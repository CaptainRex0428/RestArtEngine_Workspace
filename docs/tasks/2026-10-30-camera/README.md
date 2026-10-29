# Camera 系统

用户目标：统一视口、场景与工具预览相机，独立实现、检查和交付可运行结果。

当前状态：首版完成，完整编辑器最终验收通过。最新记录：[v6](v6.md)，历史 [v1](v1.md) / [v2](v2.md) / [v3](v3.md) / [v4](v4.md) / [v5](v5.md) 保留各轮失败与定位过程，不覆盖为成功记录。

首轮交付统一相机求值、透视/正交、Camera Actor、镜头编辑、查看/操纵、撤销与持久化，以及独立相机预览。四分屏、物理镜头、景深及动画属于原方案后续扩展。

文件归属：渲染专项负责 Camera 核心、Renderer、Shader；GUI 专项负责 SceneEditor/ViewportInteraction；场景专项负责 World 和持久化；主协调者负责构建入口、应用集成、GPU/编辑器验收、公开说明与本记录。保留同期灯光、资产、材质槽、Cornell 及用户工程变更。

已完成：无警告Debug构建、20/20 CPU及新增导航回归、Camera GPU专项8次真实DXR dispatch、GI全套1568次dispatch/errors0；v6完整Editor进程exit0、D3D11 validation errors0，覆盖旧编辑流程与Camera创建、真实镜头控件Undo、默认引用、固定画幅、只读查看、操纵手势Undo、恢复自由视角、正交拾取、两主题预览、保存重开及删除Undo。日志 `artifacts/camera/v6/editor.log`，截图 `artifacts/camera/v6/editor/`。

交付程序 `build/camera/Debug/RestArtEngine.exe`，独立演示入口 `artifacts/camera/Open-CameraStudio.cmd`。Camera Studio含16:9透视与俯视正交相机，UI及默认相机 `--no-ui` 均实际启动16帧/errors0；主协调已目视检查最终运行截图。`artifacts/camera/CameraPreview.png` 为v6蓝色主题真实预览。`artifacts/camera/v6/integrity.json` 确认原Projects 34文件SHA256全部不变，最终源码快照为同目录 `source-manifest.json`。公开说明 `docs/Camera.md` 已补 `.gitignore` allowlist，可进入公开引擎库；经验见 [Camera](../../experience/Camera.md)。

后续扩展：四分屏、多份常驻DXR历史、物理镜头、景深和动画；本轮只提供单主时间历史及独立Raster相机预览。未提交、未推送。
