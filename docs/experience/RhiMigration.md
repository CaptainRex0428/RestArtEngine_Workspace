# 实际 RHI 迁移、附件声明与 native 边界

最新原生 D3D12 经验与证据见本页末尾及 [M3任务](../tasks/2026-11-18-native-d3d12/README.md)；此前 M2 范围保留为迁移过程记录。

## 纵向切片先证明真实执行

触发：已有接口叫Backend/RHI，但场景仍绕过它直接上传、绑定、Draw。
原因：生命周期占位不具有资源和命令契约，增加枚举不能接入主渲染。
原则：沿网格上传→常量→Shader/图形管线→实际附件→Draw→视口建立闭环，公共头不含native类型，后端私有实现实际执行并统计。先证明D3D11画面等价，再用同一契约实现显式API；native桥逐项标明，不能称完整统一。
防回归：WARP实际绘制/回读；同场景、同相机、同设置下保存迁移前可执行并比较非UI图像字节；用真实执行计数证明主场景消费接口，不能只创建资源却native Draw。该对照不是性能结论。
边界：Windows D3D11通过不外推其他后端；旧IRenderBackend与当前Rhi.h是不同接口。资源统计为累计逻辑事件，不等于显存驻留或全帧全部Draw。

## 常量更新、附件和热编译的生命周期

触发：将D3D11调用封装成RHI，为后续D3D12实现共享契约。
原因：D3D11驱动隐藏了部分版本管理、绑定冲突和资源占用；原样传一个GPU地址给12会覆盖之前Draw的常量。
原则：每次write必须保持早先Draw的数据直到消费结束；显式后端需要upload版本/环和fence。附件声明须带真实资源与层、Load/Clear/Store，校验owner/格式/读写别名，结束Pass释放wrapper保留引用；DontCare不承诺有效内容。Forward背景与几何之间的Load不可偷偷变Clear。
防回归：同一常量缓冲连续red/green绘制，staging回读两者及clear背景；验证Load保留、Clear替换、非法设备/usage/格式、失败保留live Shader；候选阶段创建全部受支持图形管线后才发布，避免只编译成功却首次Draw才发现GPU管线失败。
边界：本切片仍有native SRV/采样器/后处理等，不能假定接口独占context，不做有隐式前提的状态缓存。缺UV的stride=0是合法广播，不能误拒绝。

## 同尺寸重试与失败出口

触发：ResizeBuffers前释放RTV，失败后再次请求旧尺寸；或native Outline绘制中途失败。
原因：尺寸相等不代表目标存在；幂等end在没有活动RHI Pass时不会清native暂存状态。
原则：尺寸相等仍检查目标是否存在；失败保留原始诊断并尝试重新获取旧surface。native桥失败出口清理临时OM/reads/blend，成功路径保持UI所需目标绑定。UI本帧借用的旧离屏SRV按原有安全边界退役，不能直接销毁。
防回归：实际resize、四视图与工具预览、GC及捕获；故障注入/设备丢失若未做则明确列为未验证。不能将重试补齐称作完整device loss恢复。

来源：[M2 v1](../tasks/2026-11-18-rhi-slice/v1.md)、[审查与恢复v2](../tasks/2026-11-18-rhi-slice/v2.md)。原始构建／GPU证据位于本机artifacts，跨机需复跑。

## 完整Editor验收的资产前提

独立渲染专项自行构建场景，不代表同一示例满足EditorSmoke的交互前置条件。后者拖材质明确需要已加载、Project-origin、.rasset材质。RayTracing_Simple只有legacy.ramat时会在此处停止；应使用Git已提交Sandbox的隔离归档，保持用户工作树资产不变。保留首次失败，再记录修正夹具后的结果；不将缺前置资产当作RHI绘制回归，也不把部分UI检查通过说成整套通过。来源：[v3](../tasks/2026-11-18-rhi-slice/v3.md)。

## 原生 UI 的队列与退役边界

触发：引入 ImGui DX12、主窗口最小化但独立工具窗口仍绘制、UI 构建后替换 preview/scene 图像。

原因：vendored DX12 为每个副窗口创建独立 queue，主队列中“先录制场景”不能保证副队列读到最新纹理；CPU 绘制列表先借用描述符，中途 readback/flush 完成也不代表这些尚未提交的 UI 已消费。最小化不 present，若仅在 present 退役，借用集合会持续增长。

原则：所有 native12 UI 帧先把采样纹理转换为可读并完成主场景提交，随后提交副窗口；核实副窗口 SwapBuffers 的真实 fence，再在所有 UI 完成处退役描述符和借用图像。renderMain=false 仍必须执行转换和完成边界。回读、主 submit、主 present 都不能独自代表所有 UI 完成。DX12 Shutdown 自己先清主 viewport data，不照搬 DX11 的提前 DestroyPlatformWindows 顺序。

防回归：同帧先借用旧图像 ID 再替换目标与 slot；真实创建独立 HWND，主窗口最小化后连续改变材质，GPU 回读变化且 debug errors0；结束时不依赖 present 清理。独立 RHI 测试以 weak_ptr 确认中途 submit 保留、finishUiFrame 释放，描述符中途 flush 不复用。

边界：当前同步等待以正确性为先，不代表异步性能方案；副窗口原生寿命与 GPU 验证不等于已检查其 GUI 像素或人工视觉。来源：[M3 v1](../tasks/2026-11-18-native-d3d12/v1.md)、[v2](../tasks/2026-11-18-native-d3d12/v2.md)。

## 原生 API 切换不能继承旧能力宣告

触发：同一可执行中 DX11 已有 Outline/DOF/Inspector/DXR，原生 DX12 尚未迁移这些实现。

原因：模块“已编译”不是当前后端“可用”，native Shader 指针也不是公共 Shader 身份；旧查询和工具测试可能直接把纹理 ID 当 D3D11 SRV 使用。

原则：共享绘制用 RHI 模块标识，所有原生互操作先识别后端；能力矩阵区分请求与当前后端实现，保留请求并写明确原因。旧原生读回测试须显式限制后端，不能将 D3D12 descriptor 强转为 D3D11 COM 指针。fallback 只包设备与目标创建，不包通用资产/Shader错误。

防回归：native12 禁止回退真实启动且 D3D11 device/context 均空，旧11/Auto图像对照；当前后端不支持的请求不能被标为 Active，切回11后原请求恢复执行。来源同 M3 任务与 BackendSelection/RenderPipeline CPU 测试。
