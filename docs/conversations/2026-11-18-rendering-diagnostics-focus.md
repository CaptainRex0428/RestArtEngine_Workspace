# 收敛渲染与渲染调试开发主线（2026-11-18）

状态：优先级讨论，不含具体实现授权；引擎源码未改。基线14a6b0d。

后续变更：用户进一步指定优先独立 D3D12 主后端与 D3D11 回退，联动实际 RHI／显式资源声明；[新讨论](2026-11-18-native-d3d12-backend.md)与[当前方案](../design/NativeD3D12Backend.md)取代本文的近期排序。下文保留讨论历史。

用户反馈板块过多，希望先优化渲染和对渲染的RenderDoc。建议把近期目标收敛为“阶段结果可观察→HDR成图边界正确→测量后性能优化”。第一个实现切片为Frame Inspector选定Pass前后快照/对照；第二个为HDR与显示转换分离；第三个按实测选择热点。完整RHI/RenderGraph/多后端/材质节点/NPR/全API回放不作为这轮前置。

外部RenderDoc用于专业API状态检查，内置Frame Inspector侧重引擎语义和快速对比，具体混合DXR捕获能力需验证。用户尚未决定首个任务的执行，只确认了领域偏好。

完整范围/验收/取舍：[近期方案](../design/RenderingDiagnosticsFocus.md)。延续[Inspector长期方案](../design/FrameInspectorEvolution.md)，本轮不修改既有实现、不构建、不跑GPU测试。资料按协作规则提交推送main，实际同步以Git回执为准。
