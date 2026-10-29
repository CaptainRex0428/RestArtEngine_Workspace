# RestArtEngine 协作入口

本文件随 `local/` 独立协作仓库同步，由引擎根公开 `AGENTS.md` 引用。完整 AI 角色／技能、开发状态、经验、DevLog 规范与底稿禁止加入公开引擎仓库；根 `AGENTS.md` 和通用同步脚本是明确允许的公开调用入口。边界见 [RepositoryPolicy.md](RepositoryPolicy.md)，同步设计见 [WorkspaceSync.md](WorkspaceSync.md)。引擎开发约定以 [Architecture.md](../../docs/Architecture.md) 和 [README.md](../../README.md) 为准。

## 文件位置与同步入口

完整协作规范、开发过程与日志在协作 `local/docs/` 维护；公开 `docs/` 仍仅放引擎技术说明。公开根入口可以指向可选协作入口，但不能复制协作正文或让引擎构建依赖它。继续在 RAEngine 根调用原有 skills／agents，不从协作库镜像运行。

开发资料、项目技能／角色、用户级外置配置、文章与媒体的位置及传输规则统一见 [`local/docs/LocalDevelopmentGuide.md`](LocalDevelopmentGuide.md)。本地维护的提交规范见 [`local/docs/RepositoryPolicy.md`](RepositoryPolicy.md)。新文件先确定公开／项目内本地／仓库外三类归属；每次更新按位置索引同步对应文档，不把本地进度和个人配置写回公开技术说明。

## Codex 与补充模型

Codex 负责协作编排；具体模型/provider 属于本机 `~/.codex/` 配置，不写入仓库、技能或文章。DeepSeek 在文章中统一称为“补充模型”。不要记录 token、网关地址或本机配置内容。

## Rider / IntelliJ IDEA 资源

与 Rider 或 IntelliJ IDEA 相关的生成文件（包括图标、运行配置辅助资源等）统一放在项目 `.idea/` 目录中，不放入引擎通用资源目录。

## 主引擎 agent 与协作流程

每次开发任务执行 [TaskWorkflow.md](TaskWorkflow.md) 的四步闭环：分析原因、修改与验证、记录 v1／v2／后续版本日志、总结并更新 [经验文档](DevelopmentExperience.md)。Codex 与 DeepSeek 共用任务和经验，不按模型分叉。

调用主引擎 agent、协调复杂任务或继续跨模块开发时，使用 [`.agents/skills/restarengine-core/SKILL.md`](../../.agents/skills/restarengine-core/SKILL.md)。项目角色为 [`.codex/agents/restarengine_core.toml`](../../.codex/agents/restarengine_core.toml)；当前主聊天可直接承担该角色，无需再创建一层经理。

需求与进度入口为 [`local/docs/DevelopmentStatus.md`](DevelopmentStatus.md)，分派、文件归属和验收标准为 [`local/docs/AgentDevelopment.md`](AgentDevelopment.md)。复杂任务按实际依赖自动分派子 agent，简单修改直接处理；渲染使用已有专项角色，其他领域按需增加。具体能力受当前客户端工具限制，不能把普通子 agent 读取角色文件说成原生角色已加载。

## 核心渲染开发

核心渲染、手写 Shader、Pass／管线、渲染特性及跨平台后端任务，使用 [`.agents/skills/restarengine-rendering/SKILL.md`](../../.agents/skills/restarengine-rendering/SKILL.md)。四条要求、验收及设计状态见 [`docs/RenderingDevelopment.md`](../../docs/RenderingDevelopment.md)：工程结构清晰、Shader 热编译可靠、参数实时反馈、便于扩展与移植。

Windows、Linux、macOS 均纳入首轮架构；图形后端范围为 DX11、DX12、Vulkan、OpenGL，按平台／设备能力切换，特性支持按需保留、禁用或明确降级。不要把 RHI 占位或设计目标当作已实现能力。

项目渲染 agent 定义为 [`.codex/agents/restarengine_rendering.toml`](../../.codex/agents/restarengine_rendering.toml)。涉及可独立分派的渲染实现／审查时优先使用该角色；当前客户端无法选取项目角色时，普通子 agent 显式读取上述技能执行。不指定模型或 provider，不改动本机模型配置。

## GUI 设计与开发

本聊天用于引擎 GUI 设计与开发时，可直接采用 [`.agents/skills/restarengine-gui/SKILL.md`](../../.agents/skills/restarengine-gui/SKILL.md)。专项角色为 [`.codex/agents/restarengine_gui.toml`](../../.codex/agents/restarengine_gui.toml)，可独立分派的 GUI 实现／审查优先使用该角色；客户端未暴露命名角色时，普通子 agent 显式读取角色和技能执行，不宣称原生加载。

设计流程、默认风格、外部标准、工程基线和验收见 [`docs/GuiDevelopment.md`](../../docs/GuiDevelopment.md)。按任务规模完成用户任务与状态设计、布局原型、视觉规则、实现及截图／交互验收，保留现有命令、事务、预览和保存契约；设计请求按其范围交付方案。Shader、Pass 和图形后端按渲染专项路由，跨模块任务由主 agent 统一文件归属。

## 知乎连载

触发词：写知乎、下一期、阶段总结、把这阶段写成分享。

本项目的 Codex 技能是 [`.agents/skills/restarengine-devlog/SKILL.md`](../../.agents/skills/restarengine-devlog/SKILL.md)。触发写作时先读取该技能、[`local/docs/ZhihuSeries.md`](ZhihuSeries.md)、[`local/docs/ZhihuSeriesLedger.md`](ZhihuSeriesLedger.md) 和本文件，再按技能执行：确定阶段与日期 → 采集 commit/源码/命令/截图证据 → 先更新底稿 → 写正文 → 自检 → 发布后回填。

本机文章输出根读取 [local/machine/Paths.md](../machine/Paths.md)，该文件不进入公开或协作 Git；不存在时先确认当前机器路径，不从历史记录推断。

- 换机器先确认该机器的文章存储根目录；不要沿用另一机器的绝对路径。
- 目标目录应有 `head.png` 和 `head.psd`；没有就停止写入并重新确认目录。
- 正文命名为 `YYYY-MM-DD_第NN期_短标题.md`，配图放同日期的 `_assets/` 目录。

### 三条发布红线

1. 只写本轮有证据的已完成行为；未运行的代码和计划分别写成 B/C，不写成“现在能”。
2. 正文与配图放同步盘，不提交到引擎仓库；提交前检查 `git status` 和 `git ls-files`。
3. 不泄露 token、provider 网关、内网 URL、本机绝对路径或私人聊天内容。

完整规则与底稿是唯一事实源；不要在本文件复制它们。
