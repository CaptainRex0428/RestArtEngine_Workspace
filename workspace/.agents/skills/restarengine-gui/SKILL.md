---
name: restarengine-gui
description: "Design, implement, and review RestArtEngine Project Manager and editor GUI/UX, information architecture, interactions, themes, components, and Dear ImGui layouts. Use for this engine's GUI work; route pure shader, pass, GPU, or backend work to rendering."
---

# RestArtEngine GUI 设计与开发

承担本引擎工程管理器与编辑器的 GUI 任务。项目角色见 [restarengine_gui.toml](../../../.codex/agents/restarengine_gui.toml)；当前 GUI 主聊天可直接使用本技能，无需另建经理 agent。

## 恢复现状与选择模式

使用 [restarengine-context](../restarengine-context/SKILL.md) 核对工作区、进度和源码证据。读取仓库 `AGENTS.md`（若存在）及 [GuiDevelopment.md](../../../docs/GuiDevelopment.md)，后者是 GUI 架构基线、设计标准、流程与验收的事实入口。已经核对且没有相关变化的内容无需重复读取。

按任务选读资料：

- 面板、视口与平台职责：[Architecture.md](../../../docs/Architecture.md)；停靠研究及历史边界：[GodotGuiStudy.md](../../../local/docs/GodotGuiStudy.md)。
- 操作、快捷键与保存：[EditorGuide.md](../../../docs/EditorGuide.md)；命令、输入与撤销：[UndoTransactions.md](../../../docs/UndoTransactions.md)。
- 工程管理器行为：[ProjectManagement.md](../../../docs/ProjectManagement.md)。
- 角色路由、依赖与文件归属：[AgentDevelopment.md](../../../local/docs/AgentDevelopment.md)。

根据请求采用设计、实现或只读审查模式。设计交付可评估的方案与原型，不自行修改引擎代码；实现推进到可观察验收；审查报告具体问题、影响与证据。用户已授权的后续操作继续完成，不把流程变成逐步审批。

## 从行为到可验证界面

1. 确定用户任务、触发场景、当前痛点与可观察结果，查实际面板和状态来源。分清已有实现、已有运行证据、新提案及未验证项。
2. 先处理信息架构、操作入口、反馈与状态转换，再确定布局和视觉表达。按任务需要覆盖空、禁用、编辑、成功与失败等相关状态；标明草稿、预览、提交、保存及取消边界。
3. 用合适的线框、布局说明或可检查原型表达方案，落实组件、层级和尺寸规则。默认延续已有 Black / Dark Blue 主题与工具型桌面编辑器风格；用户要求新方向时按其目标设计，将新的风格选择注明提案。具体视觉和可访问性标准按 GUI 文档执行，引用外部标准时核对原始资料及适用边界。
4. 获得实现授权后沿现有模块落地。先确定跨模块接口与唯一文件写入者，保留他人改动；保护本帧视口图像区域、输入归属、命令和撤销事务，以及预览／Apply／Save／Discard 语义。纯渲染任务路由到 [restarengine-rendering](../restarengine-rendering/SKILL.md)，混合任务与主 agent 协调接口。
5. 依据 GUI 文档选择实际截图、交互及必要回归验证，按 [restarengine-delivery](../restarengine-delivery/SKILL.md) 交付变化、证据与剩余缺口。构建通过不能代替视觉和交互验收；设计原型不能证明引擎功能已实现。

流程按影响范围精简：小幅布局或文案修改不必制作整套设计稿；复杂工作流需要先说明交互契约。规则与进度维护在领域文档，不在技能中复制快照。


## 资产浏览与详情窗口

资产浏览器的事实标准在 [GuiDevelopment.md](../../../docs/GuiDevelopment.md) 与 [EditorGuide.md](../../../docs/EditorGuide.md)，实现入口是 `src/Editor/SceneEditor.cpp` 的 `drawAssets` / `drawAssetGrid` / `drawAssetDetails`。

- 列表与网格共用同一查询结果（`AssetRegistry`），保持导航、搜索、类型筛选与选择语义一致。具体卡片尺寸以 GUI 文档为准；窄窗口与低高度分别验收名称、工具栏、滚动区和底部状态，不将某次布局参数固化为通用规则。
- 锁定 ImGui 版本的 `Selectable` 支持非零显式高度；网格采用固定原点排布时，检查实际 `GetItemRect`、padding 和裁剪，不能把名称被裁切归因于上游忽略高度。
- 双击打开 `Asset Details`（预览 + 元数据 + `Open`），右键菜单区分 `Open`（类型动作）和 `Details...`（信息窗口），不要让双击直接跳走。
- 材质球/网格大图来自渲染器离屏预览；场景缩略图来自保存时生成的 GPU sidecar，都不能当作渲染模块的新场景特性描述。
## 证据边界

- 独立 OS 窗口（材质编辑器）不进入 `--editor-self-test` 主窗口截图；其画面用预览纹理回读或窗口级 `PrintWindow` 验证，不能拿主窗口截图冒充。
- 自测与截图必须跑在临时工程副本上。直接对用户工程执行 `Save All` 会改写其资产（本项目曾把 `.ramat` 转成 `.rasset` 并删除旧文件）；每轮只清理已确认归属的测试夹具目录，证据目录与用户工程分开。
- 固定帧时钟下重复点击同一控件时，磁盘/GPU耗时不计入 ImGui 双击间隔；测试独立拖拽应按 `MouseClickedTime` / `MouseDoubleClickTime` 推进普通帧并断言非双击，避免误开 Details 后把缺少拖拽 payload 归因于生产逻辑。
## 专项角色与交付边界

诊断工具遵守 [Diagnostics.md](../../../docs/Diagnostics.md)。冻结资源图片的鼠标选择不参与 Live 场景输入；外部工具的键盘所有权要在本帧视口处理 hover 快捷键之前确定，只有末尾抑制 Delete/Ctrl+D 不足以保护 F/W/E/R/Space。ImGui 请求选择页签通常下一帧生效，交互自测在切页后提交稳定帧再判断新页内容，保留文本日志与实际截图。

主 agent 分派时提供目标、模式、文件范围、依赖和验收；当前聊天承担 GUI 主任务时直接使用同一契约。跨模块集成与共享进度由主 agent 统一维护。需要修改分派范围或既定接口时先回报协调者。

客户端支持命名角色时使用 `restarengine_gui`；否则由普通子 agent 显式读取角色和技能执行，并如实说明兼容方式。角色文件创建、配置检查、原生加载与引擎运行验证分别报告，不固定模型、provider 或权限，不修改本机配置。
