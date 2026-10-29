# 五类场景灯光模块

目标：在现有引擎上加入 Directional、Sky、Rect、Spot、Point，支持场景编辑、实时照明、撤销与持久化。

状态：完成；Cornell矩形MIS已合并，五类灯光数据／编辑／渲染／保存接通。Debug无警告构建、16/16 CPU、灯光GPU84dispatch、GI1291dispatch与完整编辑器自测通过，graphics errors 0；两主题截图已检查。

最新版本：[v3](v3.md)。未提交、未推送。

交付程序：`build/cmake-lighting/Debug/RestArtEngine.exe`；现有用户进程和bin未覆盖，自测隔离运行。收尾Sandbox场景及缩略图在自测退出后有外部保存，保留更新；其余22个项目文件哈希一致。原始证据 `artifacts/lighting/v1/`、`v2/`、`v3/`；v2 Outliner真实裁剪失败保留，v3修复后通过。能力边界见公开 [Lighting](../../../../docs/Lighting.md)，经验见 [Lighting](../../experience/Lighting.md)。
