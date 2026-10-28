# DevLog02 标签之后的工程审计与续接

本页只保留本地，不提交。审计日期：2026-10-28。公开行为说明在 `docs/`，本文保存提交覆盖、阅读结论、证据等级与任务状态。

后续实现：2026-10-28 的 [Content 浏览器交付记录](ContentBrowser-2026-10-28.md) 修复本表部分问题并附本轮运行证据。下面仍保留 `daa8859` 时点的历史审计结论，不以未提交工作区改写49提交历史。

## 基线与审计口径

- 本轮区间：`DevLog02^{commit}=cc68a1b8e6fe4a6d3cf955d2ce523043217fb7aa`（不含起点）至 `daa88592eac66697ca74e16f70e7a2022765df60`（含终点），共 **49 个提交**，93 个变更路径，4,651 行增加、1,127 行删除。
- DevLog02 文章覆盖 `6236ce3..4193f55`，实际标签落在后续文档提交 `cc68a1b`。文章终点、标签和本轮工程终点分别记录；不移动标签、不重写旧文，也不由标签推断已经发布。
- 起始 HEAD 与 origin/master 同为 `daa8859`。四个未跟踪 Sandbox 材质 `Copper/Ground/Red/Yellow.rasset` 保留，不删除、不自动提交。本轮只改文档与少量本地技能文字。
- 用户说明本阶段由 DeepSeek 完成。本地未发现独立的 `.deepseek` 开发目录；相关成果使用共同的进度、技术文档、技能和角色体系。本文不凭 Git 作者推断单个提交使用的模型；对外文章继续称“补充模型”。未读取用户级模型配置或凭据。
- 本轮做提交/源码/文档审计、文件格式与链接检查、有限历史截图核对；**未构建、未运行引擎、未验证当前 Rider 下拉**。本页“源码确认”不等于运行验收通过。

## 当前工程能力

| 领域 | 标签后的最终变化 | 边界与事实入口 |
| --- | --- | --- |
| 构建与资料归属 | 本地协作/写作资料移出跟踪，公开文档白名单；Premake 生成 Rider 的 C++ 运行配置和 RefreshConfig；HLSL 在 IDE 列出但不由 MSBuild 编译。 | Rider 当前会话识别尚待确认；生成输出仍在 `.idea/`。见 `Config.lua`、`RestArtEngine.lua`。 |
| 选中反馈 | 独立 SelectionOutlinePass，深度感知实线/遮挡虚线，默认品牌橙，可选前方物体描边、独立设置和持久化；G 切换描边，H 切换可见性。 | Filled/实心相交线等中间试验不是当前模式；最终形态需要补画面验收。见 [Architecture](../../docs/Architecture.md#编辑器选中描边)。 |
| 面板与可见性 | Details 编辑选中 Actor 实例与资产引用；Scene 管场景级背景、光照和阴影；Activity 进 Details；Outliner 眼睛与行共享矩形，可见性纳入撤销。 | 资产详情 Asset Details 与场景实例 Details 是两种对象；名称/资产分配仍未入撤销。见 [EditorGuide](../../docs/EditorGuide.md)。 |
| 启动与窗口 | 独立无边框加载窗占主屏宽28%，按图像比例；编辑器80%居中；Project Manager 1080×720居中；窗口切换复用设备与管线。 | 交互启动与自测的固定窗口路径不同；不由自测窗口推出双窗口启动/DPI验收。见 `app/MinimalApp.cpp`。 |
| Content | 递归注册表、文件夹树、List/Grid、导入、移动/重命名/删除、活动场景；网格格子显示缩略图与名称；双击打开 Asset Details，Open 执行类型动作。 | 浏览器能看到文件不等于加载器会读取；移动后的重启引用是独立验收点。 |
| 资产与场景 | 64位 GUID、RAAS `.rasset` 容器，材质与静态网格自包含；内置图元落盘；场景写v3引用，兼容v1/v2、旧`.raasset`/`.ramat`。 | 保留旧材质但不同步两份内容；纹理载荷、压缩、原子保存仍缺。见 [AssetFormat](../../docs/AssetFormat.md)。 |
| 缩略图与预览 | 64px CPU资产缩略图、160px可交互材质球、190px资产预览、128px GPU场景sidecar及CPU回退。 | 任意材质ID、多窗口纹理和大场景取景有缺口；普通Save Scene不刷新sidecar。 |
| 验证与数据保护 | 增加资产、预览、浏览器相关自测；保存容器不删除旧`.ramat`；编辑器自测复制工程到临时目录；夹具每轮重建。 | 只隔离editor-self-test，最初resolve发生在复制前；异常早退/强制结束不保证临时目录清理。 |

DX11仍为唯一真实场景后端。Forward/Deferred、已有阴影算法、Two-sided、Alt复制、GC、Capture选址等是标签前能力，本轮不能再次作为新增成果计数。DX12/Vulkan/OpenGL、Linux/macOS、通用RHI、纹理/UV、节点材质、BVH/DXR、异步Shader编译未由这49提交实现。

## 源码缺口与下一步任务

以下状态均为“待执行”，不在本轮文档任务内修代码。优先级是后续建议；“源码确认”与“待运行复现”单列。

| ID / 优先级 | 当前结论与位置 | 下一步验收条件 |
| --- | --- | --- |
| P02-01 / 高 | **源码确认**：材质预览临时球固定 materialId=1，覆盖仅在ID相等时生效；新GUID/非1号材质显示默认参数。`SceneRenderer.cpp` 的 `renderMaterialPreview` / `resolveMaterial`。 | 对两个非1号材质验证颜色差异、草稿/Discard、材质窗和Asset Details各自预览。现有红绿测试只测ID1。 |
| P02-02 / 高 | **源码风险，待运行复现**：160px材质窗、190px Asset Details、128px场景缩略图共用可重建SRV；ImGui提交前后可能覆盖内容或失效。`renderPreviewFrame` 与 `SceneEditor::draw`。 | 同帧打开两个不同资产预览并保存场景，验证纹理独立、D3D11零错误及关闭/重建生命周期。 |
| P02-03 / 高 | **源码确认**：initialize先World::load、后loadMeshes；v3引用导入网格的默认场景可能启动失败，openScene顺序正确。`SceneEditor.cpp:117–139`。 | 导入OBJ→保存→进程退出→重开工程；缺失网格明确报错且保留原状态。 |
| P02-04 / 高 | **源码确认**：浏览器递归，loadMaterials仅扫顶层；移到Materials子目录后重启无法靠同一路径解析。`AssetLibrary.cpp:212`。 | 材质移入子目录、重命名、重启、再保存，GUID与引用稳定；定义允许的移动范围。 |
| P02-05 / 高 | **源码确认**：候选编译8个Shader，Apply只发布原六个，漏outlineMaskPS/outlineCompositePS。`SceneRenderer.cpp:1324`。 | 成功Reload更新描边；任一编译/契约失败保留整套旧管线；修成功诊断和测试枚举。 |
| P02-06 / 中 | **源码风险**：Save As/New Scene直接World::save，没有普通saveScene先保存资产的步骤。`SceneEditor.cpp:1148/1160`。 | 新建内存资产后Save As，再独立重启加载目标场景，所有引用可解析；失败保旧。 |
| P02-07 / 中 | **源码确认**：只有传renderer的保存生成sidecar；普通Save Scene、Ctrl+S、Save As不刷新；移动不随迁sidecar。 | 统一或明确更新策略，验证过时图、保存失败、重命名/移动后的图像来源。 |
| P02-08 / 中 | **源码确认**：预览取景距离1.5–80/材质控件1.6–8，被公共render再限到2–30。 | 大/小场景与模型完整取景，UI有效距离与渲染一致。 |
| P02-09 / 高 | **源码确认的测试盲区**：Asset Details场景测试拼成`.rscene`，共用`###AssetDetails`可能命中旧窗；SceneV2RoundTrip实际写v3。 | 分别断言场景路径/类型/内容及不存在路径失败；显式v1/v2/v3夹具；不能只查窗口存在。 |
| P02-10 / 中 | 编辑器自测先resolve源工程后复制，恢复关联可能写源manifest；复制/二次resolve失败发生在清理登记前。 | 失效关联、复制失败、解析失败下核验源工程哈希和临时目录；明确强制结束边界。 |
| P02-11 / 中 | 资产当前直接覆盖写；无纹理载荷、压缩与dump工具。 | 先明确原子保存方案及失败保旧测试；其余按实际需求排期，不当已授权实现。 |
| P02-12 / 中 | Rider生成器已提交，当前IDE识别与Run/Debug仍缺验收；描边最终遮挡形态、G/H行为与多选/缩放也缺稳定证据。 | 干净检出生成→IDE识别→Run/Debug；描边与快捷键分别留真实日志/图像。 |
| P02-13 / 中 | **本轮格式检查确认**：RayTracing_Simple的5个`.ramat`仍为非法JSON；旧Test-Window允许空ExitCode却记录0成功。 | 独立修复示例/严格退出判断并重验；不能从本轮文档更新消项。 |

四个未跟踪Sandbox容器、外部清理备份尚未清除、文章发布状态未回填属于保留事项，不自动合并、删除或发布。清理证据仍记录 `backup_removed:false`；本轮不重试删除。

## 验证证据与可信度

1. **本轮直接确认**：Git区间/源码、文档、13个示例JSON的解析（8合法、5失败）；改动文件链接/公开边界/受保护文件哈希见 `local/maintenance/devlog02-catchup/checks.json`。没有本轮引擎构建/运行结论。
2. **历史报告**：DevelopmentStatus中Debug/Release零warning、自测PASS、D3D11零错误属于既有叙述。多数没有关联完整命令、退出码和构建commit，不能据此说当前HEAD已复测。
3. **项目内原始资料**：`artifacts/rider-premake/` 有此前隔离导出/生成/构建检查；`generation-checks.json` 的 `ui_verified:false`。它早于本阶段终点，不能证明当前Rider识别。`artifacts/devlog02-writing/` 是上期媒体检查，不能证明新功能。
4. **现存系统临时目录**：`D:/tmp/asset-details6/`、`isolate-3/`、`isolate-rel/`、`final-assets-Debug/`、`final-assets-Release/` 尚有截图。已由只读审计目视 `D:/tmp/asset-details-window2.png`（Sphere预览及元数据）；`D:/tmp/content_grid.png` 属早期无名称网格，不能证明最终名称修复。`D:/tmp/rae-selftest.log` 为空。这些路径仅本机，不上传；截图不能单独证明命令成功或最终HEAD一致。
5. **需要补证据**：后续验证以修复后的明确commit、可执行文件哈希、命令、退出码、设备、主题/尺寸、场景副本、日志/截图清单绑定。主窗口截图不包含独立材质窗；像素回读也不能证明原生窗口位置/DPI。

## 开发经验与管理同步

- 保留既有 core/context/delivery、GUI/rendering 专项分工，不新增一套模型专属事实源。任务状态沿用“待执行→执行中→待验收→完成”，实现状态与运行证据分别记录；本表是当前待办入口。
- 数据格式迁移必须验证“保存→退出→重开”，浏览注册表与运行加载器扫描范围必须一致；默认资产测试不能代替随机GUID资产测试。
- 新Pass进入编译候选后，还要核对发布、资源绑定、失败回滚和销毁；不能只增加Shader入口而漏热更新赋值。
- 多窗口预览须按消费者确认纹理生命周期，不能只验证单窗口的一张图。
- 保存与自测使用自有临时副本；初次解析、失败清理和路径重绑同样属于隔离边界。夹具清理仅针对已确认归属的测试目录；同一solution构建串行。
- Selectable非零高度在锁定ImGui源码中生效。网格用手工原点排布是本项目选择，不能把曾经的裁剪/行高问题写成上游忽略高度。图标按真实20px及行矩形验收。
- 失败重跑通过仍保留首次失败证据；历史“偶发时序抖动”需要定位，不能用重跑抹去。
- 文章规范中的共享开发审计、旧角色登记方式、`zhihu-NN`标签等漂移本轮纠正；DevLog03尚未开始，不生成正文或媒体。

## 阅读覆盖

主/专项审计已通读 README、12份公开docs（含vendor说明）、assets/icons/README、vendor/README；8份local/docs、AGENTS、6个项目技能、3个角色定义。源码按49提交分为渲染/描边/预览、资产/场景/编辑器/自测、构建/窗口/提交边界核对；未声称逐行阅读全部vendor或未改动的引擎源文件。公开文档只描述引擎事实，本页、进度、经验和技能均保持Git忽略。

历史审计 [DevelopmentChanges-DevLog02](DevelopmentChanges-DevLog02.md) 与 [GodotGuiStudy](GodotGuiStudy.md) 保留原阶段口径；当前总入口为 [DevelopmentStatus](DevelopmentStatus.md)。

## 49个提交逐项覆盖

此表来自本轮固定区间，每个提交恰好一行；功能解释以本页最终行为为准，不把被后续替换的中间方案累计为独立能力。

| 提交 | 日期 | 内容 |
| --- | --- | --- |
| `9239226` | 2026-10-26 | chore(repo): keep AI workflows and devlogs local |
| `ba7311a` | 2026-10-26 | docs: clarify configuration locations and publication boundaries |
| `8ad6255` | 2026-10-26 | docs: limit published documentation to engine usage and architecture |
| `b90f541` | 2026-10-26 | fix(premake): regenerate Rider run configurations after editor cleanup |
| `4f6f87f` | 2026-10-26 | feat(editor): add screen-space selection outline for the viewport |
| `2924e8f` | 2026-10-26 | feat(editor): expose selection outline settings in the UI menu |
| `681edb5` | 2026-10-26 | feat(editor): move selection outline settings into a dedicated window |
| `1fc76d4` | 2026-10-26 | feat(editor): allow a custom selection outline colour |
| `87dda30` | 2026-10-27 | feat(editor): depth-aware outline, dashed occluded edges and G/H toggles |
| `b4de534` | 2026-10-27 | fix(editor): draw occluded outline as a dashed contour instead of a fill |
| `ac13f67` | 2026-10-27 | fix(editor): keep occluded outline dashed-only, drop the fill mode |
| `1b99b60` | 2026-10-27 | fix(editor): stop outlining the occluder in front of the selection |
| `40b0469` | 2026-10-27 | feat(editor): make outlining front occluders an outline option |
| `9b876cc` | 2026-10-27 | feat(editor): offer a solid occluder intersection line instead of whole-occluder outlines |
| `98064d8` | 2026-10-27 | feat(editor): make outlining front objects an explicit outline option |
| `cd021a8` | 2026-10-27 | chore(test): drop unused variables flagged by C4189 |
| `0ebaaa8` | 2026-10-27 | update scene sandbox |
| `cf51731` | 2026-10-27 | feat(editor): default the selection outline to the brand orange |
| `cdff41e` | 2026-10-27 | feat(editor): move actor properties to Details and leave Scene to scene-level parameters |
| `b446f64` | 2026-10-27 | feat(boot): borderless loading window at 28% width, centred 80% editor window |
| `d55b9da` | 2026-10-27 | feat(editor): move key light and shadow settings into the Scene panel |
| `7c87f76` | 2026-10-27 | feat(editor): clickable visibility eye on Outliner Actor rows |
| `bae6db9` | 2026-10-27 | docs(gui): note the Outliner visibility eye row structure |
| `6c7771e` | 2026-10-27 | fix(editor): centre the Outliner visibility icon in a fixed column |
| `802c6c7` | 2026-10-27 | feat(ui): line-art visibility icon and assets/icons convention |
| `773976d` | 2026-10-27 | fix(ui): readable 20px eye icon with eye-shaped lens and solid pupil |
| `ecd90be` | 2026-10-27 | fix(editor): share the Outliner row rect between the eye and the label |
| `6e92804` | 2026-10-27 | feat(editor): show the activity status at the top of Details |
| `6a3c2b2` | 2026-10-27 | build: list HLSL sources in the solution for IDE editing |
| `d3ea6d2` | 2026-10-27 | feat(content): asset registry, folder browser with drag move, active scenes |
| `06db9db` | 2026-10-27 | docs(assets): decide materials live in .raasset |
| `fcbabd8` | 2026-10-27 | feat(assets): GUID identity and .raasset container for materials |
| `368fbca` | 2026-10-27 | feat(scene): scene v2 references materials by GUID |
| `5ca9841` | 2026-10-27 | feat(editor): resolve scene v2 materials from Content on load |
| `9843248` | 2026-10-27 | feat(assets): static mesh assets and scene v3 mesh references |
| `a678dba` | 2026-10-27 | fix(launcher): open the project manager centred on the primary monitor |
| `40c9b2a` | 2026-10-27 | feat(assets): generate built-in primitives as raasset files |
| `4e86dd3` | 2026-10-27 | feat(assets): generate and show 64px container thumbnails |
| `ecace7c` | 2026-10-27 | refactor(assets): rename the container extension to .rasset |
| `433c204` | 2026-10-27 | feat(content): grid view and scene thumbnails |
| `0f8cdac` | 2026-10-27 | feat(material): GPU offscreen sphere preview in the material editor |
| `fdc49b5` | 2026-10-27 | docs(editor): note the live material sphere preview |
| `2062c35` | 2026-10-27 | feat(preview): orbitable material ball and GPU scene thumbnails |
| `f86b357` | 2026-10-27 | feat(content): show asset names under grid thumbnails |
| `8727ffa` | 2026-10-27 | test(content): rebuild the scene fixture directory each run |
| `2f717b9` | 2026-10-27 | feat(content): asset details window with live preview |
| `98af7ea` | 2026-10-27 | fix(assets): keep legacy .ramat files when saving container materials |
| `d87156f` | 2026-10-28 | test(editor): run self-tests against a temporary project copy |
| `daa8859` | 2026-10-28 | docs: sync references with the .rasset pipeline and content browser |
