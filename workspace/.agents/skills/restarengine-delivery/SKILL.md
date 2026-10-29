---
name: restarengine-delivery
description: "Plan and verify RestArtEngine implementation handoffs, integration and completion evidence. Use when accepting subagent changes or preparing an engine feature/fix for delivery; select checks by affected behavior."
---

# RestArtEngine 开发与交付

用于任务开始时制定验收、完成时核验交付。共同职责与任务契约见 [AgentDevelopment.md](../../../local/docs/AgentDevelopment.md)，模块边界及已有验证入口见 [Architecture.md](../../../docs/Architecture.md)。渲染专项同时遵守 [restarengine-rendering](../restarengine-rendering/SKILL.md)，GUI 专项按 [GuiDevelopment.md](../../../docs/GuiDevelopment.md) 选择视觉和交互验收。

## 开发标准

从一个可复现的用户行为或最小场景出发，明确模块归属、数据流、资源生命周期、失败恢复和可观察结果。公共接口与实现按现有目录分工；Scene／Assets 保持不依赖编辑器和图形 API，当前工程数据不写入引擎模板。新增源文件同步接入相关 CMake／Premake 规则。

优先沿用已有流程，再修正实际缺口。改变数据格式、CPU/GPU 契约、资源依赖或撤销事务时，明确兼容与失败路径（例：`.rasset` 保存不得删除旧 `.ramat`，旧 `.raasset` 仍需可读）。可复用的经验写进技能，行为快照写回领域文档，不把进度复制到技能里。第三方方案从对应版本的官方文档／源码取证，引用与复制遵守原许可。不要将当前平台的通过结果外推为其他平台支持。

## 按影响范围验证

| 改动 | 有效证据 |
| --- | --- |
| 文档、agent、skill | 配置解析、链接可达、约束一致；涉及分派流程时做有边界的行为演练，不要求引擎重建。 |
| 低风险 UI 显示 | 本次构建；影响布局／图像时检查实际截图。无需为静态文案删除写镜像测试。 |
| 编辑交互、场景与资产 | 相关编辑器自测或定向用例；涉及撤销、保存、加载则覆盖恢复和失败不破坏原状态。 |
| 原生窗口 | 对应窗口脚本及截图；命中测试通过不能代替实际吸附弹窗或跨屏操作。 |
| Shader、Pass、材质、后端 | 渲染技能规定的实际 GPU 画面、失败恢复及参数行为验证。 |

使用实际构建产物，给脚本显式传入 `-Executable`。优先使用已配置且对应本工作区的构建目录；新环境按 `CMakePresets.json` 配置。构建和 GPU／桌面输入测试由协调者串行调度或隔离输出，避免同时链接同一程序、修改同一测试工程或争抢桌面焦点。测试必须使用临时工程副本与独立布局设置：对真实工程执行 `Save All` 会改写其资产（本项目曾把 `.ramat` 转成 `.rasset` 并删除旧文件）；仅对已确认归属的测试夹具目录每轮重建，证据目录与用户工程分开，不关闭用户进程。同一解决方案的 MSBuild 串行执行，避免 `*.tlog` 文件锁导致构建失败。

可复用入口：`--editor-self-test`、`scripts/Validate-Render.ps1`、`scripts/Test-Window.ps1`、`scripts/Test-WindowChrome.ps1`。具体命令和参数先核对对应脚本；仅运行与改动相关的检查及架构要求的检查。通过后没有新变化或未解决风险就不重复全量测试。

## 接收子任务

按 [任务闭环](../../../local/docs/TaskWorkflow.md) 验收：原因／假设有依据、修改验证有结果、当前 vN 日志与任务索引可续接、经验已新增／修订／明确复用。查看 [经验索引](../../../local/docs/DevelopmentExperience.md)，不要只更新进度而遗漏经验处理。失败版本保留，后续实质重试使用下一版本；提交与推送仍按本次授权。

检查子 agent 返回的行为、改动文件、执行命令、退出码／结论、产物及未验证范围；查看实际 diff 和关键输出。独立审查按故障影响选择，不能将“另一个 agent 说没问题”当作证据。

若分工或接口变化，先统一实现再执行集成检查。若环境无法运行，标明未验证范围并给出可执行步骤；不要伪造通过，也不要把失败检查删除。完成实现与验证后更新领域文档和进度索引，由主 agent 向用户交付；提交、推送与发布是否执行遵循本次授权。
