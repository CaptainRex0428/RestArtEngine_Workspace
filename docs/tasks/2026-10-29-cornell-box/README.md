# Cornell Box Path Tracing 示例

目标：根据用户参考图搭建红绿房间、顶灯和三颗金属球，可从 Project Manager 直接打开并使用渐进式路径追踪。

状态：独立提交完成，当前 [v2](v2.md)；引擎提交 `638ae2e` 位于 `codex/cornell-box`，尚未合入共享 master，未推送。历史实现见 [v1](v1.md)。主 agent 负责工程资产、生成器、构建／GPU 调度、集成与文档；场景 worker 负责可选视角／照明持久化和编辑器入口；渲染 worker 负责矩形灯与实际 GPU 专项，另有只读渲染审查。

下述 v1 验证及未提交描述为历史状态，当前独立提交验证见 v2。

原始证据：artifacts/cornell-box/v1/。既有 Sandbox／RayTracing_Simple 和其他任务工作区改动保持；未提交／推送。

16/16 CPU、完整 GI 专项（1261 dispatch、errors0）、真实样例1024/1024样本通过；最终画面和编辑器启动已检查。独立产物 `build/cornell-box/Debug/RestArtEngine.exe`；常用 bin 的用户进程在运行，未关闭／覆盖。经验见 [PathTracingExamples](../../experience/PathTracingExamples.md)。
