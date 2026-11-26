# RHI 与材质系统讨论记录（2026-11-11）

状态：讨论记录，**不包含已批准的实现**；引擎代码未改动。参与：用户、补充模型（DeepSeek）。基线：引擎 `14a6b0d`。

关联：[渲染架构学习笔记](../learning/RenderingArchitecture.md)、[材质模板系统方案](../design/MaterialTemplateSystem.md)。

## 背景

用户希望系统理解 DevLog02 之后的渲染扩展，先怀疑“并发的、和渲染相关的方案”与“多光源”有关，随后逐层追问到 RHI、PSO、G-Buffer、CBuffer，最后提出：有了 RHI 后能否做自己的 Shader 语言与转译、像 UE 一样提供材质模板 API，以及编辑器参数如何传递、是否都属于 BasePass。

## 问题与结论

### Q1：DevLog02 之后新增了哪些模块？RHI、后处理、多光源算不算？

- 83 个提交、180 个新增文件。新增模块包括：声明式渲染管线（`RenderPipeline`/`RenderFeatures`/`ShadowPass`/`ScenePipeline`）、D3D12 DXR 硬件光追与 GI、Camera 模块、五类灯光与打包、网格 Slot/UV、资产容器与导入、编辑器 Console/Diagnostics、景深与选中描边等。
- **RHI 不是 DevLog02 之后新增的**：`RenderBackend.h` 在初始引擎就有，DevLog02 之后对 `RenderBackend.h/.cpp` 的 diff 为空。
- 后处理目前只有两条：屏幕景深（`DepthOfField.hlsli/.inl`）与编辑器选中描边（`SelectionOutline`）。没有 Bloom、Tone mapping 栈、SSAO。
- 多光源是**固定 32 盏灯的常量缓冲打包**，不是 cluster/tile，也不是多线程。

### Q2：渲染管线有哪些模块和流程？

- 声明层：`RenderPipeline.h`（Pass 种类、资源位、读/写声明）、`ScenePipeline.cpp`（按条件拼帧图 + `validatePipeline`）。
- 执行层：`SceneRenderer::render` 按声明顺序执行：ShadowMap → HardwareTransport（DXR）→ GBuffer/Deferred 或 ForwardBackground/ForwardGeometry → HardwareResolve → DepthOfField → SelectionMask/Composite → FrameCapture。
- 支撑：Lighting、GlobalIllumination、D3D12 桥、RenderDiagnostics、GeometryStatistics、MaterialRenderStates。
- 详细流程见 [学习笔记第 2 节](../learning/RenderingArchitecture.md#2-一帧的-pass-流)。

### Q3：RHI 是什么？对管线有什么影响？我们怎么声明和打包？

- RHI 是图形 API 的抽象层，负责设备/交换链、资源、管线状态、命令、同步、能力协商；它不决定“画什么”。
- 我们当前的 RHI 是**骨架**：`IRenderBackend` 只有 initialize/shutdown/beginFrame/endFrame/present；五个后端全是占位；`Engine` 会创建它，但 App 没使用 `Engine`，`SceneRenderer` 直接调 D3D11；`D3D12` 目录只是 DXR 桥。
- 因此 RHI **目前对管线没有实际影响**。管线真正的抽象是 Pass 图：`PipelineResource` 逻辑位 + `reads/writes` + 校验。
- 声明与打包的实际机制：Pass 声明、特性三层（请求/能力/实际）、着色器反射契约（名字/类型/槽位/字节数/变量偏移）、常量缓冲结构体（`alignas(16)` + `static_assert`）。
- 详见 [学习笔记第 4–7 节](../learning/RenderingArchitecture.md)。

### Q4：RHI 是只给 D3D11 吗？PSO 是什么？G-Buffer/Deferred 的读写声明怎么理解？CBuffer 是什么？

- **不是**。RHI 设计上支持多后端，但当前既没实现 D3D11 后端，也没被渲染器使用；D3D11 代码是直连的。D3D12 只服务 DXR。
- **PSO**：把 VS/PS、输入布局、光栅/深度/混合状态、RT 格式等一次性打包成管线状态对象；D3D11 是零散状态，D3D12/Vulkan 需要 PSO。我们代码里的 `materialRasterizers[rasterIndex]` 就是 PSO 思想的雏形。
- **G-Buffer/Deferred**：GBuffer Pass 只写表面属性（Albedo/Roughness、Normal/Metallic、WorldPos/Coverage）+ Depth，不做光照；Deferred Pass 全屏读这些纹理 + ShadowMap + IndirectLighting，算一次光照写 SceneColor。`reads/writes` 是 Pass 图的数据流声明，校验保证生产者在前。
- **CBuffer**：CPU → GPU 的小块常量参数，HLSL 用 `cbuffer X : register(bN)`；我们按更新频率分为 b0 Scene、b1 Object、b3 Shadow、b7 Lighting 等，遵守 16 字节对齐并用反射校验布局。

### Q5：有了 RHI，是否可以有自己的 Shader 语言并转译？像 UE 一样提供材质模板 API？参数是否都是前端 BasePass 的事？

- **RHI ≠ Shader 语言**。层次是：材质/DSL 编写 → 代码生成/转译 → 平台编译（DXIL/SPIR-V/MSL）→ RHI（shader 模块/PSO/绑定）→ GPU。RHI 只消费字节码。
- UE 不是“自有语言再转译”：节点图生成 HLSL 表达式 + `MaterialTemplate.ush`，平台编译器编译；运行时参数进 uniform buffer，静态开关生成 permutation；材质实例覆盖运行时参数不重编译。
- 我们目前是手写 HLSL + 固定 `Surface`/`MaterialAtUv` + 热编译候选替换，没有参数 Schema、模板 API、变体系统。
- 推荐的落地顺序：① 参数 Schema + 自动生成 `MaterialConstants`；② 稳定的 `EvaluateMaterial` 模板 API；③ 节点图/DSL → 生成 HLSL；④ 变体键与缓存；⑤ 跨后端（DXC → DXIL/SPIR-V）。
- **职责不是都归 BasePass**：编辑器管值，材质系统管 Schema/数据/实例覆盖，代码生成管变体，BasePass 管“选变体 + 绑定 + 执行”，RHI 管后端。
- 方案细节与风险见 [材质模板系统方案](../design/MaterialTemplateSystem.md)。

## 澄清的误解

| 说法 | 实际情况 |
|---|---|
| “我们加了 RHI” | 只有接口骨架；`SceneRenderer` 直连 D3D11，D3D12 只做 DXR 桥 |
| “用了并发” | 没有 CPU 渲染线程；只有 DXR 与光栅的 fence 协作、诊断异步 GPU 查询、渐进 GI 的跨帧累积；文档里的“并发任务”指并行开发任务 |
| “多光源并发的方案” | 32 灯固定预算的常量缓冲打包 + Sky 聚合 + 矩形 MIS，不是 cluster/tile 并行光照 |
| “后处理” | 只有景深和描边；无 Bloom/Tone mapping/SSAO |
| “有了 RHI 就能写自己的 Shader 语言” | RHI 提供后端抽象，不提供语言/编译器/材质系统；这些是独立投资 |

## 达成的方向（提案，未实现）

1. RHI 先落地资源/命令/PSO/能力查询，从 Null + D3D11 两个后端开始，保持行为不变。
2. 材质系统分四阶段：参数 Schema → 模板 API → 代码生成/节点 → 变体缓存。
3. 所有 Pass（Base/Shadow/DXR/GI）共享同一份 `EvaluateMaterial`，保证语义一致。
4. 运行时参数走 CBuffer，静态开关走 `#define` 变体；变体键与缓存必须可控。
5. 先不造完整语言；用 HLSL + 代码生成，跨后端交给 DXC/SPIRV-Cross。

## 未决问题

- 材质模板用 HLSL include 约定，还是引入轻量 DSL/节点图？
- 变体维度与上限（TwoSided/Grid/Shadow/DXR/GI/平台）如何定义与缓存？
- 纹理参数与绑定布局（D3D11 直绑 vs D3D12 root signature/Vulkan descriptor set）。
- RHI 迁移顺序：先抽象资源还是先抽象命令？DXR 作为可选扩展还是独立后端？
- 编辑器参数 UI 与 `.rasset` Schema 的版本兼容策略。

## 证据与源码锚点

- RHI：`include/RestArtEngine/Renderer/RenderBackend.h`、`src/Renderer/RenderBackend.cpp`、`src/Core/Engine.cpp`
- 管线声明：`include/RestArtEngine/Renderer/RenderPipeline.h`、`src/Renderer/Pipelines/ScenePipeline.cpp`
- 执行与常量：`src/Renderer/SceneRenderer.cpp`（`validateShader`、常量结构体、`render`）
- 照明打包：`include/RestArtEngine/Renderer/Lighting.h`、`Shaders/Private/Lighting.hlsli`
- DXR 桥：`src/Renderer/D3D12/HardwareRayTracing.h/.cpp`
- 材质现状：`Shaders/Materials/Standard.hlsli`、`Shaders/Private/Scene.hlsl`（`MaterialAtUv`/`PSGBuffer`/`PSDeferred`）

以上结论基于 `14a6b0d` 源码与本次讨论；未运行新的 GPU 验证，学习文档与方案文档分别标注了“已实现/未实现”。
