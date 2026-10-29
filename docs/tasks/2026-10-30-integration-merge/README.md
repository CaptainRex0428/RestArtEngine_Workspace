# 集成工作区改动与 Cornell 分支合入

状态：完成；引擎提交 `8f027db`、`c5db70c` 与合并 `a46432b` 已推送 `origin/master`。最新尝试：[v1](v1.md)。

目标：把 2026-10-30 工作区的 49 个已跟踪改动与 39 个未跟踪路径分类提交，并在保留现有功能的前提下合入 `codex/cornell-box`（`638ae2e`）。

范围：引擎源码、Shader、测试、构建列表与公开文档；Sandbox 用户资产、R8 模型及 `PathTracing_CornellBox` 样例按既定边界处理。实现过程未修改现有功能语义。