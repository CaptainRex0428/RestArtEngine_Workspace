# 独立 D3D12 与 D3D11 回退的目标确认（2026-11-18）

状态：架构讨论／方案提案；用户确认目标，尚未进入具体代码实现。本轮引擎代码未改。基线 `14a6b0d`。

参与：用户、Codex 主协调、渲染专项只读审查。

关联：[实施方案与验收](../design/NativeD3D12Backend.md)、[此前近期建议](../design/RenderingDiagnosticsFocus.md)、[RHI/Pass 学习](../learning/PassGraphRhiRelationship.md)。

## 背景与需求

用户在渲染／RenderDoc 方向中进一步指定先解决 D3D11/D3D12 后端方式、显式声明和 RHI 骨架问题。询问“D3D12”是主后端还是现有 DXR 增强后，用户明确要求：

1. 支持独立的 D3D12 主渲染后端。
2. 可选择回退到 D3D11 后端渲染。

此要求取代此前 Inspector 先行的近期建议；先前建议记录保留为讨论历史。

## 问题与结论

### 主后端与光追的关系

后端选择与 DXR 分开。D3D12 能光栅但无 DXR 仍应可用；明确选择严格 D3D11 时不能偷偷创建 D3D12。现有混合模式是迁移中的兼容路径，不能重命名为原生 D3D12。

### RHI 与 Pass 从哪里开始

建议顺序：真实后端选择／生命周期 → D3D11 实际 RHI 与明确资源使用 → 原生 D3D12 场景及 UI → 完整功能覆盖与原生 DXR。RHI 和资源声明按真实执行切片联动，不先铺满空接口，也不先追求完整 Render Graph。

### 如何回退

建议 Auto／11／12 与独立回退开关，保留请求／实际值和原因；禁止回退时清楚失败。首版启动时选择，运行中热切和设备丢失恢复另行设计。实验 D3D12 不因 device 创建成功便进入 Auto。以上为建议策略，用户尚未逐项确认具体字段或默认值。

## 源码审查证据

- `app/MinimalApp.cpp` 创建 SceneRenderer 并把 D3D11 device/context 交给 ImGui，未通过 Core 占位后端执行。
- `src/Renderer/RenderBackend.cpp` 只有占位生命周期；Auto 的枚举选择不构成实现。
- `src/Renderer/SceneRenderer.cpp` 的 initializePipeline 无条件创建 DXR bridge；现有关闭光追不等于不初始化 12。
- `src/Renderer/D3D12/HardwareRayTracing.cpp` 从已有 11 device 获取适配器并创建 12 device，经共享图像和 fence 交互。
- `RenderPipeline.h`／`Pipelines/ScenePipeline.cpp` 当前只有语义 bitmask 与顺序校验，还不能生成完整资源状态转换。
- 专项独立只读审查与主协调结论一致，无代码修改或 GPU 执行。

## 取舍与后续

保留现有 DX11 画面作为迁移对照，旧项目的 DXR/GI 请求不丢失；缺后端字段的兼容混合行为要明示，不能在严格 D3D11 名下继续隐式混用。后端设置改变首版需要重启，普通数值依旧实时生效。

下一项实施建议为真实启动选择、设备生命周期和失败状态，然后进入 D3D11 RHI 切片。详细验收和兼容条件以方案为准，本文不把规划写成已完成。

经验处理：复用 RHI/Pass 学习中的“接口存在不代表调用链落地、声明不代表完整图执行”判断；本轮不新增重复经验文件。

## 同步与验证

仅更新协作库设计、讨论与进度索引；检查链接和 Git diff，不构建、不做 GPU 测试。引擎与用户 Sandbox 资产保持原状。按 AgentEntry 规则提交并推送协作库 origin/main，具体提交／同步状态以 Git 回执为准。
