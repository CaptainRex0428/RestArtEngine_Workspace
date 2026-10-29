# 开发经验索引

Codex 与 DeepSeek 共用此索引，任务开始按问题查阅，收尾按 [任务闭环](TaskWorkflow.md) 更新。经验按主题组织，具体尝试和时间顺序写入任务版本日志；已有规则引用原文，不复制第二套规范。

| 主题 | 经验入口 | 使用时机 |
| --- | --- | --- |
| 大网格性能、缓存与测量 | [MeshPerformance.md](experience/MeshPerformance.md) | 导入后卡顿、拾取耗时、几何缓存失效或性能对比 |
| 并行开发、片段提交与证据 | [Integration.md](experience/Integration.md) | 共享工作区、多任务同文件、独立提交验收 |
| 渲染预览与 GPU 取证 | [渲染技能](../../.agents/skills/restarengine-rendering/SKILL.md) | 离屏目标、独立窗口像素、热编译、GPU 资源生命周期 |
| 隔离测试与交付 | [交付技能](../../.agents/skills/restarengine-delivery/SKILL.md) | 避免真实工程被自测改写、构建锁、有效证据选择 |
| 续接、资产迁移与历史审计 | [协作经验](AgentDevelopment.md#续接与证据管理经验)、[历史审计](DevelopmentChanges-AfterDevLog02.md) | 模型切换、旧证据失效、GUID／格式迁移 |

新增条目使用“场景 → 原因 → 做法 → 验证 → 边界 → 来源”；已有结论优先修订原条目。过时条目注明替代位置和更正依据。规则仍有效但原始证据不在本机时，说明其历史性质。
