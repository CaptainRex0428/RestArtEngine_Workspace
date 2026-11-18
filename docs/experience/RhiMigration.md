# 实际 RHI 迁移、附件声明与 native 边界

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
