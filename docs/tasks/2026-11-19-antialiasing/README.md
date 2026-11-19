# 光栅抗锯齿

目标：解决前向／延迟场景严重毛边，提供可切换的实际抗锯齿方案，保持热编译和实时参数契约。

当前状态：已完成。Debug 构建、配置／管线、D3D11／原生 D3D12 GPU 质量、真实 UI、CTest 30/30 与启动 resize 修复均通过；提交 `b142549` 已推送。最新记录：[v4](v4.md)。

基线：引擎 `a28f38c`；用户 Sandbox 材质／场景／工程改动与并行 Project Settings 依赖规则任务保留。测试、构建使用独立输出，不关闭用户正在运行的编辑器。

分工：渲染专项负责共享 RHI Pass／Shader／历史；GUI 专项负责工程配置与实时控件；只读调查 agent 续接 GPU 质量自测；主 agent 负责契约、集成、构建与证据、技术说明和记录。

验收：两种光栅路径、实际 D3D11／原生 D3D12；质量对照超采样参考；相机／场景变化、预览隔离、Shader 成功与失败恢复；GI 回退透明且历史不被逐帧重置；图形验证错误为零。

待办：无阻塞。MSAA、HDR 时间重建、运动矢量和跨平台验证列为后续。

暂停交接（历史，已由 [v4](v4.md) 续接完成）：配置／JSON／实时 UI 与独立工程配置测试已写；主入口 `--aa-self-test`／CMake／12 Shader、227 PSO 加载校验已接线，但 GPU smoke 源码和渲染历史执行仍在实现中，当前工作区不应视作可编译。渲染 agent `aa_renderer`，GPU 自测 `aa_pipeline_probe`，配置／UI 自测 `aa_settings` 均已中断；恢复后检查其落盘文件再续接。新 UI 自测若接入，签名应接收 ProjectPaths 以便隔离保存往返；其 CMake／CLI 尚未接入。工具材质／相机／缩略图预览目前构造默认 Off，需要决定并实现空间 AA 默认。主视图与四视图继承 live AA 已核对。用户编辑器保持运行，禁止覆盖其被锁定的 common Debug EXE；使用独立 `build/antialiasing`。基线工程夹具及用户资产 SHA 在 `artifacts/antialiasing/v1/`。本轮未执行构建、GPU、提交或推送。
