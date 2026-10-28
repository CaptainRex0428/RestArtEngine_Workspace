# Content 浏览器交付记录（2026-10-28）

本地开发记录，不提交。起始 HEAD `daa8859`；本轮在既有文档审计改动之上实现，未创建 commit。用户要求继续优化 Content 的逻辑与显示，主要参考 UE Content Browser。

## 行为与范围

- Sources 树、Back／Forward／Up、面包屑、文件夹卡片；进入目录展开对应祖先。搜索按名称／路径的空格分词匹配，ASCII 不区分大小写；类型、递归范围和排序共享同一查询。
- Tiles／List、缩略图大小、数量与选择状态；宽面板两行工具栏，窄窗换行，低矮面板缩小卡片保留名称和类型；440px 浮窗隐藏 Sources。保留 Black／Dark Blue 和六面板停靠身份，去掉 Content 内部冗余 Meshes 页签与常驻 mesh library。
- 单击资源不修改场景 Actor；双击仍打开 Asset Details，Open 执行类型动作。网格右键创建实例走 UndoStack；Content 焦点屏蔽 Actor 快捷键。
- Move／Open 在遍历结束后执行。材质、网格、场景移动限定对应类型根；文件改名保留 GUID，浏览器按文件名显示。内置网格受保护，目录整体移动暂禁。已加载的材质／网格、当前场景及 Actor 引用资产禁止删除，避免删后又被保存重建。
- 材质／网格递归加载，按 GUID 保留子目录／改名路径，新资产重名不覆盖已有文件；旧 `.ramat`／`.raasset` 保留，同 GUID 现代容器优先，浏览器可显示或隐藏被替代旧文件。普通云同步 reparse 文件不按链接拒绝。
- 首次初始化先加载材质／网格再解析场景 v3。普通 Load Scene 保留原有内存材质语义，没有改成强制重载磁盘资产。
- 工具预览使用实际材质 ID；MaterialEditor／AssetDetails／SceneThumbnail 各有独立纹理与回读接口，另一槽重绘或 resize 不改变本槽。工具相机距离为 1.5–80，主场景保持 2–30。

公开行为说明已同步 README、Architecture、GuiDevelopment、EditorGuide、AssetFormat、RenderingDevelopment。本地 GUI 技能删除固化旧卡片高度的规则，改为引用领域文档与真实裁剪验收。其余此前文档审计改动保留。

## 验证与证据

1. CMake 配置成功，新 `ContentBrowserTests` Debug 构建通过，CTest 65 项断言通过：目录／查询／排序／旧格式、递归持久化、GUID 与路径、同名碰撞、失败不修改资产库、移动与 sidecar。符号链接夹具因本机未持有创建权限跳过，不算通过。
2. Premake 生成的解决方案 Debug 构建退出 0，没有编译告警。最终完整 `--editor-self-test` 退出 0，D3D11 debug layer 开启、validation errors 0。包括非 1 号材质颜色、多槽尺寸与像素隔离、导入网格 v3 编辑器初始化、Content 历史／搜索／类型交集、真实资源点击与 Delete 隔离；既有材质／Shader／Alt 复制／撤销／停靠／视口回归全部保留。
3. 修正旧测试 `.rscene` 拼写并断言实际场景路径，避免共用窗口 ID 假通过。注册表名称断言改为文件名显示的新契约，保留 GUID 检查。
4. 检查实际截图：Black／Dark Blue 网格与列表、根目录卡片、空结果、440×360 浮窗。第一轮发现卡片类型文字裁剪后缩小卡片，最终截图已复核；不是用户视觉签收。
5. 测试使用从 HEAD 已跟踪 Sandbox 制作的独立夹具，自测进一步复制到临时工程。Projects／Shaders 共 27 个文件 SHA256 前后一致，无新增；4 个预存未跟踪材质保留。自测禁用个人 Dock 布局，最终轮从仓库工作目录执行，启动会读取本机主题偏好；不宣称完全隔离所有进程偏好。
6. 74 个公开文档／GUI 技能相对链接有效，GUI 技能 YAML 通过。证据位于 [检查结果](../../artifacts/content-browser-v2/checks.json)、[构建日志](../../artifacts/content-browser-v2/debug-build.log)、[CPU 测试](../../artifacts/content-browser-v2/cpu-test.log)、[最终自测](../../artifacts/content-browser-v2/final/smoke.log)。

截图：[默认网格](../../artifacts/content-browser-v2/final/content_browser_black.png)、[深蓝列表](../../artifacts/content-browser-v2/final/content_list_blue.png)、[窄窗](../../artifacts/content-browser-v2/final/content_narrow.png)。这些是本地测试证据，未整理为文章媒体。

## 与标签后审计的关系及剩余限制

- P02-01／02／03／04 对应实现与上述定向证据已补齐；P02-03 运行证据是独立编辑器初始化夹具，未宣称人工重启所有用户工程。
- P02-07 仅补 sidecar 随文件移动／改名，普通保存刷新策略尚未统一。
- P02-08 工具二次限幅已修正，但仍有 80 距离上限；任意超大场景完整取景未保证。
- P02-09 修正场景详情假通过，仍未补齐所有显式历史版本夹具。
- P02-05 描边 Shader 热更新发布、Save As／New Scene 资产保存顺序、原子资产写入、旧样例损坏 JSON等未在本轮解决。
- 未实现 UE Collections／Favorites／引用图、全工程安全删除／卸载、文件操作 Undo、通用纹理资产和跨平台后端；本轮只验证 Windows／DX11 Debug，未运行 Release 或其他平台。

冻结的 `DevLog02..daa8859` 49 提交审计保留历史结论，后续状态以本记录和 DevelopmentStatus 页首为准。DevLog03 未开始写作或发布。

## 后续：资产类型颜色

新增统一资产类型色（Mesh 蓝、Material 绿、Scene 琥珀、Shader 紫），颜色映射由 EditorTheme 提供，应用到卡片、列表、筛选与详情。公开色值及规则见 GuiDevelopment；本机证据在 `artifacts/content-asset-colors/`，不覆盖上文原交付截图。未增加资产文件字段或改变查询／持久化语义。
