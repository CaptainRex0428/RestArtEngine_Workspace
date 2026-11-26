# DevLog03 审计：UI／编辑器／资产（一句话带过用）

**口径**：只读审计 `4193f55..26aaf1f`（117 提交），未构建、未运行。`4193f55` 是 DevLog02 正文终点；`ffb7936..b90f541` 属上期收尾，`cc68a1b..daa8859` 的 49 提交已有[标签后审计](DevelopmentChanges-AfterDevLog02.md)与 [Content 交付记录](ContentBrowser-2026-10-28.md)，本页复用结论、不当本轮证据。工作区 GI 修复未提交，不计入。

**上期已写、不重复**：六面板 Docking／布局持久化／视口矩形、Alt 组复制与 Undo、实例 Details 与材质窗口草稿／Two-sided、GC 与 Capture、加载页外观。本期只承接"Scene／Details 分工"。

## 本期新增（按读者能感知的行为）

| 组 | 读者能感知到 | 关键提交 | 证据候选（artifacts/） | 一句边界 |
| --- | --- | --- | --- | --- |
| 选中反馈 | 外轮廓描边、遮挡虚线、前方物体整圈可选、`G`／`H`、独立设置窗（1–6px、主题／预设／自定义，默认 `#FD7804`）、材质拖放目标同通道 | `4f6f87f` `2924e8f` `681edb5` `1fc76d4` `87dda30` `b4de534` `ac13f67` `1b99b60` `40b0469` `9b876cc` `98064d8` `cf51731`；`f6e3295` | `camera/v1/editor/toolbar_outline_window.bmp`（仅设置窗） | 多选／缩放／最终形态缺截图；中间填充与双向比较方案已删，不能写现存 |
| 面板职责与入口 | Details 只管选中 Actor，Scene 只留场景级参数；Activity 进 Details；Outliner 眼睛（一条撤销）；面板可出主窗成系统浮窗并回嵌；底栏＋命令控制台；Profiler／Frame Inspector；底栏 GI 状态可跳 Project Settings | `cdff41e` `d55b9da` `6e92804` `7c87f76` `6c7771e` `802c6c7` `773976d` `ecd90be` `c86a6de` `8f027db` `5c23e42` `9db4815` | `status-bar/v4/editor/status_bar_black_wide.bmp`、`camera/v1/editor/outliner_eye_hidden.bmp`、`floating-windows/commit-validation-05/floating_restored_scene_native.bmp` | 跨屏 DPI／其他平台未验；撤销未覆盖名称与资产分配 |
| 启动加载 | 真实阶段（Shader／PSO／DXR／材质／网格／场景／Content）＋文件名与计数、两行排版；不提前 100%／不切窗后退回；首帧后才 Ready；99% 保持小窗无边框 | `7e5ca88` `a28f38c` | `loading-progress/v3/visual/loading.png`、`editor.png`（963×542 实拍） | 同步观察者、不预测剩余时间；单 Shader／大资产内部仍等待；异步未做 |
| 内容浏览器与资产身份 | Sources／搜索／筛选／排序／List·Grid、类型色、移动限类型根、拖网格入场景一条撤销、导入 OBJ／FBX、Reimport 保 GUID、Delete 查引用；GUID＋`.rasset`、scene v2/v3/v5；Engine 只读挂载＋Copy to Project | `d3ea6d2` `fcbabd8` `368fbca` `5ca9841` `9843248` `40c9b2a` `4e86dd3` `ecace7c` `433c204` `f86b357` `2f717b9` `98af7ea` `9d0f194` `960c1e9` `dc3ceeb` `f6e3295` `eee716d` | `content-browser-v2/final/content_browser_black.png`、`content-asset-colors/final/content_type_colors_black.png`、`content-source-labels/editor/content_grid.bmp`（Engine／Content 文案） | 无纹理载荷／压缩／节点材质／父子层级；文件操作无 Undo；Save Scene 不刷新 `.rthumb`；写盘非原子 |
| 资产详情与槽位 | Asset Details 预览＋元数据；网格逐 Slot 默认材质并写回容器（保缩略图）、Engine 只读；预览拖拽环绕（绕包围盒中心）／缩放／双击复位；预览纹理隔离 | `8f027db` `79bf6d0` `25e1c0b` `0f8cdac` `2062c35` `2c84e99` | `mesh-final2/{asset_details_mesh,asset_details_mesh_orbit,material_slots_many_bottom}.bmp` | 不能增删 Slot／重划 section；不能拖材质到行；整容器重写（398MB 级卡顿）；旋转不持久化 |

**其他一行**：README／公开文档重写同步（`fca018a` `c2ab76e` `c5db70c` `812c513`）、三角统计（`d7d2fe6`）、示例工程调整（`638ae2e` `14a6b0d` `5cafa4b` `86dab47`）不单列模块。

**"一段话带过"建议**

> UI 与资产这条线没有新增渲染特性，但把编辑器从"能编辑"推到"能管内容"：Content 浏览器能浏览、搜索、筛选、拖放、导入与重导入并安全删除，资产有了 GUID 和自包含 `.rasset`，引擎内容以只读来源挂载、需要时可 Copy to Project；网格详情能逐 Slot 声明默认材质并绕物体中心旋转预览；选中描边、面板职责、底栏命令、浮动窗口和真实加载进度把日常操作补齐。

**配图候选（最多 1–2）**：① 内容浏览器终态——当前 HEAD 重拍 1440×900 PNG（Engine／Content、类型色、缩略图），基底 `content-source-labels/editor/content_grid.bmp`；② Asset Details Slot／环绕预览（需重拍，基底 `mesh-final2/asset_details_mesh_orbit.bmp`），或直接复用 `loading-progress/v3/visual/loading.png`。

**新能力边界**：资产无纹理 payload／压缩／调试导出、无节点材质与父子层级、文件操作无 Undo、跨工程引用未做；网格不能增删 Slot、UV 不展开；描边中间方案不能当现存；加载无异步／线程取消；浮窗仅 Windows／DX11／原生 D12 验收；项目设置联动与重启提示已在 HEAD，但运行证据来自隔离基线；三角统计是提交与裁剪计数，不等于可见面数。

**证据等级**：现有 `artifacts/` 都是历史自测截图／日志（B，可复核非本轮运行），部分早于 HEAD。升 A 需在 `26aaf1f` 用隔离工程跑 `--editor-self-test`，导出 1440×900 PNG 并记录主题、构建、D3D11 errors=0；优先补拍描边终态、Slot／环绕预览、Engine Content 终态。DevelopmentStatus 的 Debug／CTest／errors0／截图检查只作历史引用。
