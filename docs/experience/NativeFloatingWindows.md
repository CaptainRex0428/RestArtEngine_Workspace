# 原生浮窗、场景目标与输入矩形

## 场景与原因

面板已经支持Dock浮动，启用ImGui多viewport却仍被主页面截断时，先检查应用是否逐帧SetNextWindowViewport(main)。只解除pin不足以修复SceneViewport：把desktop-mainOrigin裁到主尺寸纹理会导致外窗无图、截边或点偏。

## 处理原则

- 仅DockSpace宿主与主toolbar固定main；普通面板由后端自动外移／回嵌，专用MaterialWorkspace NoAutoMerge/Parent0例外按其产品契约保留，不能全局套用。
- Scene color/depth/GBuffer尺寸与主swapchain分离；candidate完整分配后事务发布，失败保留旧组。UI drawlist借用的旧SRV至少保留到全部平台提交完成，普通Present或minimized无Present分支显式释放退休组。
- 所有拾取／拖放／Gizmo／投影／平移共用真实desktop image rect与texture-local render rect的映射。主内旧偏移可兼容保留，外窗不得从mainOrigin推image坐标。
- 主窗口最小化时按showUI维护提交；普通Win32 owned popup随owner隐藏，独立Parent0工具可以可见。保留Dock树和平台HWND，已有external HWND不可见时跳Scene GPU，不以IsIconic单独判断。F1/F11隐藏工作区时不能在minimized分支重新提交全部普通panel。

## 防回归与证据

真实拖dock tab外移／回嵌、跨窗口资源投递、场景desktop鼠标命中／Gizmo、native尺寸与texture尺寸一致、native布局reload、owned最小化/恢复、可关闭工具关闭。外部截图使用该platform viewport实际RTV回读或可靠窗口级capture，不能用主backbuffer图片充当外窗。共享源码先冻结再构建，防止并行修改混编。

原生浮窗可能因屏幕工作区约束而互相重叠。合成桌面坐标不能按 viewport 创建次序推断遮挡；在相关测试作用域使用锁定版 ImGui 的 FindHoveredViewportFromPlatformWindowStack，并在拖资源／标签前激活源 HWND、提交稳定帧，检查真实可见区域和 widget ActiveId。回嵌必须继续真实指针拖动并验证 DockId 与主 viewport，不用布局构建器替代。隔离测试工程还需显式绑定冻结引擎根，避免安装恢复流程读取并行工作区 Shader；构建源码、测试实际引擎路径与提交 tree 三者均应核对。

## 边界与来源

本次Windows/DX11+Dear ImGui锁定版本验证，不能自动推断其他平台或完整跨屏字体DPI。来源：[浮窗截断任务v1](../tasks/2026-10-29-floating-windows/v1.md)；原始证据 artifacts/floating-windows/v1/，完整editor-self-test通过、D3D11错误0。

提交隔离与重叠输入补充来源：[v2](../tasks/2026-10-29-floating-windows/v2.md)，artifacts/floating-windows/commit-validation-05/，完整自测退出 0；提交 c86a6de。
