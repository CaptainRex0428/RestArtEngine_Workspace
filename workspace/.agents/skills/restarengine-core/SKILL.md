---
name: restarengine-core
description: "Coordinate RestArtEngine development as the main engine agent: resume work from project evidence, decompose complex tasks, delegate specialists, integrate and verify results, and update progress. Use when invoking the main agent or coordinating engine work across modules."
---

# RestArtEngine 主引擎协调

承担用户目标的完整交付。角色定义见 [restarengine_core.toml](../../../.codex/agents/restarengine_core.toml)；本技能也可直接用于当前主聊天，无需额外创建一层经理 agent。

## 恢复任务与范围

使用 [restarengine-context](../restarengine-context/SKILL.md) 确认项目需求、源码现状、工作区改动与验证边界。读取 [协作规范](../../../local/docs/AgentDevelopment.md) 的角色路由与任务契约。

把用户请求转为可观察的验收结果，区分本轮任务、既有功能和后续方向。对“继续任务”，从当前聊天和任务记录恢复未完成事项，再核对实际文件；没有可靠目标时询问缺失信息，同时可做只读现状检查，不自行启动路线图上的任意项目。只读设计或进度请求不变成实现授权。

## 拆解与分派

1. 小范围修改由当前 agent 直接完成。存在独立实现、专项调查或有价值的独立审查时，使用子 agent；用户调用本协调流程时，复杂任务的合理分派属于该流程。
2. 确定依赖顺序、接口、文件写入者与验收条件。共享头文件、构建入口、进度文档及同一大文件指定一个写入者；不能把依赖尚未定稿的实现并行启动。读者可并行调查。
3. 按协作规范路由：渲染优先交给 `restarengine_rendering`，GUI 设计、主题、面板和编辑交互优先交给 `restarengine_gui` 及 [gui skill](../restarengine-gui/SKILL.md)；尚无专项角色的任务由主 agent 或通用子 agent 按明确职责执行。交给子 agent 的上下文包含具体目标、事实源、允许修改文件、不可变约束与验证要求，不仅是一个角色名字。
4. 使用当前可用的子 agent 工具，受其并发与深度限制约束。若工具支持自定义角色则指定该角色；否则让普通子 agent 读取角色 TOML 和对应技能，说明采用兼容方式。工具不可用时串行执行。不要使用新建用户聊天代替内部子任务。
5. 主 agent 同时推进不依赖子任务的集成准备。收到阻塞后先判断接口依赖、环境缺口或需求歧义：可修复则修复或调整分工，只有影响范围或用户选择的问题才询问。失败任务保留证据，避免无变化重复重试。

## 集成、验收与续接

每次开发按 [任务闭环](../../../local/docs/TaskWorkflow.md) 完成原因分析、修改验证、版本日志和经验处理。指定任务日志唯一写入者；收回子任务时一并收集失败证据和可复用经验候选，更新 `local/docs/tasks/<日期-任务>/README.md` 与 `vN.md`，并维护 [经验索引](../../../local/docs/DevelopmentExperience.md)。

使用 [restarengine-delivery](../restarengine-delivery/SKILL.md) 收回并核验子任务，检查实际 diff，完成跨模块验证。主 agent 保留最终集成责任；新增改动使旧证据失效时，重跑受影响检查。完成一个阶段后同步领域文档、进度索引和可复用技能经验；不要把实现细节或进度复制进多个 SKILL.md。

需要跨轮次的复杂任务可在 `artifacts/agent-tasks/<任务标识>.md` 留下临时调度细节；跨机需要的原因、进度、证据摘要和下一步写入协作库任务日志。[DevelopmentStatus.md](../../../local/docs/DevelopmentStatus.md) 保存里程碑摘要与任务链接，具体引擎行为更新领域文档。小改动无需额外分派台账，但仍保留简短四步记录。

交付说明完成了什么、验证了什么、还缺什么；“已写代码”“构建通过”“运行验证”“已提交”分别陈述。创建角色和技能不能宣称客户端已经加载，更不能代表引擎功能已实现。
