# 原生 Frame Inspector、程序诊断与 Profile

状态：功能实现、专项验收和文档收尾完成；完整Editor末段原生跨窗拖放待解锁桌面后补验。用户明确授权增强自研工具，尽可能提供详细渲染检查及程序debug/profile。

基线：引擎14a6b0d加未提交M1/M2/M3；M3实际独立12场景/UI已通过。引擎代码不自动提交；Sandbox七项本地资产继续保护。

最新：[v5](v5.md)。历史：[v1](v1.md)、[v2](v2.md)、[v3](v3.md)、[v4](v4.md)。范围：两API的详细Draw/PSO/绑定/逐Draw常量、指定Pass边界冻结、原生12实际GPU计时、离线.raframe资源包、CPU线程时间线与运行日志/内存/图形验证。完整API回放、Pixel History、Shader单步和CPU源码断点不属于本轮已实现能力，分别记录后续。

最终Debug构建和Premake通过，CTest29/29；两API实际Inspector、双主题宽窄UI通过，双向跨API离线打开已有通过证据。混合HRT251次真实dispatch/图形错误0，严格11的13张非UI图与原基准逐字节一致；七项用户资产哈希不变。完整Editor已过全部Diagnostics与保存/Content等，但系统前台LockApp导致末段原生跨窗焦点失败，解锁后补验，不记整套PASS。证据范围和版本身份见v5。经验：[NativeDiagnostics](../../experience/NativeDiagnostics.md)。

主agent拥有公共契约、SceneRenderer/捕获、构建与集成验收；渲染agent负责12计时/层copy及严格metadata；GUI agent负责DiagnosticsPanel；通用agent负责二进制容器、Core日志与隔离Inspector自测。GPU与构建由主agent串行执行。
