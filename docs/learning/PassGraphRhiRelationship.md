# Pass、Render Graph、RHI 与混合 DX11/DXR（2026-11-18）

基线：引擎14a6b0d。原理答疑，未修改运行时。对应[讨论](../conversations/2026-11-18-pass-graph-rhi-inspector.md)。

## 1. Pass 与声明

Pass是渲染的一段工作，例如GBuffer、光照、景深。一个Pass可以包含许多Draw/Dispatch；它不是一张图，也不等于一次Draw。此处是引擎逻辑阶段，不应与某API的原生render pass对象等同。

“隐式Pass声明”并非本项目正式机制，准确说法是阶段/资源依赖隐藏在普通顺序代码里。即使函数名叫drawGBuffer，只要框架没有可读取的资源声明，依赖仍需人读实现推断。

旧式示意：drawGBuffer(); drawLighting(); drawDof();。有明确函数调用，但谁读写何资源只能看函数体。声明式示意：GBuffer写Albedo/Normal/Position/Depth，Lighting读GBuffer写SceneColor，DOF读SceneColor/Depth写新颜色。框架可以校验顺序与缺失输入；Shader和绑定仍要程序实现并验证，声明不会自动保证函数体正确。

本项目RenderPassDeclaration记录kind/name/reads/writes，buildScenePipeline组合有序列表，validatePipeline检查此前是否存在生产者；资源位是粗粒度语义，尚无完整子资源/版本/读写冲突模型。显式声明不等于D3D12“显式API”，D3D11也能使用声明。

## 2. Render Graph

Render Graph用图表达任务与依赖：常见节点为Pass，边表达通过资源形成的先后关系。也有Pass/资源都作为节点的表示；图不意味着存在GPU并行，也不意味着自动更快。

例：Shadow与GBuffer分别产生ShadowMap和表面数据，Lighting读取两者；DOF再读光照颜色和深度。源代码可以先登记所有Pass，编译图时检查依赖并生成合法执行计划。独立分支是否可并行还取决于队列、同步与资源冲突。

成熟实现还可跟踪资源生命周期、剔除不影响最终输出的工作、插入barrier/fence、复用不同时存活的临时内存。不能因缺少某一优化就断言不是Render Graph；关键是依赖图是否真正参与编译/执行管理。

本项目当前是有资源注解、可校验的顺序Pass列表，可视为向依赖图演进的起点；没有完整图编译器/资源版本/自动状态与生命周期管理。这比简单说“完全没有图”准确。

## 3. RHI与数据打包不是一回事

RHI（Render Hardware Interface）是引擎定义的图形后端抽象，并非全行业通用的唯一标准接口。上层借它创建Texture/Buffer、设置Pipeline、绑定参数、Draw/Dispatch、提交命令与同步；D3D11/D3D12/Vulkan等后端把这些操作翻译为具体API。真实职责与接口粒度取决于引擎。

CPU结构体对应HLSL cbuffer的字段顺序、对齐、偏移属于Shader参数布局契约；它只是RHI可能承载的资源/绑定工作的一部分，不是RHI的定义。没有RHI也可以直接通过D3D11上传常量和绘制。

目标关系：Renderer/Pass图决定工作与依赖 → RHI描述资源/命令/同步 → 具体API/驱动 → GPU。Shader编译工具链在旁边产生GPU程序，RHI消费Shader/管线对象，不自动提供自研Shader语言。

当前IRenderBackend只有initialize/beginFrame/endFrame/present等生命周期方法，没承接实际SceneRenderer的资源/命令；其实现是占位。SceneRenderer直接操作D3D11。

## 4. DX11、DX12、DXR的当前关系

DXR是D3D12的硬件光追能力，不是与DX12并列的完整图形API；DXR1.1提供RayQuery，当前引擎在D3D12计算Shader中使用它。没有把D3D11 Draw命令自动转换成DXR，亦不是D3D11 API直接调用DXR。

现在同一GPU上有D3D11设备与D3D12设备：D3D11负责主光栅/编辑器/UI/最终呈现，D3D12模块构建光追加速结构、提交光追计算，并把选定输出图像以共享资源交给D3D11。fence的Signal/Wait排序写者和读者，防止边写边读/过早复用；不是CPU每帧截图上传，也不意味着所有资源自动共享。

Realtime共享间接HDR图，D3D11将它与光栅直接光合成；Progressive共享完整显示颜色，D3D11接入场景视口及编辑叠加。D3D11使用完共享输出后也要向D3D12同步再写，因此存在双向同步。

“有D3D12模块”不等于“完整D3D12场景后端”：主绘制/Shadow/GBuffer/后处理/资源管理/呈现等仍没有整体由DX12后端承担；UI迁移还要配套处理。RHI不足不会阻止直接调用原生API，代价是后续移植/统一捕获需处理两路实现。

选择这条混合路径是对现有DX11能力的复用，先拿到硬件求交；代价包括共享格式限制、设备对象边界、生命周期和同步复杂度。不能把它描述为“不通”，现有GPU历史验收已证明这条组合实际工作；也不能说已经完整迁移DX12。

## 5. D3D11 是否支持光线追踪（2026-11-18补充）

光追是算法，DXR是API能力，两者不等价。D3D11普通Shader可以自己做射线求交、遍历与采样；本引擎已有的解析图元／三角形求交运行在像素Shader，不是DXR。Compute Shader也能做通用计算，但不能因此声称本项目已把此路径实现为Compute，更不能声称自动使用硬件光追加速单元。

D3D11不提供DXR接口。本引擎混合模式的硬件光追由D3D12/DXR执行，D3D11合成共享结果。用户明确三个正式选项：严格11、11+12/DXR混合、原生12；后者仍未实现，启动选择器不构成完整后端。当前选择／回退实现见[任务](../tasks/2026-11-18-backend-startup/README.md)。

依据：[微软D3D12 Raytracing](https://learn.microsoft.com/en-us/windows/win32/direct3d12/direct3d-12-raytracing)、[D3D11 Compute](https://learn.microsoft.com/en-us/windows/win32/direct3d11/direct3d-11-advanced-stages-compute-shader)。

## 来源

- 引擎RenderPipeline.h、ScenePipeline.cpp、SceneRenderer.cpp、RenderBackend.h/.cpp。
- HardwareRayTracing.cpp：同适配器D3D12CreateDevice约791行，共享纹理约654/682行，共享fence约842行，双向Signal/Wait约979/1125行。
- [Epic RDG](https://dev.epicgames.com/documentation/en-us/unreal-engine/render-dependency-graph-in-unreal-engine)：依赖图及自动管理示例，不等于本引擎已实现这些能力。
- [Microsoft DXR规范](https://microsoft.github.io/DirectX-Specs/d3d/Raytracing.html)：DXR、Inline Raytracing与RayQuery。
