# 浮窗跨主窗口边界完整显示

状态：完成并验证，已提交 c86a6de，未推送。用户要求悬浮窗口不被主页面截断，保留外移／回嵌逻辑。
当前版本：[v2](v2.md)（独立提交候选验收与测试重叠窗口处理）；首次实现与验收见 [v1](v1.md)。事实入口为公开GuiDevelopment/EditorGuide，原始证据 artifacts/floating-windows/。

文件归属：floating_scene_viewport独占SceneRenderer.h/.cpp与ViewportInteraction.h/.cpp；floating_platform_audit独占DockManager、Diagnostics/ProjectSettings、ImGuiLayer；material_window_tests独占EditorSmoke；root负责SceneEditor普通工具pin与main visibility分发、MinimalApp minimized loop、文档、集成验收与经验。

验收：native外移/边界完整显示、Scene独立尺寸/拾取/投递/Gizmo、回嵌与布局重载、主最小化继续提交可见平台窗口；不以主截图代替外部窗口截图。使用隔离工程/布局、保留用户进程与原始资产。
