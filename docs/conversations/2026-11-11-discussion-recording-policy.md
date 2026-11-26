# 讨论记录规范确立（2026-11-11）

状态：讨论记录；引擎代码未改动。
参与：用户、补充模型（DeepSeek）。
基线：引擎 `14a6b0d`。

关联：[AgentEntry「讨论与学习记录」](../AgentEntry.md#讨论与学习记录必须)、[TaskWorkflow 第 5 步](../TaskWorkflow.md#5-讨论与学习记录)、[_TEMPLATE.md](_TEMPLATE.md)、[学习笔记](../learning/RenderingArchitecture.md)、[方案提案](../design/MaterialTemplateSystem.md)。

## 背景

用户要求：以后每次讨论都要记录为学习讨论或经验，必须落盘，并保证能同步到其他机器（同步目录或 workspace Git 均可），由执行者自行保证合规。

此前 2026-11-11 的 RHI／渲染架构／材质模板讨论已经产出了三份文档，但当时没有把“每次讨论必须记录并同步”本身固化为规则；本次补上规范与执行入口。

## 决定

1. **记录范围**：实质性讨论（架构、原理、方案、排障、工具链取舍）都要记录；不产生代码的讨论同样适用。
2. **文件路由**：
   - 原理／概念学习 → `local/docs/learning/<主题>.md`；
   - 讨论过程与结论 → `local/docs/conversations/YYYY-MM-DD-<slug>.md`，用 [_TEMPLATE.md](_TEMPLATE.md) 起稿；
   - 可复用判断／踩坑 → `local/docs/experience/<主题>.md`，并在 [DevelopmentExperience.md](../DevelopmentExperience.md) 建索引；
   - 未实现的设计 → `local/docs/design/<主题>.md`，标注“提案，未实现”。
3. **收尾动作**：写文档 → 更新经验索引或 [DevelopmentStatus.md](../DevelopmentStatus.md) → `git -C local add/commit` → 推送 `origin/main` → 用 `git -C local status -sb` 与远端 HEAD 确认同步。
4. **跨机保证**：协作库 Git 是事实源；运行目录的 skills／agents 通过 `Sync-Workspace.ps1` 的 Collect／Install 同步。聊天记录、本机绝对路径、凭据和私人配置不作为跨机依据，也不写入文档。
5. **技能固化**：`restarengine-context`、`restarengine-core`、`restarengine-delivery` 增加讨论收尾要求；修改在 `local/workspace/` 源副本完成后安装到运行目录。

## 实施内容

| 文件 | 变更 |
|---|---|
| [`local/docs/AgentEntry.md`](../AgentEntry.md) | 新增「讨论与学习记录（必须）」：路由表、收尾与同步要求 |
| [`local/docs/TaskWorkflow.md`](../TaskWorkflow.md) | 新增第 5 步「讨论与学习记录」 |
| [`local/docs/conversations/_TEMPLATE.md`](_TEMPLATE.md) | 讨论记录模板（背景/问题与结论/方案/未决/证据/同步） |
| [`local/docs/DevelopmentExperience.md`](../DevelopmentExperience.md) | 新增「讨论记录与学习沉淀」索引行 |
| `local/workspace/.agents/skills/restarengine-{context,core,delivery}/SKILL.md` | 加入讨论记录与协作库推送要求 |
| `.agents/skills/...` 运行副本 | 通过 `Sync-Workspace -Mode Install` 安装，Status 20/20 Synced |

## 未决问题

- 讨论记录的粒度：多长算“实质性讨论”由执行者判断，但至少包含问题、结论与证据；纯寒暄或单句确认不单独建文件。
- 是否需要定期把 conversations 的通用结论提炼进 experience；目前按需提炼，不强制批量迁移。
- 文章／DevLog 与讨论记录的关系：讨论记录可作为 DevLog 底稿来源，但发布仍按 DevLog 与发布红线执行。

## 证据与同步记录

- 规范提交：`5c80e57`（docs: require discussion and learning records in the collaboration workspace）。
- 本条记录及状态页更新随下一提交入库。
- 远端：`origin/main`，推送后用 `git -C local status -sb` 与 `git rev-parse HEAD origin/main` 核对。
