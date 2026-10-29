# 本地开发资料与外置配置位置索引

本文件供协作开发与续接，位于公开引擎整体忽略的 `local/` 独立协作 Git 仓库，可随协作库同步，不进入引擎发行包。提交边界以 [RepositoryPolicy.md](RepositoryPolicy.md) 为准；双仓库初始化、同步与换机按 [WorkspaceSync.md](WorkspaceSync.md) 执行。工程不再依赖坚果云同步。

## 三处存放位置

`docs/` 只保留公开引擎技术说明；完整协作、进度、写作和提交规范在协作库 `local/docs/`。根 `AGENTS.md` 和 `scripts/Sync-Workspace.ps1` 是用户允许公开的通用入口，只指向可选协作内容。项目角色和技能仍由 `.codex/agents/`、`.agents/skills/` 发现，两者是引擎库忽略的运行副本，由协作库 `workspace/` 通过清单同步；不改变在 RAEngine 根调用的习惯。

表中“项目根”指当前 RestArtEngine 工作区；`~` 指当前操作系统用户目录。两者下的 `.codex/` 不是同一个目录。

| 资料 | 位置／事实入口 | 可以传到哪里 |
| --- | --- | --- |
| 引擎源码、公共构建配置、示例与技术说明 | 项目根，具体清单见 RepositoryPolicy 与 `.gitignore` | 可提交公开引擎库；个人示例编辑仍须按任务核对。 |
| 引擎内置资产 | 引擎根 `Content/`，首个资产为 `Materials/DefaultMaterial.rasset` | 公开提交并随引擎安装分发；项目引用 ID，不在项目保存时复制。项目自定义副本放自身 Content，取证图继续只在 artifacts。 |
| 通用协作入口 | 项目根 `AGENTS.md` 与 `scripts/Sync-Workspace.ps1` | 公开引擎库可提交；仅指向协作内容并说明可选安装，不含实际协作正文。 |
| 完整协作入口 | `local/docs/AgentEntry.md` | 进入独立协作库，不进入公开引擎库；本机路径另存 machine。 |
| 项目 AI 角色 | 运行 `.codex/agents/*.toml`；版本化 `local/workspace/.codex/agents/` | 协作库同步；只定义职责，不写模型服务配置。 |
| 项目技能与工具 | 运行 `.agents/skills/`；版本化 `local/workspace/.agents/skills/` | 协作库同步，包括 DevLog 技能及媒体检查器；通过清单排除缓存，不提交到引擎库。 |
| 个人 Codex 配置、模型／provider 设置 | 用户目录 `~/.codex/`；具体配置由本机客户端管理 | 仓库外；不抄入角色、技能、开发文档或文章，不读取凭据来生成文档。 |
| 用户级技能与已安装插件 | 当前会话提供的用户目录技能／插件位置，如 `~/.codex/skills/`、`~/.agents/skills/` | 仓库外；按工具安装机制管理，不复制整套到引擎发行包。 |
| 开发需求、当前进度与任务接续 | [DevelopmentStatus.md](DevelopmentStatus.md)、[AgentDevelopment.md](AgentDevelopment.md)；跨机交接放 `local/docs/`，临时任务为 `artifacts/agent-tasks/` | docs进入协作库；临时任务与原始证据只在本机，缺失不可当作本轮已验证。 |
| 引擎诊断设计与实现说明 | 公开 `docs/Diagnostics.md`；本轮接续 `artifacts/agent-tasks/engine-diagnostics.md` | 设计契约随技术文档公开；分派、进度、原始日志/截图留在本地。 |
| 源码阅读与阶段变化审计 | [GodotGuiStudy.md](GodotGuiStudy.md)、[DevelopmentChanges-DevLog02.md](DevelopmentChanges-DevLog02.md)、[标签后审计](DevelopmentChanges-AfterDevLog02.md)、[Content 交付](ContentBrowser-2026-10-28.md)；新笔记放 `local/docs/` | 文字进入独立协作库；提炼后的引擎技术约定单独写入公开领域文档。 |
| 写作规范与底稿 | [ZhihuSeries.md](ZhihuSeries.md)、[ZhihuSeriesLedger.md](ZhihuSeriesLedger.md) | 协作库文本同步，不随引擎提交。 |
| 正式文章、封面源文件、截图和 GIF | 仓库外原内容目录；本机输出根在 `local/machine/Paths.md` | 媒体与正式稿单独管理，不进这两个Git仓库；发布前检查隐私和媒体。停止工程云盘同步不等于迁移外部文章目录。 |
| 同步基线与本机路径 | `local/.sync/state.json`、`local/machine/Paths.md` | 协作库也忽略；不复制另一机器的基线或路径，不同步凭据。 |
| 本地草稿与原始取证 | `.zhihu/`、`artifacts/`、`screenshots/`；验证输出也可能在系统临时目录 | 不提交、不直接作为发布素材；正式媒体整理到外部当期 `_assets/`。 |
| Rider／IDE 辅助资源 | 项目 `.idea/`；`.run/`、`.fork/` 为生成输出 | 默认本地；可提交的少量共享配置仅以 `.gitignore` 例外为准。 |
| 编辑器偏好与引擎安装映射 | 位置见 RepositoryPolicy 的配置表 | 本机使用；不混入场景、共享构建配置或公开示例。 |

## 每次改动同步到哪里

开发流程统一见 [TaskWorkflow.md](TaskWorkflow.md)：任务索引和 v1／v2／后续日志放 `local/docs/tasks/<日期-任务>/`，经验索引为 [DevelopmentExperience.md](DevelopmentExperience.md)，主题经验放 `local/docs/experience/`。这些文本由协作 Git 管理，原始证据继续放引擎忽略的 `artifacts/`，不进入引擎库。

1. 引擎功能、配置格式和操作变化：同步 README／对应公开领域文档，保证使用者不依赖本地资料也能理解和构建。
2. 开发过程、验证结果、待办与后续任务：每个任务更新 `local/docs/tasks/` 的版本日志及索引，DevelopmentStatus 只摘要并链接；临时调度细节可放 `artifacts/agent-tasks/`。收尾新增、修订或注明复用经验，不把时间流水账写回公开说明。
3. 角色或协作流程变化：同步本地 AgentDevelopment、相关角色与技能；统一的位置规则维护本页，由 AGENTS 引用，不在多份文件复制机器路径。
4. 写作与媒体变化：同步本地 ZhihuSeries／Ledger，正式稿与 `_assets/` 留在外部输出根；文章已完成、已审核、已发布分别记录。
5. 新目录、外置配置或提交边界变化：先更新本页；涉及公开提交规则时再更新 RepositoryPolicy 和 `.gitignore`，验证新路径确实被忽略或允许。

## 2026-10-26 清理备份（仅本机）

本次先恢复到用户刚推送的 `ba7311a` 干净检出，再整理目录。备份根为 `E:\Private\RAEngine-local\cleanup-2026-10-26`，不属于引擎仓库：

- `working-state/Projects/Sandbox/` 保存原有 5 个已跟踪文件的未提交修改和新增 `5.ramat`；它们没有自动恢复到当前示例工程。
- `working-state/artifacts/` 保存此前全部验证、截图和交接证据；旧记录里的 `artifacts/...` 若当前不存在，到此归档查找，不视为本轮运行证据。
- `working-state/build/`、`bin/`、`settings/` 等保存旧构建产物；当前工作区需要重新生成与构建，不将移动后的旧构建缓存当作可继续使用的配置。
- `working-state/.idea/`、`.run/`、`.fork/` 及原编辑器偏好保留原本机状态；未自动覆盖新检出的工作区设置。
- `working-state/` 中原始技能／角色／文档、`public-before/` 中原公开文档用于核对；当前使用的是项目内已迁移并更新引用的副本。
- `before.json`、`clean-baseline.json` 记录备份清单、哈希及干净基线。此路径只供本机恢复，不写入公开说明或文章。

外部文章同步目录保持原位置与内容；用户级模型／provider 配置未读取、未修改。新产生的验证产物仍可放项目内忽略的 `artifacts/`，不会自动合并到这次归档。

## 当前任务与经验入口

模型切换继续使用 DevelopmentStatus 和领域文档，不维护第二套模型专属进度。最新基线、逐提交覆盖、待办和证据位置见 [标签后审计](DevelopmentChanges-AfterDevLog02.md)；本轮检查产物在 `local/maintenance/devlog02-catchup/`。临时目录中的截图未归档前不能视为长期可恢复证据。

IDE生成物被忽略不代表可以丢失启动能力：公共Premake脚本应从干净检出重建运行配置；清理后需分别验证生成、构建、IDE发现与Run/Debug。个人workspace不作为唯一配置来源。当前Rider条目生成已实现，实际会话识别仍缺确认。

## 提交、传输与恢复

- 引擎库只暂存本次公开文件，通用入口是明确例外；协作库通过 `git -C local` 单独检查和提交 docs/scripts/workspace 清单。完整技能、角色和开发日志不得进入引擎库，禁止以 `git add -f` 绕过；两个仓库分别核对 `diff --cached` 与 `ls-files`。
- 本机路径只在必要的本地入口记录；token、网关和配置内容不写入本页、进度、技能或文章。公开配置示例只用占位值或可移植路径。
- Git 忽略不会过滤手工压缩、云盘复制、邮件附件或发行包。对外传输按用途选文件并检查实际清单；文章发布授权不代表允许把开发记录或 AI 配置一并发布。
- 换机分别 clone 引擎和协作库，再 Install 恢复原技能/角色路径；服务配置与凭据用工具自己的方式设置。确认本机用户目录、文章输出根并写 machine/Paths.md；文章目录仍须确认 `head.png` 与 `head.psd`。
- 同步工具显式执行 Status/Collect/Install，没有后台云同步或自动推送；协作库完成远端 push 才构成对应提交的异机备份。旧备份段落只保留历史路径和处理记录，不保证那些目录仍存在。
