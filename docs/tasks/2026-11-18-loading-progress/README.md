# 引擎与工程加载反馈

状态：实现与隔离验收通过，引擎已提交 7e5ca88，未推送。加载显示实际 Shader、管线、资产、场景和工作区准备状态，首帧完成后才 Ready；独立提交的基线启动、缺 Shader 失败及 4 项相关 CTest 通过。

最新：[v2](v2.md) 为独立提交验收；[v1](v1.md) 保留首次混合工作区的三模式实现与验收。公开行为见 EditorGuide / Architecture；证据放 artifacts/loading-progress/，用户工程不得作为自测写入目标。
