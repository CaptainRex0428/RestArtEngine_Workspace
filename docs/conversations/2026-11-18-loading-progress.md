# 引擎与工程加载反馈（2026-11-18）

状态：用户要求实现，已改代码，隔离验收通过。
基线：引擎 14a6b0d 加当前未提交后端及 native-inspector 工作。
关联：[任务](../tasks/2026-11-18-loading-progress/README.md)、[经验](../experience/LoadingProgress.md)。

## 背景与结论

用户指出加载进度可能从 15% 大幅跳到接近完成，信息缺少参考价值，要求增加实际加载节点。源码确认原引擎阶段只有 15% / 65% / 100%，工程加载没有细分反馈，切窗口还退回 65%。

方案采用轻量可选同步观察者与子范围映射，向现有加载页接入 Shader、PSO、可选 DXR、Engine / Project 资产、场景和 Content 索引／缩略图；显示阶段、当前项／总数及文件名。去掉 Project Manager 无用的场景管线初始化；实际首帧准备好才报告完成。现有加载视觉保持，两行反馈与长文裁剪补足窄窗口。

没有采用计时器驱动的假进度或人为延迟；百分比是工作预算而非剩余时间预测。单个 Shader 编译或大资源读取内部仍是同步等待。验证与未验证边界以任务 v1 为准，引擎本轮不自动提交。

## 证据与同步

入口：app/MinimalApp.cpp，Core/LoadProgress.h，SceneRenderer.initializePipeline，SceneEditor.initialize，AssetLibrary / AssetRegistry；公共说明为 docs/EditorGuide.md 与 docs/Architecture.md。

协作记录按项目规则独立同步；提交与远端状态收尾记录于任务日志。
