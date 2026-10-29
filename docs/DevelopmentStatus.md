## 进度同步快照（2026-10-30，补充模型）

读取协作入口、任务闭环、状态页、任务日志与经验索引后的对齐结果；本段只同步仓库事实与 Codex 记录的验收摘要，本轮未重新构建或复验 GPU 数字。

**引擎仓库**

- `master` HEAD `c86a6de`，`origin/master` 仍为 `f6e3295`；`eee716d`（资产重导入/删除）、`8119e01`（间接漫反射强度）、`c86a6de`（浮窗越界）三个提交未推送。
- 工作区 49 个已跟踪文件修改、39 个未跟踪路径（`Projects/PathTracing_CornellBox/`、`Shaders/Private/DepthOfField.hlsli`、`Lighting.hlsli`、Sandbox 资产等），对应 Camera／四分屏 DOF／GI／DXR／导入与 Content 的进行中改动，未提交。
- `codex/cornell-box` 分支有 `638ae2e`（Cornell 示例与矩形灯），未合入 master。

**Codex 任务日志已记录、本轮未复验的验收**

- 统一 Camera v6：20/20 CPU、8 次真实 DXR dispatch、GI 1568、完整 Editor 通过，errors 0（[任务](tasks/2026-10-30-camera/v6.md)）。
- 四分屏与景深 v2：20/20 CPU、Camera 37 次 dispatch、GI 1568、三格正交拾取，errors 0（[任务](tasks/2026-10-30-camera-quad-dof/v2.md)）。
- 间接漫反射强度：已提交 `8119e01`；GI 1458 与 UI 230 次真实 DXR dispatch，errors 0。
- 网格 Slot／UV v3：18/18 CPU、属性 27 + 硬件 206 + GI 1291 dispatch，千万面 10,000,024 三角形通过（[任务](tasks/2026-10-29-mesh-slots-uv/v3.md)）。
- 灯光 v3：16/16 CPU、灯光 84 + GI 1291 dispatch、完整自测通过（[任务](tasks/2026-10-29-lighting/v3.md)）。
- 资产重导入/删除：提交 `eee716d`，14/14 CTest、完整隔离自测；浮窗越界：提交 `c86a6de`，完整 Editor 自测。
- 各任务证据目录与原始 artifacts 只在本机；跨机读取时按历史验证处理。

**资产管线侧（补充模型实现，已冻结审计）**

- `daa8859` 及之前的 49 个提交由 [DevLog02 后审计](DevelopmentChanges-AfterDevLog02.md) 与 [Content 交付记录](ContentBrowser-2026-10-28.md) 记录：`.rasset` 容器、GUID、64px 缩略图、Asset Details、可旋转材质球、GPU 场景 sidecar、自测临时工程隔离均在其中。
- Codex 在 10-29 的导入、Engine 网格与 Content 重构接续这些接口，公开文档已同步。

**同步后的待办**

1. 为 49 文件工作区改动分类、补验证并提交；三个未推送提交按授权推送。
2. `codex/cornell-box` 合入并处理共享 Shader／SceneEditor 冲突。
3. DevLog03 尚未开始，素材未整理。

边界：本节只记录仓库状态与任务日志摘要，未运行引擎，不把 Codex 的 GPU 数字转写成本轮验证；技能运行副本 Status 为 Synced。
## Cornell 示例独立提交（2026-10-30）

Cornell Box 示例及必要场景／矩形灯支持已提交 638ae2e（codex/cornell-box，基线f6e3295）。独立Debug无警告、10/10 CPU、GI1261真实dispatch/errors0、完整Editor和1024/1024样例通过。共享master同期被其他任务推进，本次使用独立索引／分支，未合入master、未推送；其他功能和用户工程保持原工作文件。后续集成需处理共享Shader/SceneEditor改动并重验。详见[任务v2](tasks/2026-10-29-cornell-box/v2.md)。

## 四分屏与景深（2026-10-30）

在Camera首版上接通四格独立相机、激活/导航/拾取路由、最大化/恢复及窄窗口切换；激活格沿用主DXR/GI历史，其余三格使用独立Raster输出。Camera Actor及自由视图支持DOF开关、对焦距离、f-stop、传感器高度；光栅/Realtime采用屏幕景深，Progressive为圆孔径薄透镜采样，正确区分history失效。DOF撤销、关闭保值、开场书签及v7场景保存兼容接通。

Debug构建无警告，20/20CPU、Camera GPU37次实际DXR dispatch、GI全套1568dispatch及最终完整Editor通过，图形错误0；三格正交拾取、真实焦点控件Undo/重开和两主题截图已验证。屏幕DOF焦平面像素差0，近远条纹边缘能量下降；PT焦平面和孔径效果有实际图像证据。最后工具栏两行/半透明微调按低风险视觉变更额外构建及演示截图验收。原Projects34文件哈希不变；独立演示入口 `artifacts/camera-quad-dof/Open-CameraStudio.cmd`、默认景深输出 `View-DepthOfField.cmd`。范围与证据见[任务v2](tasks/2026-10-30-camera-quad-dof/v2.md)，经验与公开Camera文档同步。当前仅一个常驻主DXR历史；屏幕景深有24px半径及遮挡/深度近似限制。未提交／推送。

## 统一Camera系统首版（2026-10-30）

视口、场景Camera Actor与工具预览统一平台无关Pose/Lens/View求值，透视/正交、六向视图、Orbit/Fly、实际画幅内拾取/Gizmo/拖放接通。Camera创建与镜头Details、只读查看/显式操纵、连续手势Undo、默认输出引用、独立Raster预览及v6场景保存重开完成；旧v1–v5与开场书签兼容。正交观察方向、深度、CSM、光追射线和GI像素尺度同步，ViewId防历史误复用。当前单主时间历史，无四分屏或多套常驻DXR历史。

Debug无警告构建、20/20 CPU及导航回归、Camera GPU 8次真实DXR dispatch、GI1568次dispatch/errors0通过。最终v6完整Editor退出0，Camera创建/真实镜头控件Undo/默认引用/固定画幅/View/Pilot/恢复自由视角/正交拾取/两主题预览/保存重开/删除Undo全部PASS，D3D11 validation errors0；原生浮窗、资产/材质保存、灯光、Shader与布局旧回归同样通过。证据 `artifacts/camera/v6/editor.log`，程序 `build/camera/Debug/RestArtEngine.exe`，独立演示 `artifacts/camera/Open-CameraStudio.cmd`。最终默认相机无UI演示16帧/exit0/errors0、真实截图已检查，原Projects 34文件SHA256全不变，完整性与源码快照位于v6证据目录。失败原因及修复保留v1–v5；公开说明 `docs/Camera.md` 已加入文档allowlist，[任务v6](tasks/2026-10-30-camera/v6.md)与[经验](experience/Camera.md)同步。未提交／推送。

## 间接漫反射强度独立提交（2026-10-30）

已提交8119e01 `feat(renderer): add configurable indirect diffuse intensity`，仅10文件239新增／13删除的参数／持久化／实时UI／首段BRDF+PDF增益／history及测试文档；保留其他任务和用户工程在工作树。相对已提交基线独立构建无警告、9/9 CPU、GI1458与硬件UI230真实DXR dispatch全部通过，errors0；候选按暂存blob校验，真实紧凑UI截图通过。隔离首次误读注册表中的工作引擎导致Shader布局拒绝，已通过夹具绝对engineRoot修正并保留失败证据。未推送，常用bin保留完整工作树交付版本。详见[提交v3](tasks/2026-10-30-cornell-bleeding/v3.md)。下段未提交为当时状态。

## 可配置间接漫反射强度（2026-10-30）

用户选择艺术互染控制后，Project Settings→Rendering新增Indirect diffuse intensity（0–8，默认1）。实时／渐进统一在第一接收表面的间接漫反射BRDF应用一次，匹配采样PDF；直接灯光及间接镜面分量不被倍乘，后续反弹不重复放大。倍率变化实时重置history，贡献关闭保值，项目JSON缺失默认1／严格有限范围验证／保存重开接通。沿用现有GI分类，漫反射采样环境照明也随倍率变化。

Debug无警告构建、20/20 CPU、GI1568与硬件/UI230真实DXR dispatch通过，graphics errors0；实际鼠标拖动、持久化、常规／紧凑UI截图检查通过。3倍间接贡献的近似显示反演比2.9918、纯金属接收面像素误差0；真实Cornell1x/3x各1024样本／64dispatch图像已查看。29用户工程文件哈希未变；本轮GI源码和产物稳定，后续并发Camera7文件变化保留且不计入本轮验收。常用bin Debug已更新并校验。详见[任务v2](tasks/2026-10-30-cornell-bleeding/v2.md)，经验补充至PathTracingExamples；未提交／推送。

## Cornell 地面互染偏弱诊断（2026-10-30）

实际场景GI两贡献开启／12反弹，地面非金属；只读积分审查未发现明确系统性衰减错误。四组隔离GPU对照（原场景、关间接、侧墙中性、提高侧墙反射率）均1024样本／64真实dispatch／errors0，确认红绿墙颜色实际传到地面，提高墙面反射率会增强色偏。仅显示域ROI证据，不当作物理参考精度证明。保留用户场景全部参数与资产，未改生产代码；已询问物理场景调整或艺术增益偏好，后续依回复实施。详见[诊断v1](tasks/2026-10-30-cornell-bleeding/v1.md)，经验补充至PathTracingExamples，未提交／推送。

## 导入网格多材质 Slot 与四套 UV（2026-10-30）

FBX 按实例面材质 ID 保留命名 Slot／连续 section、最多 UV0–UV3；OBJ 支持 usemtl 与一套 vt，接缝与镜像角点对应保留。所有属性在同一 .rasset；无 UV 仍为 24B 顶点，旧资产兼容。Actor 每槽独立材质覆盖、实时草稿、Undo／Redo、命中面拖放、v5 场景保存与来源身份重映射接通；光栅、阴影、软件射线、DXR／GI统一解析。Asset Details 展示 Slot 与 UV，长列表可滚动。不能自动转换 DCC 材质图／贴图；旧模型需 Reimport 获取此前丢弃的属性，同名源材质无法唯一匹配时拒绝重导入并保留原资产。

Debug 无警告构建、18/18 CPU、属性GPU专项27 DXR dispatch、完整Editor、硬件回归206 dispatch、GI回归1291 dispatch全部通过，图形错误0；四UV／25Slot截图已检查。千万面兼容测试在RTX5060、1080p、DXR+实时GI通过（10,000,024 triangles，66 dispatches，无FPS门槛）。Audi原FBX只读解析25Slot／25section／1UV，未修改原模型。122源码／产物哈希稳定，Sandbox资产未改；Cornell配置外部采样设置变化保留。常用bin Debug已更新并哈希匹配。公开说明与[任务v3](tasks/2026-10-29-mesh-slots-uv/v3.md)、[经验](experience/MeshAttributes.md)同步；未提交／推送。

## 五类场景灯光模块（2026-10-29）

已增加 Directional／Sky／Rect／Spot／Point Light Actor，创建菜单、Details实时参数、撤销、视口标记拾取/Gizmo与保存重开接通；含灯光场景v4，旧v1-v3兼容。共享b7支持32直接灯与独立Sky聚合，Forward／Deferred／软件光追／DXR／GI统一，保留Cornell矩形MIS并扩展到多Actor Rect，参数变化重置GI历史。普通Raster/Realtime局部直接阴影须AnalyticRay，硬件preview/Progressive支持DXR阴影；程序化Sky不含HDRI，矩形发光面本体仅Progressive主成图可见。

Debug无警告构建、16/16 CPU、灯光专项84真实DXR dispatch、GI全套1291 dispatch、完整editor-self-test通过，graphics errors 0；实际两主题截图已检查。首次GUI因新增按钮挤掉Outliner列表失败，v3改为同行创建/窄矮菜单后完整通过，失败记录保留。交付程序 build/cmake-lighting/Debug/RestArtEngine.exe；用户常用bin进程未关闭或覆盖。自测使用隔离夹具；收尾真实Sandbox场景/缩略图在自测退出后再次保存，保留外部更新，其余22文件哈希一致。公开技术说明、[任务v3](tasks/2026-10-29-lighting/v3.md)及[经验](experience/Lighting.md)已同步；未提交／推送。

## Cornell Box Path Tracing 示例（2026-10-29）

新增 Projects/PathTracing_CornellBox：红绿房间、三种粗糙度金属球、真实矩形顶灯，Engine网格引用、6个现代材质及缩略图、渐进4 SPF／1024目标／8次表面着色、初始曝光0.38。补齐可选场景camera／lighting及Scene编辑入口；矩形单面发光、主射线／反射可见、面积与BRDF采样MIS、有限遮挡和历史失效。通用emission材质和玻璃折射未实现，矩形仅progressive PT。

固定源码独立Debug无警告构建、16/16 CPU、GI专项1261真实dispatch／errors0、样例1024/1024样本／256dispatch通过；真实样例及32帧编辑器启动截图已查看。生成器拒绝覆盖且重建字节一致，原工程23文件哈希未改；公开说明、任务及经验同步。常用bin已有用户进程运行，未关闭／覆盖，验证程序位于build/cornell-box/Debug/RestArtEngine.exe。保留同期LightActor开发；其完整GPU功能不属于本轮验收。未提交／推送。见 [任务v1](tasks/2026-10-29-cornell-box/v1.md)、[经验](experience/PathTracingExamples.md)。

## 资产重新导入与删除（2026-10-29）

2026-10-30 已按本功能片段提交 `eee716d`（feat(assets): add reimport and safe asset deletion），16 文件，未推送。精确候选独立 Debug 构建、10/10 CTest、完整 editor-self-test 通过，D3D11 errors 0；其他工作区及并行任务的 10 项暂存保留。[提交验收](tasks/2026-10-29-asset-lifecycle/commit.md) 记录版本适配与隔离测试工程绑定修正。

Content 右键新增 Reimport（原来源）和 Reimport from...（新来源），项目 Imported Mesh 保留 GUID／名称／位置，几何及预览更新；解析／写入失败保留旧数据。Delete... 可删除未被引用的已加载项目网格／材质，保护当前与保存场景引用、Engine、活动／启动场景和材质草稿；同步磁盘／内存，保留外部源文件，确认窗说明成功后清空场景 Undo／Redo。重复 GUID／legacy 或无法验证依赖时拒绝。

CMake Debug、Premake Debug（0 warning/error）、14/14 CTest、完整隔离 editor-self-test 通过，D3D11 errors 0；真实菜单／确认、两主题列表／网格、同 GUID GPU 几何更新和删除后无复活已验证，Sandbox 15 文件哈希未改。常用 bin Debug 已更新。新源执行服务已测试，原生选择窗口未自动化操作；符号链接夹具因权限跳过。详细 [任务 v1](tasks/2026-10-29-asset-lifecycle/v1.md)、[经验](experience/AssetLifecycle.md)，证据 `artifacts/importing/asset-lifecycle/`。未提交／推送。

## Audi FBX 移除圆柱体（2026-10-29）

从已清理 FBX 移除独立 Cylinder.001，另存 Cleaned_NoCylinder.fbx；其余属性逐项不变，原件保留。Blender 实际打开及引擎严格导入通过，剩余 73 网格、3,873,168 三角形。仅处理外部资产，未修改引擎源码或项目；[任务记录](tasks/2026-10-29-fbx-remove-cylinder/v1.md)，证据 `artifacts/importing/fbx-no-cylinder/`。未提交／推送。

## 编辑器底栏与命令控制台（2026-10-29）

新增固定底栏：Content／Output Log／Cmd／Diagnostics／Tools 与分类保存状态。命令共用现有编辑器操作和撤销，支持 help、Tab 补全、历史／草稿、选择 Actor、保存和诊断；日志保留会话命令及编辑器提示。高缩放底栏高度计入 ImGui 最小窗口尺寸，DockSpace 与视口真实排版，文本焦点不透传场景。

Debug 无警告构建、13/13 CPU、完整 editor-self-test 通过，D3D11 errors=0；两主题 1440px／680px＋150% 截图已检查，用户 Sandbox 14 文件哈希不变。Premake 已刷新，常用 bin Debug 已与验证产物哈希匹配。公开操作／架构文档、任务版本及经验已同步；未提交／推送。详情见 [任务 v4](tasks/2026-10-29-status-bar/v4.md)，经验见 [EditorConsole](experience/EditorConsole.md)。首轮增量混编崩溃、测试页签延迟、最小高度越界分别保留失败记录；不宣称全量日志、Content 临时抽屉或非 Windows 验收。

## 普通浮窗跨主窗口边界（2026-10-29）

2026-10-30 提交完成：c86a6de，仅浮窗修复、自测与文档 15 文件，未推送。候选合并到 8119e01 后独立 Debug 无警告构建，完整 Editor 自测退出 0、D3D11 错误 0；本轮原生外窗图像已查看，真实外移／回嵌与跨窗口投递通过。补充处理测试中重叠浮窗的实际 z-order 与拖源激活，保留旧输入注入和真实拖放断言。共享工作区其他修改保留，提交前后可见文件哈希无变化；见[任务 v2](tasks/2026-10-29-floating-windows/v2.md)。

已解除普通dock面板、Diagnostics/Project Settings/GC/Outline的main viewport pin；SceneViewport独立scene目标尺寸与desktop映射，完整显示／拾取／跨窗Mesh与Material拖放／Gizmo／回嵌和布局读取。主最小化保留owned浮窗并跳隐藏Scene GPU；F1隐藏UI不因minimized复活。固定快照独立Debug无警告构建、完整Editor自测退出0，native GPU画面已检查，D3D11错误0；35原始工程／资产／Shader哈希不变。新产物build/floating-windows/Debug/RestArtEngine.exe，未覆盖bin、未提交。完整过程见[任务v1](tasks/2026-10-29-floating-windows/v1.md)，经验见[原生浮窗](experience/NativeFloatingWindows.md)。其他Persistence/Sandbox改动保留。

## 场景与资产保存职责分离（2026-10-29）

根据用户进一步要求，Save Scene／Save As 现在只写 Actor、变换和 GUID 引用，不写资产、不清除资产 dirty，也不扫描几何。编辑器按实际挂载范围只读文件索引检查依赖，未落盘／缺失引用提示先 Save Asset／Save All；已发布资产的内存修改保持独立。Apply 只标记对应材质，Save material asset 仅当前材质；New material 正常创建即发布，失败保留 dirty 可重试。Save All 负责应用草稿、增量保存资产与场景／配置；几何完整性验证移到实际资产写入之前。

最终 Debug 无警告构建、12/12 CTest、完整编辑器自测通过，D3D11 errors=0，覆盖两个材质独立 dirty、新建失败恢复、场景与资产互不写入、缺失依赖和 Save All 重载。构建／测试期间 93 源文件哈希稳定，Sandbox 14 文件未改，常用 bin 已更新。同期另一聊天的浮动窗口改动保留；其首轮最小化测试失败和后续更新后的完整通过分别留证。公开文档、经验已同步；未提交／推送。详见 [v5 记录](tasks/2026-10-29-save-scene/v5.md)。下段 v4 的几何验证缓存和保存调用行为为历史阶段，已由本段替代。

## Save Scene 无响应修复（2026-10-29）

已确认 Save Scene 会重写 Content 中未引用的约 326 MB R8：全量几何打包、逐坐标 JSON 包围盒操作、缩略图与同步写盘，World 还验证所有网格。现对已加载／发布且未变的网格复用持久化文件，修改／移动／缺失／迁移仍保存；场景只记录实际引用并按几何版本缓存验证。Save As 同步资产后写场景，Save All 去除重复材质保存。

Debug 无警告构建、11/11 CTest、六个内置网格逐字节重建、完整编辑器自测与新增 Save Scene／Save As／Save All／失败恢复／重载通过，D3D11 errors=0。R8 未引用的隔离保存从约 78～89 秒降到约 6 ms；引用首次约 235 ms、重复约 7 ms（函数计时，不含 UI／启动／GPU）。常用 bin Debug 程序已更新并哈希确认，用户 Sandbox 14 文件未变。文档、经验已同步；未提交／推送。完整过程和前期测试定位失败见 [任务记录](tasks/2026-10-29-save-scene/README.md)。首次或实际修改大网格仍同步，文件状态不是内容哈希，资产与场景尚无整体事务。

## 剩余开发改动分类提交（2026-10-29）

用户授权整理提交剩余改动，并明确保留 R8 测试模型及引用它的 Sandbox 改动在本地。本轮引擎提交：b7f77fe（公开轻量协作入口与同步 wrapper）、769f192（PBR／NPR 目标和 GPU 裁剪统计说明）、f6e3295（统一导入、六个 Engine 网格、材质拖放及配套测试／文档）。此前 2c84e99、d7d2fe6、933e2d7 的性能、统计、材质状态提交保留。引擎库剩余工作区仅为 Sandbox 用户资产和配置；未提交 R8 或任何协作正文／原始证据，未推送。

f6e3295 的实际暂存源码独立 Debug 无警告构建、9/9 CTest、完整编辑器自测通过，D3D11 errors=0；六个内置网格由工具重建逐字节一致，测试前后8个用户文件哈希不变。四步任务规范、经验、历史任务进度在协作库单独整理提交。完整本轮闭环见 [任务记录](tasks/2026-10-29-remaining-commits/README.md)；历史段落的“未提交”描述其当时状态，以本段和最新提交记录为准。

## 材质深度／剔除与千万面验收已提交（2026-10-29）

已提交 `933e2d73d9a5361c6b4754aea06a2b6ad28982e5`（feat(renderer): add material depth and cull controls with 10M DXR GI validation），26个公开源码／测试／技术文档文件，未推送。基于分别提交的性能缓存 `2c84e99` 和统计 `d7d2fe6`，仅加入本任务材质 Cull／ZTest／ZWrite、序列化与实时预览、光栅／射线／拾取契约、相机与阴影视锥剔除、硬件深度兼容恢复及千万三角形基准；排除导入、Engine mesh迁移、材质拖放、Sandbox资产与协作配置。工作文件未被候选覆盖，其他任务dirty保留，提交后暂存区为空。

证据 `artifacts/render-scale-commit/`：从HEAD按片段构造候选并独立导出；Debug构建和8/8 CTest、材质GPU专项、完整Editor、10,000,024三角形DXR＋RealtimeGI（66 dispatch、errors0）通过。期间统计任务提交后做三方合并，保留全部统计UI/接口，更新CPUfrustum开启input0／关闭input2断言与新材质截图raw-readback前缀；最终v2重新构建和完整Editor通过（31 geometry cases、errors0），已检查真实材质窗口截图。v1与v2渲染器实现相同；最终26文件blob与manifest-v2.json一致。提交阶段Debug规模样本median46.41ms/P95 47.0751ms，不替代先前Release测量，均非通用FPS承诺。候选、manifest、review-v2.patch、build-v2.log、cpu.log、material-state.log、editor-v2.log、scale.log保留，可复核提交边界与验证版本。

## 每次开发任务四步闭环（2026-10-29）

已统一分析原因 → 修改与验证 → v1/v2/后续版本日志 → 总结经验的流程；Codex 与 DeepSeek 共用入口，保持 RAEngine 根调用 skills／agents。完整规范见 [TaskWorkflow](TaskWorkflow.md)，经验入口见 [DevelopmentExperience](DevelopmentExperience.md)，本次实施与文档验证见 [任务记录](tasks/2026-10-29-task-workflow/README.md)。三个运行 skills 已 Collect 且全部 Synced；新增任务／经验目录在协作库仅放行 Markdown，引擎库继续整体忽略 local。未修改引擎实现，未提交／推送本轮规范改动。

## 面数统计已分类提交（2026-10-29）

已提交 d7d2fe65f9adf63a3958b5307e8f8840b1143f7f（feat(editor): show scene and post-clipping triangle statistics），仅13个公开源码／测试／技术文档路径，未推送。提交以当时HEAD 2c84e99为父，精确tree 2b2fd9d89071192c13656040eb23f6dfc6f1124e；将本任务增量从Material/Import/frustum/渲染缓存等工作区改动中剥离，用独立index和HEAD导出源码验证后提交。独立Debug构建通过，完整editor-self-test退出0、29 geometry cases全PASS、D3D11错误0，证据 artifacts/triangle-statistics/commit-validation/；对应产物 build/triangle-statistics-commit/Debug/RestArtEngine.exe。先前31case是混合其他任务CPUfrustum的集成证据，提交树本身只含GPU裁剪统计、不含CPUfrustum。提交过程77个已记录工作文件字节未变，真实暂存区已按这13路径同步，其他dirty保留。详细提交结果见 artifacts/triangle-statistics/commit-result.json。

## 千万三角形＋实时硬件 GI、材质深度与剔除（2026-10-29）

用户确认首轮规模验收要求视锥内至少一千万三角形，同时开启硬件光追和实时 GI，帧率先实测；culling 包含材质 Off／Front／Back 和相机视锥，不含遮挡剔除。已实现后端无关 MaterialCullMode／MaterialDepthTest，兼容 twoSided，新增 ZTest 九种模式与 ZWrite，现代/旧材质稳定字符串持久化和失败不污染；材质面板统一 Cull 组合框，参数、材质球与详情即时预览，Apply／Discard／Save契约保留。光栅六种镜像×Cull状态、深度状态缓存、解析／三角形／DXR普通和反向阴影面筛选、背面法线与CPU拾取同步。ZTest Never不截获拾取，其他特殊深度模式仍为几何最近拾取，不模拟最终绘制顺序。

主视图和各阴影级联按自身裁剪矩阵保守剔除完全在外的网格包围盒；SceneSettings.frustumCulling默认true，可供验证关闭。DXR保留相机外几何供阴影、反射和GI使用。硬件最近主命中仅兼容Less／LessEqual且ZWrite On；其他状态保留请求、effective inactive并给原因，恢复后更新GI history epoch。阴影贴图始终Less／Write On。本轮为DXR打包添加精确topology reserve，避免千万面时vector增长峰值。并行R8任务提供MeshGeometryKey、geometry cache、scene-input缓存和MeshQuery BVH；本轮在这些新接口上集成剔除和Cull Front，没有把其全部工作计成本轮独立修改。

独立 build/cmake-render-scale Debug／Release构建通过，9/9 CTest通过。新 --material-render-state-self-test 实际GPU验证九类用例，Cull硬件12 dispatch，视锥输入4→2且画面相同，相机后方donor在反射和GI分别影响2704像素，errors0。完整editor-self-test最终通过，包括真实Cull/ZTest/ZWrite交互、预览／Discard／Apply／保存、诊断统计和热编译失败保留；硬件专项206 dispatch、GI专项1181 dispatch均通过且errors0。首次编译碰到测试helper near/far与Windows宏冲突，已改名；首次editor测试新raw截图stem漏注册，补齐后通过；并行任务同步增加CPU剔除和GPU-only的统计对照，未放松可见像素验证。

--render-scale-test 使用2500×2000非退化独立地形网格（10,000,000tri，5,004,501vertices）加两彩色方块；1080p／Deferred／DXR＋Realtime GI／双贡献／1SPF／3次表面着色／32历史，场景所有bounds在视锥内。Debug和Release均确认主GPU input/postclip与DXR场景为10,000,024tri，33帧66真实dispatch，静态重复gather和mesh upload为0。Debug validation开启、errors0，首次build+frame10,259.0081ms，稳态24帧中位15.4586ms/P95 31.2473ms。Release首次3,273.4376ms，稳态均值15.5341ms／中位15.5152ms／P95 16.0087ms，DXGI进程local2,137,751,552B、nonlocal760,205,312B。测量从CPU提交至GPU同步完成，排除UI/Present/VSync，不是独立GPU执行时间或任意场景FPS承诺；Release不启debug layer，错误验证由Debug覆盖。AS仍是全场世界空间BLAS，运动／几何变更成本不外推为静态结果。

证据均在 artifacts/render-scale-depth-cull：material-state/、editor-final/、hardware/、gi/、scale-debug/、scale-release/及日志；已看过1080p场景和真实材质窗口截图。测试工程为ff65873原始Sandbox资产的隔离副本，未保存用户Sandbox。常用bin/windows-x86_64/Debug四个运行文件已与通过验证的Debug产物逐项哈希匹配并校验--help；原exe运行中无法覆盖，已将旧文件保留到before-runtime并安装新文件，未终止用户进程，重开后使用新版。源码快照与哈希见verified-sources.json。本轮未提交／推送，其他导入、统计、R8性能与用户资产修改保留，后续提交需按真实文件归属处理这些依赖。

## 场景与视口三角面数统计（2026-10-29）

Scene Overview、视口角落与Profiler已加入场景总三角数和主geometry GPU裁剪输出，按实例累计含隐藏；异步query排除shadow/outline/fullscreen/tool preview，纯硬件成图N/A，RealtimeGI有效，明确sample来源与Pending/Unavailable/NoViewport。固定源码快照Debug构建通过；delivery完整editor-self-test退出0，31项GPU统计case全PASS，D3D11错误0，实际截图已检查；23个原工程文件哈希不变，用户bin进程/资产保留。新产物build/triangle-statistics-verified/Debug/RestArtEngine.exe。实现、统计口径、并行构建交错与修正证据详见 [交付记录](TriangleStatistics-2026-10-29.md)；原始日志位于artifacts/triangle-statistics/delivery/。未提交，其他导入/材质/性能任务改动保持。

## R8 大网格运行与拾取性能优化（2026-10-29）

实际 Sandbox Audi R8 容器包含 3,877,264 三角形、11,631,792 顶点／索引，约 325.7 MB。本轮针对导入后持续卡顿：GPU 网格每个 Pass 重哈希约 311 MiB 数据；DXR 静态帧反复展开、变换和哈希约 562 MiB 临时数据；鼠标查询逐面变换／求交；包围盒与静态 Details 预览重复计算。保留用户模型、场景、材质和采样设置。

已实现 `MeshGeometryKey`／`markGeometryModified()`、版本化局部包围盒、GPU 几何缓存、软件光追／DXR 小输入签名（含 Transform、材质和 Cull／Depth 状态），仅实际变化时重建。静态 Mesh Details 按几何／Shader／默认材质／预览资源失效刷新。Assets 层新增平台无关 `MeshQueryCache`，局部空间射线查询真实三角形，保留单双面、镜像／非均匀缩放、最近命中语义；Morton 编码＋线性基数排序构建 BVH，256 MiB LRU，清理删除／替换资产。单个超预算网格可保留，预算不表示构建临时内存的峰值上限。原位或同长度内容赋值后须显式标记几何修改，公开 AssetFormat／RenderingDevelopment 已说明。

受控 Debug 实测（独立 R8 工程、`--no-ui`、排除前两帧）：光栅 Application Frame 平均 684.72 → 45.92 ms，Scene Submit 684.07 → 0.28 ms；原硬件光追＋GI 设置（16 spp／9 bounces）平均 5106.98 → 252.92 ms。数据为应用帧墙钟／CPU scope，含 GPU 等待，不是 GPU 独立时间或用户完整编辑器 FPS。优化前后 R8 光栅 BMP SHA256 一致且已查看。新增 `--trace-output` 自动导出主循环 Chrome Trace，公开 Diagnostics 说明测量边界。

最终 Morton BVH 实测：1808 checks 通过；包围盒首次计算 326.47 ms，首次求交含 BVH 构建 628.87 ms（前一版中位分割构建 9748.97 ms）；128 条预热射线平均 0.055 ms、平均 133.53 候选三角形，缓存 57,452,056 字节、仅构建一次。首次包围盒与 BVH 仍为同步成本；改变 Actor Transform／材质仍会重新展开全场 DXR 数据，按网格 BLAS／实例 TLAS 更新尚未实现。高采样／多反弹 GPU 成本仍存在，未暗中降低画质。

集成结束后再次测量：final-comparison.json 记录光栅 5.54 ms／硬件 48.09 ms；随后重新串行跑冻结旧程序和当前程序，recheck-comparison.json 记录光栅 855.98 → 4.69 ms、硬件 5812.68 → 11.09 ms。几次应用帧墙钟有明显波动，真实用户程序仍在运行，未隔离整机 GPU 负载，因此不据此换算承诺帧率或只宣传最好样本；首轮保守结果与全部原始 Trace 均保留。当前 Scene Submit 光栅约 0.18 ms，再次确认重扫几何开销消失。final-image 与 before-image／after-image 的 BMP SHA256 均为 `4F0BF00F20B0EFA23BFCB744FF117DFE6C95995C027A50D50C848743D60B7C96`，真实模型与隔离模型 SHA256 一致。

验证：当前 Debug 构建及 9/9 CTest 通过；硬件回归 206 次真实 dispatch、GI 回归 1181 次 dispatch，均 graphics errors=0，包含本轮新增的同缓冲同长度几何原位编辑／恢复像素测试。完整隔离编辑器回归通过，涵盖拾取、网格／材质拖放、变换、预览／提交／保存、Shader 热编译／失败恢复、布局和诊断，D3D11 errors=0。首次集成构建遇到并行新增测试的 Windows `near` 宏冲突，相关任务已改名后重建成功；集成验收补齐新增 Cull／Depth 测试的原始像素采集前缀，并将屏幕外几何统计检查区分 CPU 视锥剔除开启（GPU 输入 0）与关闭（GPU 输入 2，裁剪后 0），保留原始失败日志。证据根 `artifacts/r8-performance/`，包括 comparison.json、picking-final.log、cpu-final.log、hardware-final.log、gi-final.log、editor-complete.log／editor-complete、before/after-image。用户运行的旧 Premake 进程保持运行，新产物在 `build/cmake-sandbox-meshes/Debug/RestArtEngine.exe`；性能优化已提交为 `2c84e99`，未推送。

提交验收：`2c84e99`（`perf(engine): cache static mesh geometry and accelerate viewport picking`）仅含本轮性能优化、测试和公开技术文档，共 16 文件。以 HEAD 为基准按片段暂存，排除未提交的导入器、Engine 网格、材质 Cull／Depth、视锥剔除和三角面数统计；相关缓存键对新增材质状态的适配与集成测试修补仍保留在工作区，随对应功能后续提交。R8／Sandbox 用户资产未纳入。单独导出暂存候选与固定子模块源码，Debug 构建无警告、7/7 CTest、硬件光追 206 dispatch／errors=0；证据 `artifacts/r8-commit/{build.log,cpu.log,hardware.log,manifest.json}`。修正新拾取测试的 C++20 u8path 弃用警告，不改变测试行为。提交操作未覆盖当前完整工作区或用户运行程序。

## Blender FBX 退化面与可选导入配置（2026-10-29）

用户反馈 Blender 导出的 Audi FBX 被 `degenerate triangle after static mesh conversion` 拒绝，随后明确要求处理行为可选。已新增 `AssetImportOptions.skipDegenerateTriangles`，默认true；Content → Import options... → Skip degenerate triangles 复选框控制并保存到 `RestArtEngine.ui.ini` 的 `import_skip_degenerate_triangles=on/off`。选择文件／外部拖入共用设置。开启仅跳过存储float位置后cross恰为0的三角形，保留任意非零小面；关闭整源严格拒绝。全部退化仍失败，坏索引／非有限值／非法变换等原错误边界保持。保留三角形的零法线可用几何法线修复；成功的清理计数通过 MeshImportDiagnostics → AssetImportResult.warnings → 黄色结果提示流转。仅警告也会打开 Import results，仍为 Imported，不改 Actor／undo／scene dirty。

真实原文件只读验证：源SHA256 `68115239AAE4AB914EB9F19CE47E70F214710793CE0C51D2D8B648D627618BBD` 前后一致，保留3,877,264三角形（11,631,792 corners），跳过162退化三角形，修复8角点法线，最小保留cross长度3.01657723027e-18。严格模式正确拒绝且输出不变／诊断归零。完整统一服务生成325,707,485字节自包含rasset于隔离artifacts工程，材质与scene GUID保存重载通过；RTX5060／D3D11实际4帧绘制退出0，errors0。画面包含原文件所有可见Mesh，未声称与Blender材质／隐藏视图等价。

验证：CMake Debug和常用Premake Debug通过（后者0warning/error且已更新bin程序），7/7 CTest、导入专项157 checks通过；符号链接夹具因Windows创建权限SKIP。完整隔离editor-self-test退出0，实际鼠标点击Import options按钮／checkbox、检查保存后的偏好、严格false与跳过true原生文件投递、仅警告成功／两主题结果窗、既有编辑器与6种Engine网格拖放回归均通过，D3D11 errors0。首轮并行构建碰到PDB C1041锁冲突，串行重试通过，无源码回避。证据根 `artifacts/importing/blender-degenerate/`（parser-model-probe.log、model-service.log、model-render/、cpu-tests.log、editor.log及editor/、build-retry.log、premake.log）。公开Importing／EditorGuide和vendor说明已更新。本轮未提交／推送；真实源模型未修改，Sandbox工程未被本任务写入，期间另一任务的Engine Plane挂载／Sandbox引用修改保留。

额外只读核查：源场景89nodes／74meshes，全部mesh与祖先可见、无display layer。图中大圆筒对应可见源对象Cylinder.001（mesh Cylinder.002、4096triangles、原点半径约1m高2m）。Guide aktuell 1,323,008三角形与Audi aktuell 314,560三角形车身范围几乎重叠，可能解释表面闪烁，但未做Blender／逐面对应验证；未发现whole-node几何哈希完全重复组，未擅自过滤节点。证据parser-node-review.log。用户后续若要求按对象选择导入，可基于此继续，不能把当前默认所有mesh合并误称为只导入车体。

## 资产来源显示名称简化（2026-10-29）

按用户最终确认，浏览器来源名称由 `Engine Content` 改为 `Engine`，`Project Content` 改为 `Content`。来源树、根菜单、路径栏、`Show Engine` 开关及相关只读／来源提示同步；内部 `engine://` 键、资产 GUID、目录和读写权限保持原有语义。EditorGuide／GuiDevelopment 与原有 UI smoke 的文案断言同步。

本次提交限定名称调整：从 HEAD 构造文案差异暂存，保留工作区中的网格资产、Sandbox 迁移、导入和其他未提交开发改动。提交为 `dc3ceeb`（`fix(editor): rename asset sources to Engine and Content`），共 5 文件、24 行替换，未推送。验证使用独立 `build/cmake-sandbox-meshes`，当前工作区构建及完整 `--editor-self-test` 通过，D3D11 errors=0；已查看更新后的来源树与路径栏截图，证据在 `artifacts/content-source-labels/{build.log,editor.log,editor/content_grid.bmp}`。验证针对包含其他未提交功能的当前工作区，未另行构建纯提交快照；本提交本身仅替换显示文案和匹配断言。

## Sandbox 统一使用 Engine 网格（2026-10-29）

按用户要求将 Sandbox 默认场景的 Sphere／Cube／Ground 引用切换为 Engine Sphere／Cube／Plane，保留全部 Actor ID、变换、材质、名称与可见性。增加 `Content/Meshes/Plane.rasset`，固定 ID `0010000000000106`，几何与旧 Plane 一致（24×24，Y=0）；删除前逐一核对旧 Sphere／Plane／Cube 的几何及缩略图 blobs 与 Engine 文件字节一致，已删除 Sandbox `Content/Meshes/Builtin` 三个生成物及空目录。

SceneEditor 初始化不再调用 `ensureBuiltinMeshes`，默认新场景和 `+ Sphere`／`+ Cube` 均引用 Engine 资产；旧 1/2/3 仍作为内存兼容数据供旧场景使用，保存不附带未使用的旧图元引用。显式生成 helper 仅保留给兼容工具／测试，不参与普通启动。Content／拖拽 smoke 改为直接使用 `engine://Meshes`，没有为了旧测试恢复自动生成。

本轮 7/7 CTest 通过；第一次 Debug 引擎构建遇到 C1041 PDB 占用（日志保留），串行重试并设置本次编译进程 `/FS` 后成功，未修改全局环境或构建政策。随后共享构建目录再次发生 tlog 占用，最终改用独立 `build/cmake-sandbox-meshes` 构建成功，无警告。证据位于 `artifacts/sandbox-engine-meshes/{build.log,build-retry.log,build-final.log,build-isolated.log,cpu.log}`。

第一次编辑器 smoke 暴露两处仍按旧 Content 网格 ID 点击的测试，已迁移为 Engine GUID，并增加名称过滤确保行可见，没有恢复项目 Builtin 来迁就旧测试。最终完整隔离 `--editor-self-test` 退出 0，六种网格实际拖拽／Undo／Redo、新建 Engine Sphere／Cube、默认 Engine Sphere／Plane、保存重载与兼容测试通过，D3D11 errors=0。已查看 `editor-final/content_grid.bmp`，Engine Meshes 正确列出六种资产，项目侧无 Builtin；检查本机 Sandbox 目录也仍不存在 Builtin。Details 下拉隐藏未被 Actor 使用的旧兼容图元，并标明 Engine 来源。安装验证确认 Engine Plane 随包存在且 Sandbox 不携带 Builtin。证据为 `editor-final.log`／`editor-final/`／`install.log`。公开文档已同步六种 Engine Mesh 与不再生成 Builtin 的规则；没有提交／推送。

## 引擎内置 StaticMesh 资产（2026-10-29）

按用户要求提供 Cylinder、Cube、Cone、Sphere、Torus 五个正式 `.rasset`，位于引擎 `Content/Meshes`，含完整几何与 64px 缩略图。固定 ID `0010000000000101`～`0010000000000105`（依次 Cube、Sphere、Cylinder、Cone、Torus），可信挂载赋予 Engine 只读归属；旧项目 Sphere/Plane/Cube 的 1/2/3 不变。可从 Engine Content 拖入场景或 Add Actor，实例使用默认材质，支持原有材质拖放、变换、放置撤销／重做。

`loadEngineMeshes` 在启动与切换场景时挂载；项目加载拒绝占用保留 ID，项目保存和旧图元生成跳过引擎网格，场景只写实际使用的引擎网格引用。v1/v2 加载保留引擎挂载，v3 不复制几何。网格容器自包含，World 保存不再要求导入来源文件存在；导入网格 GUID 避开保留区。Cube/Sphere 复用精确解析标记，其他三种走通用三角网格路径，未引入新后端或 UV 格式。

资产重建工具为 `tools/GenerateEngineMeshes.cpp`（CMake 可选 `GenerateEngineMeshes` 目标，运行时不依赖）；CMake 安装整个 Content 与 Premake 的既有通配已覆盖五个文件。公开约定同步到 AssetFormat、EditorGuide、Architecture、EngineDistribution。

验证：CMake Debug 构建与 7/7 CTest 通过，CPU 验证五种闭合拓扑／法线／绕序、缩略图、保留 ID 冲突、损坏挂载回滚、保存排除和旧版本兼容。完整隔离 `--editor-self-test` 退出 0：五种资源通过实际 Content 卡片拖入、放置、Undo/Redo，逐一检查场景截图；D3D11 validation errors=0。证据在 `artifacts/engine-meshes/editor.log` 和 `editor/engine_mesh_drop_*_placed.bmp`。用户正在运行的 Premake 编辑器未关闭；使用 CMake 独立产物验证，常用 bin 下旧进程需重新构建／启动才能获得新挂载代码。本轮未提交、未推送。

最终复核：补充挂载 Engine 网格后直接 importObj 的 ID 分配与删源后重载回归；最终 Debug 重建和 7/7 CTest 通过（`build.log`／`cpu.log`）。CMake install 成功，安装包五个网格与源码资产 SHA256 逐一一致（`install.log`）。最后仅清理失效的顺序网格 ID 字段及只读／类型提示，未改变已通过的拖拽逻辑；GPU 全套运行与截图为此前同轮功能验证。

## 统一 Import 与 FBX 静态网格（2026-10-29）

按用户要求完成首版统一导入：Content 的 `Import...` 多选与外部文件投递共用 `Assets/AssetImport`，当前支持 OBJ／ASCII 与 binary FBX。导入到当前项目 Content 根／子目录，逐源独立校验、GUID、重名编号、临时文件与排他发布，只写新资源；未知格式、损坏内容、目录、越界／链接目标及只读 Engine 均明确拒绝，混合批次保留成功项并在 Import results 保留详情。导入本身不建 Actor、不改场景 dirty 或撤销记录。网格加载与保存按整个 Content 查找原 GUID 位置，Builtin 仍在 Meshes/Builtin。公开技术契约为 [Importing.md](../../docs/Importing.md)，接口为 AssetImport.h。

FBX 使用 vendored ufbx 0.23.1（固定 commit 与 MIT 许可），合并默认姿态静态节点，烘焙层级与 geometric transform、转换左手 Y-up 米制，处理缺失法线、非均匀缩放及镜像绕序；不加载外部依赖。不迁移 UV／材质／贴图／骨骼／动画，蒙皮仅保留默认控制几何。资源与输入边界见公开规范和 vendor/ufbx/README.rae.md。未来贴图扩展同一服务与两种入口，当前贴图仍拒绝。

本轮 CMake Debug、Premake Debug（0 warning/error）、安装及 ufbx license 分发检查通过；7/7 CTest 通过，导入专项 65 checks，符号链接夹具因 Windows 创建权限 SKIP。隔离 MSVC parser probe 覆盖真实 binary FBX、中文路径、双实例、Y/Z-up、层级／geometric／镜像／非均匀缩放，检查的 cross·normal 均为1，并验证坏索引／伪装OBJ／奇异／退化失败保持原输出。完整 `--editor-self-test` 在自动隔离 Sandbox 副本运行退出0：原生 WM_DROPFILES 注入验证 OBJ+FBX+不支持文件混合、重复名、Engine／区域外／重叠独立材质窗口拒绝、Actor／undo不变、删源重载与保存不重复，导入FBX立方体提交GPU并检查实际截图，两主题结果窗口已检查，D3D11 errors=0。证据为 `artifacts/importing/{build-accepted.log,premake-final.log,cpu-reviewed.log,editor-accepted.log,editor-accepted/,fbx-probe/,install.log}`。

过程修正保留在 `artifacts/agent-tasks/importing.md`：新smoke最初缺ImGui context、随后新建目录未刷新registry导致目标断言失败，均修正而非删断言；独立审查发现仅坐标会误接收覆盖Content的原生工具窗口投递，已传递并校验来源viewport ID并通过重叠用例。未进行物理鼠标拖拽或原生文件选择器自动操作，运行证据为同一平台消息／共享导入通路与截图。常用 `bin/windows-x86_64/Debug/RestArtEngine.exe` 已更新；本轮未提交、未推送。7个无关已修改路径包括Sandbox资产及ViewportInteraction字节SHA256保持；共享SceneEditor／EditorSmoke／文档的既有材质拖放与其他任务改动保留。协作16副本Status均Synced，没有改动skill/agent。

## Sandbox 红蓝涂漆与实时 GI 预设（2026-10-29）

用户已明确选择“改成红、蓝涂漆材质，优先呈现可见的互染效果”。已提交 `ff65873`（未推送），仅 4 路径：Red.rasset、Copper.rasset、Sandbox.raproject、GlobalIllumination.md。红色 RGB=(.75,.04,.04)，蓝色=(.04,.10,.75)，均 metallic=0、roughness=.4；保留 GUID 4/1、名称、grid、twoSided 及所有其他字段。现代容器覆盖同 GUID 的旧 .ramat，旧文件保留。Sandbox 默认请求 hardware=true、PathTracing/Realtime、两种间接贡献开启，4 SPF／512 历史／4 次表面着色；引擎通用默认值未改。

使用常用 Premake Debug、Windows／RTX 5060，在当前 Sandbox 的隔离副本分别验证“旧材质＋同样 GI”“涂漆＋GI”“涂漆＋两种间接贡献关闭”，各 144 帧、退出 0、D3D11 debug layer errors=0。实际截图显示 GI: Realtime，新材质有涂漆高光、相邻面可见偏色；关闭贡献后背光面变暗。证据位于 artifacts/gi-paint-tuning/ 的 variants、captures 与三份日志。该轮为资产／配置调整，复用既有引擎构建，没有新增 Shader／算法／增益或固定 FPS 承诺。

两个容器除 baseColor／metallic／roughness 外的 manifest、头部版本／flags 和 blob 尾部逐项核验一致；17 项无关工作文件 SHA256 保持，场景位置、金球、地面及其他任务改动保留。项目 index 使用独立 blob，仅提交新预设，保留工作树原排序和显式 reflection／shadow=true 偏好；其有效配置与实际 GPU 验证一致。独立范围审查及 cached diff --check 通过，提交后暂存区空。备份与基线见 artifacts/gi-paint-tuning/before/、baseline.json、changes.json。已打开的编辑器不监听磁盘材质修改，需要重新加载资产或重新打开 Sandbox；勿用旧内存资产覆盖。下节“尚未修改资产”为此前诊断阶段的历史状态，本节为当前交付。

## GI 颜色互染诊断与实际状态提示（2026-10-29）

用户反馈红球／蓝立方互染弱。本轮已核对实际优先加载的材质：蓝R=0、metallic .867、roughness .744；红G/B=0、metallic .313、roughness .638；saved项目GI method=disabled、hardware=true。保存状态不能证明截图会话的实际状态。独立Shader审查未见丢失bounce／PDF问题；当前BRDF使纯色异色diffuse为0，spec仍可传色，其强度受F0、粗糙度、几何与环境填充影响。保持物理输运，不增加gain或强制串色；原项目、场景、材质保留，涂漆外观选择尚未修改资产。

提交 9db4815（未推送），5个公开路径：SceneEditor只加入41行实际GI状态按钮／tooltip；ProjectSettings就近说明GI关闭或diffuse关闭时没有颜色溢出；HardwareSmoke验证真实980/1440宽度、状态导航、暂停／不可用和保存；GISmoke增加320×240彩色接收面双向donor因果对照；GlobalIllumination文档补材料吸收与UE官方PBR依据。工具栏可区分GI Off／Realtime／Progressive／Paused／Inactive，点击仅打开既有配置，不重写开关。

候选tree ce80dead6effc6a3bea20ba66336b17c911d12b3 独立raw blob导出178文件校验一致，CMake Debug、6组CTest、GI1181真实dispatch、硬件／UI204dispatch及完整编辑器回归全部通过，RTX5060图形错误0。painted接收面Progressive蓝→红.0121107／红→蓝.0115329，Realtime .0122527／.0115403（显示通道均值增量）；两贡献关闭的固定receiver差0，纯饱和异色diffuse增量严格0。原高metal参数独立参考测得spec可传色，无强制增强阈值。GPU mask经albedo/normal分割并侵蚀2px，排除5×5滤波边缘泄漏。图像、JSON、UI截图见 artifacts/gi-colour-transfer/candidate-gi/、candidate-hardware-rt/；工作区first/为早期复现。缺DXC的unavailable/明确SKIP真实硬件、dispatch0，保存和状态解释通过。常用Premake Debug已更新。

本轮仅提交上述5路径，原材质拖放／PBR-NPR／协作同步、19个无关基线文件及全部用户项目数据保持原始字节；暂存区空。初次候选导出遭遇Node默认buffer不足，改用直接fd输出，最终源码逐blob精确匹配；没有放松测试。原参数／保存配置的诊断快照为 artifacts/gi-colour-transfer/material-analysis.json。

### 实时 GI 与贡献控制已实现并提交（2026-10-29）

本轮沿用 PathTracing 算法，将算法选择、Progressive／Realtime 更新模式与间接 diffuse／specular 贡献独立配置。实时通道在光栅之前生成线性 HDR 间接光，由 Forward／Deferred 实际消费并与各自直接光及阴影合成；跳过原近似环境项和解析反射，避免重复计光。两个贡献开关分类相机接收面的 BRDF，次级路径保留完整光传输。共用 API 与项目 JSON 无 DirectX 依赖，具体生成仍仅 Windows 同适配器 DX11+DX12 DXR 1.1，未来算法可沿相同消费契约替换。

实时每帧持续采样，有界样本历史＋独立序列，在相机／物体／材质／光照／Shader／模式／贡献变化时全失效；5×5 几何和材质边缘感知空间滤波，近镜面不模糊，当前无运动重投影。内部FP32均值及引导，共享FP16间接输出，资源60B/px、4K约475MiB。初验FP32共享图像被DX11拒绝，改FP16并补齐对应能力检查，不能称所有设备支持或保证固定帧率。

工作区 CMake Debug、6组CTest、GI专项（含边界）781真实dispatch、硬件与配置真实UI145dispatch、完整编辑器回归已通过，RTX5060图形错误0；灰地面4577像素颜色传递0.01545，直接光墙色影响0，两条光栅路径GI差异>0.24，满历史后仍有2873像素变化。运动后图与显式reset同seed图严格相同，非零viewport偏移两路径逐像素一致；热编译失败保留活动管线及历史。配置截图已检查。证据位于 artifacts/gi-realtime/，最终交付21个路径：eb833a6仅修正旧编辑器测试从可见材质query选择夹具，8c9ae9d为14个GI功能／测试文件，dda510c为6份技术文档；未推送。另一任务的材质拖放、PBR/NPR、协作同步和Sandbox资产均排除，20个冻结工作文件提交前后SHA256一致，暂存区空。最终HEAD tree 414ca9808ad07db61d08f3ccfb2a78f9efcdba7c 与独立验证候选一致。

 开发状态与事实入口

最终原始blob独立导出178个文件逐一校验一致，Debug构建及6组CTest、完整编辑器、GI781dispatch、配置145dispatch、14帧Validate-Render全部通过，图形错误0；对应证据 raw-cpu.log、raw-editor/、raw-gi/、raw-hardware-rt/、raw-render/。无DXC隔离程序 unavailable/ 明确SKIP硬件执行、dispatch0，Realtime及贡献偏好保存重载通过。常用Premake Debug和DXC/DXIL已更新。隔离初验分别暴露旧隐藏.ramat测试夹具及Git archive换行转换：前者仅提交最小fixture修正，后者以cat-file原始blob解决，不降低源码或像素断言。当前无运动重投影／固定FPS承诺；Windows结果不外推其他平台。

## 渐进式 GI 已实现并提交（2026-10-29）

按用户授权完成并提交：`b79d9bc` 为硬件DXR基础、共用GI请求／状态、路径积分、HDR累积、项目配置与测试（23路径）；`4f16de6` 为公开引擎技术文档／白名单（9路径）。未推送。最终tree `e6f546fc44b5f2d6025da81877cb8c5c81c7041b` 与隔离验证候选一致，暂存区空。其他材质拖放／PBR-NPR规划、协作入口／同步工具和Sandbox资产改动未纳入；32个生产文件提交前后字节不变，未覆盖工作区。AGENTS及本地状态期间被其他任务更新，均保留。

已实现Disabled／PathTracing共用契约，Forward／Deferred均可组合DXR渐进路径。Lambert／GGX、多次表面反弹、方向光估计、环境逃逸和漫反射颜色传递；FP32线性HDR均值、严格样本目标、相机／材质／几何／光源／Shader／选项失效，曝光仅显示、debug暂停、工具预览隔离。配置页提供算法、每帧采样、目标、反弹、进度和重启，严格schema与原子保存。技术事实见引擎公开GlobalIllumination／HardwareRayTracing文档。

待提交源码排除其他任务后独立导出并干净构建通过；6组CPU、GI专项、硬件／GI配置交互、完整编辑器回归、14帧Validate-Render全通过，图形错误0。RTX5060 GI182次实际dispatch；灰地面4577像素直接光改墙色误差0、间接色差0.01544；1／16／64样本对256参考误差0.07238／0.01262／0.00557。镜面／粗糙反射及配置图已检查。证据 `artifacts/gi/commit-gi/`、`commit-ui/`、`commit-editor/`、`commit-render/`；总结 `artifacts/agent-tasks/global-illumination.md`。

常用Premake Debug及匹配DXC/DXIL已更新；干净CMake安装通过；缺失编译器分支明确SKIP并保留请求，不算硬件执行。干净配置发现并修正GNUInstallDirs晚于DXC install；隔离源码使用原始blob避免CRLF改变Shader源码字节断言。未实现降噪、透明／折射、发光材质、体积、其他实时GI或其他平台后端；无Release验证声明。下方此前阶段“未实现／未提交”以本节最终交付为准。

## 协作库公开规则（2026-10-29）

用户在首次私库推送完成后明确要求改为Public。README、同步/提交/位置规范、协作入口和Codex/补充模型阅读规范已统一改为独立协作库公开模式，原运行路径与双仓库隔离不变。历史“Private／私库”叙述是当时状态，以本节和当前RepositoryPolicy为准。现有协作库内容及历史将公开；凭据、机器设置、原始聊天数据库和外部媒体继续排除。本轮只更新规则与远端可见性，不推送引擎工作区其他改动。

## 私有工作区远端配置（2026-10-29）

用户指定 `CaptainRex0428/RestArtEngine_Workspace` 并授权配置与推送。已通过GitHub API核实该新空库原为Public，按用户的私有用途改为Private并复核；可见性切换期间Git一度返回repository disabled，随后重查已可正常访问。local的origin已绑定对应HTTPS地址，使用main分支。本轮首次提交范围仅私库34个清单文件，不包含引擎工作区的其他未提交代码；推送是否完成以远端main与本地HEAD核对为准，下方“未绑定／未提交”描述保留为初始化时历史。

README已补齐目录归属、原运行入口、新机安装、日常收集/安装、冲突与删除、Codex/补充模型共同读取规范及验证命令；同步规范改为真实远端。公开AGENTS及薄封装仍是引擎工作区独立的待提交改动，本轮不推送引擎库；新机文档提供直接从RAEngine根调用local/scripts的兼容方式。机器配置、同步状态、临时证据、缓存和正式媒体仍排除，当前16个skills/agents内容一致。

## 双 Git 协作资料同步（2026-10-29）

工程停止坚果云同步，`local/` 已初始化为独立私有 Git（main，无远端，尚未提交／推送）；公开引擎继续整体忽略 local、运行 skills 与角色。用户明确允许公开通用调用入口，因此根 AGENTS.md 改为轻量入口，完整原规则移至 local/docs/AgentEntry.md；公开 scripts/Sync-Workspace.ps1 只派发到私有同步工具。原 `.agents/skills/`、`.codex/agents/` 调用位置与名称保留，在 RAEngine 根继续使用。

私库 docs 直接维护，workspace 镜像显式清单中的16个skill/agent文件；Status/Collect/Install与WhatIf可用。基线哈希检测单侧、双侧、缺失和首次冲突，批次预检、写入复核、独占同步锁、原子单文件发布；不传播删除，不处理用户级provider配置，不自动执行Git网络操作。机器写作路径已迁移到私库也忽略的 machine/Paths.md；原外部文章未移动。Codex与DeepSeek共用AgentDevelopment、WorkspaceSync与ZhihuSeries §9.4，不另建模型专属进度。位置/提交规范与context/devlog技能引用已同步。

PowerShell 7与Windows PowerShell 5.1隔离测试各59项通过。公开入口额外验证：缺私库明确失败且不写文件，Install预演不创建运行文件，新工作区安装16文件哈希一致、公开AGENTS不变、父Git不列出私有路径、冲突错误码正确透传。当前16文件Status全部Synced，关键入口/技能相对链接可达，疑似凭据模式扫描无命中。测试证据 `local/maintenance/workspace-sync/entry-validation.txt`；临时测试目录只在本机。未构建引擎，本轮只改同步工具与规范。私库未配置GitHub remote，用户将创建空的Private仓库；绑定/首次提交/换机步骤见WorkspaceSync。

## 硬件光追画质反馈与约束调整（2026-10-29）

用户截图反馈红球与蓝方块缺少颜色联系，并确认硬件光追可放宽实时要求、优先真实光照。源码复核：当前是真实DXR求交，但间接漫反射只取程序化Environment，无场景漫反射GI／颜色溢出；反射为单理想方向＋粗糙度压权、仅一次命中着色，无随机采样／历史累积／降噪，等待不会收敛。此前48次dispatch／零错误／低粗糙高金属反射测试不能证明GI或粗糙反射物理正确。截图不能独立确认运行中的反射开关与草稿参数；饱和红蓝互相吸收亦需考虑，颜色溢出验收应包含白灰接收面。

已将硬件模式画质优先、可放宽最终画面逐帧完成但仍自动响应调参记录到公开渲染要求；当前缺口补充到HardwareRayTracing。渐进式路径追踪（漫反射／粗糙镜面采样、反弹、累积、历史失效、后续降噪）作为建议路线，尚未实施或承诺具体采样预算。本轮仅答疑、源码与Epic官方资料核对和需求文档更新，没有修改运行时代码、构建或GPU测试。UE官方区分实时硬件光追与Path Tracer；噪点不是硬件光追定义。

## 硬件光追与项目配置（2026-10-29）

已实现独立同适配器 DX12／DXR1.1 RayQuery 通道，与 DX11 编辑器通过共享 RGBA8 图像及双向 fence 组合。全部可见网格构建 GPU BLAS／TLAS，几何缓存、平滑法线、镜像／双面和只读材质草稿生效；工程材质、光照、曝光、Debug 共用源码。主可见性、一次反射和方向光硬阴影已实现；工具预览继续光栅，非完整 DX12 后端切换、非路径追踪，其他 OS/API 尚未实现。技术契约见公开 HardwareRayTracing 文档。

新增 Project → Project Settings... → Rendering 导航，移除顶部 Ray tracing 复选框，F3 打开配置。总开关／反射／阴影实时生效，能力／请求／实际状态分开显示；显式 Save project settings、Save All 和退出提示支持保存。可选 rendering 对象兼容 v1/v2/v3，严格 bool，原子更新保留未知字段与失败原文件。缺失 DXC 保留请求并显示原因。光栅专属导数材质在硬件关闭时仍可更新，硬件管线明确禁用，修复源码后恢复。

验证：CMake Debug、Premake Debug 构建通过并复制匹配 DXC/DXIL DLL；CTest 6/6（包含 ProjectSettingsTests）通过。`artifacts/hardware-rt/final-debug/` 专项实测 RTX5060，48 次真实 DXR dispatch，GPU 像素、效果开关、实时参数／草稿、几何／空场景、双面／镜像、resize／前后向、热编译失败回退、相对／嵌套include及真实 Project 配置交互保存重载全部通过，图形错误0。配置截图已检查。完整编辑器回归 `artifacts/hardware-rt/editor-verified/` 退出0、D3D11错误0；发现并修正既有材质拖放测试选中被新版资产隐藏的旧 .ramat，选择可见 .rasset，用户资产未改。缺失DXC的隔离程序验证 `artifacts/hardware-rt/unavailable/` 退出0，硬件执行明确SKIP、dispatch0、配置请求保存与回退通过；不冒充硬件执行。

安装包专项 `artifacts/hardware-rt/installed/` 同样通过48次DXR执行、错误0，验证分发的Shader与DXC/DXIL DLL。常用Premake Debug主程序已更新，显式执行 Validate-Render.ps1 于隔离工程，14帧图像比较全通过、D3D11错误0，证据 `artifacts/hardware-rt/raster-regression/`。没有Release或其他平台运行声明。

首次验证发现HLSL保留字triangle和共享图像缺少render-target标志，均修正。独立审查修正fence旧事件误唤醒及关闭硬件时不应限制已有光栅材质。FXC不支持宏形式include，最终验证使用共用语言支持的字面量相对／嵌套include，未扩展预处理语义。过程与原始失败保留在 `artifacts/agent-tasks/hardware-ray-tracing.md`。本轮未提交，既有Sandbox/材质拖放/PBR-NPR未提交工作保留；AI/进度/截图仍只在本地忽略目录。

## 诊断功能有序提交（2026-10-29）

按用户授权仅提交本聊天的 Diagnostics，依赖顺序为：`50964d8` Core CPU Trace与主循环插桩；`c9342be` GPU计时、冻结捕获与Shader诊断；`5c23e42` Debug菜单、Profiler/Frame Inspector和视口键盘归属；`3f497f3` GPU/编辑器诊断自测及隔离Project验证入口；`5a5a729` 公开技术文档与Diagnostics白名单。当前master为5a5a729，未推送。下文“未提交”保留交付时状态，以本节为准。

29个公开路径，索引最终tree `50cfd2ea7e004d3f43ddd7677572c89a98b0dc9a` 与隔离构建/运行的候选完全相同。共享文件按代码块排除材质拖放与PBR/NPR文档任务，未改工作区文件；提交前后35个修改/新文件原始字节SHA256全部一致。原Sandbox场景、4个未跟踪材质、材质拖放源码/测试/文档和PBR/NPR文档均继续留在工作区；暂存区空，本地AI/进度/截图/配置没有进入提交。

排除其他任务后的源码独立导出至 `artifacts/diagnostics/commit-source/`：Debug构建退出0无warning/error，5组CTest退出0，完整编辑器自测退出0且D3D11 debug layer enabled/errors0。诊断原值、各通道、捕获冻结、双主题/300px和快捷键隔离均通过。证据 `artifacts/diagnostics/commit-build.log`、`commit-cpu-tests.log`、`commit-editor.log`；候选、分组blob、提交patch与提交号在 `commit-preparation/`。69个公开文档文件链接检查通过，未收录其他任务的新增说明。用户bin进程未关闭或覆盖。

## 渲染长期目标确认（2026-10-29）

用户明确最终目标为 PBR 与 NPR 两套渲染体系，允许部分管线共用，同时保留 Feature 差异。已写入公开 RenderingDevelopment 的“双体系目标”，Architecture 与 README 只保留目标摘要和链接；后续渲染方案须据此评估共享基础、专属材质／Pass／Feature、依赖和禁用边界。PBR／NPR、Forward／Deferred 与图形 API 是不同选择维度；具体特性清单、材质格式、选择粒度及同场景混合能力仍待设计。

本轮只记录目标和架构约束，没有实现 NPR 或新增渲染开关，没有构建／GPU 测试。现有 PBR 着色基础和编辑器 outline 不作为完整双体系或 NPR 艺术描边的交付证据。本地进度继续忽略，公开文档不包含协作日志。

## 统一诊断工具首版（2026-10-28）

按用户确认的“方案加首版可用功能”完成 Profiler / Trace、Frame Inspector 和 Viewport Debug。统一技术契约与后续范围见公开 [Diagnostics.md](../../docs/Diagnostics.md)，任务/文件归属和原始证据见 `artifacts/agent-tasks/engine-diagnostics.md`。当前未提交。

Core 提供线程安全、有界嵌套 CPU Trace、Frame ID、120帧 wall time 历史和 Chrome JSON 导出；DX11 提供异步 GPU Pass 计时与原采样帧标识。Debug 工具窗可停靠/关闭，支持录制、停止、清空、原生另存为。Frame Inspector 捕获下一有效主场景的事件和独立 SceneColor/Depth，Deferred 增加三张真实 GBuffer；RGB/R/G/B/A转换、显式raw像素和仅元数据JSON导出可用。单套捕获与显示缓存限256MiB，候选/旧图安全退役会暂时额外占用。工具预览不消费捕获；resize、热编译、下一帧不改旧快照。

视口新增 Roughness、Metallic、Specular F0、Linear depth、Direct diffuse/specular；F0为材质模型派生反射率，不是新增Specular参数。数据视图不受曝光影响，直射贡献按现有显示变换输出。Apply补齐全部八个Shader候选发布，失败保留原活动版本。Diagnostics同帧焦点抑制视口F/W/E/R/Space及全局场景快捷键。

CMake Debug最终构建成功无警告；5组CTest全通过（TraceProfilerTests实际19项检查）；完整编辑器自测与Validate-Render退出0，D3D11 debug layer enabled、errors=0。GPU原值、25种资源/通道显示、双管线模式5–10、草稿实时反馈、冻结跨preview/resize/Shader成功失败、异步GPU身份通过；Record/Stop、raw读取、双主题、300px窄窗和场景/Undo不变通过，最终截图已人工复核。证据 `artifacts/diagnostics/final.log`、`final/diagnostics/diagnostics-report.json`、`render-validation.log`、`cpu-tests.log` 和 `build-final.log`。

测试使用HEAD导出的独立Sandbox与独立布局；27个预存工程/材质/Engine Content/材质Shader文件哈希不变，原Sandbox场景与4个未跟踪材质保留。初次测试模块构建的Windows near宏及ImVec2算术问题已修；前三轮GUI验证错误来自页签切换下一帧生效的测试假设，最终用稳定帧与文本日志定位修正，失败日志保留。原有材质投递等任务的工作区改动均保留，最终完整自测也覆盖其合并后路径。

仅Windows/DX11有运行证据；Trace JSON不含GPU计时，帧JSON不含图像或重放。离线完整帧、逐Draw输出/重放、Pixel History、Shader单步、AO/阴影/其他材质与成本诊断按文档后续设计推进。两个新增原生导出对话框未单独做桌面自动化，导出API及真实JSON已验证。Premake生成成功；当前用户仍运行bin的旧EXE，未关闭或覆盖，本次可执行产物为 `build/cmake-vs2022/Debug/RestArtEngine.exe`。

## Content 材质拖放赋予 Actor（2026-10-28）

已实现从 Content List/Tiles 拖动 Project/Engine 材质到 Scene Viewport：按最近可见三角面命中实例，悬停只用既有 outline 标识当前目标，保留 Actor 选择；目标提示独立于选中描边开关并保持颜色/粗细，结束恢复偏好。释放只改目标 Actor 的 materialId，单条 `Assign Material` Undo/Redo；同ID、Esc、空白、工具栏与视口外取消不产生历史。共享 Mesh/材质资产与其他实例不变，场景保存持久化引用。

本轮生产代码初次共享CMake Debug构建通过；后续工作区另一聊天并发加入诊断系统，未完成文件暂时阻断共享CMake生成，因此最终验证使用 `artifacts/material-drop/source/` 中的 `812c513 + 本任务源码` 独立快照。快照Debug构建成功，完整编辑器自测退出0、D3D11 errors=0；真实 Engine Grid/Project List、目标切换与GPU描边像素对照（关闭选中描边仍提示）、最近命中/实例隔离、保存重载、Undo/Redo/no-op与取消全部通过，原Mesh拖放/Alt复制/材质/布局回归通过。实际检查悬停与赋值截图。日志/截图 `artifacts/material-drop/run2/`，源码清单和构建隔离过程见 `artifacts/agent-tasks/material-drop.md`。

自测重复拖同卡片曾被固定帧时钟识别为双击，修复测试按ImGui实际双击窗口推进帧，并增加非双击断言，未改生产双击行为。保护清单65文件中 Projects、assets、Engine Content及用户4个未跟踪材质哈希不变；唯一变化为另一任务负责的 `Shaders/Private/Scene.hlsl`，本轮未写Shader。未关闭用户bin进程或覆盖bin产物。公开EditorGuide/GuiDevelopment/UndoTransactions同步；本轮未提交。独立快照通过不代表并发诊断系统的合并后构建已验收；弹窗/浮窗遮挡沿用接收区保护，未新增专项GUI投递用例；其他平台未测。

## 提交同步（2026-10-28）

用户授权后按依赖和领域完成4个提交：`25e1c0b` 渲染预览隔离与材质ID修复；`9d0f194` Engine Content、资产加载/保存/复制与CPU测试；`960c1e9` Content交互、拖入场景、类型颜色、默认开启的负轴提示配置与编辑器回归；`812c513` 公开技术文档同步。当前HEAD为812c513，未推送。提交仅收录31个公开路径，原Sandbox Default.rascene修改及4个未跟踪材质均未提交且哈希不变；本地AI/进度/日志/截图未进入提交。下面“未提交”是实现交付时状态，以本节提交记录为准。源码未在提交环节改变，沿用verified2完整自测、两套CPU测试和Debug构建证据。

## Engine Content 与默认材质（2026-10-28）

已实现引擎根 `Content/Materials/DefaultMaterial.rasset`（中性灰、固定ID、64px缩略图），与Project Content分源挂载。新Actor默认引用引擎材质；New material继承默认参数生成项目GUID；旧Actor/项目材质保留。engine://浏览键支持来源导航/搜索/Details/只读提示，Copy to Project只保存单个新资产并选择副本，不自动改Actor引用。运行时来源由loader赋予，保留ID冲突拒绝；项目save排除engine，reload保留engine，v1/v2/v3场景兼容。GPU工具预览对clean/只读材质也持续存在；scene draft override语义保持不变。

CMake Debug、EngineContentTests 59项和ContentBrowserTests通过；CMake安装后的Engine Content再次通过59项测试，Premake生成成功。最终完整编辑器自测退出0，D3D11 errors=0，新增真实只读/复制/保存操作、旧Content拖场景/撤销/Alt复制/材质/布局回归通过，截图检查完成。证据与中间失败处理见 `artifacts/agent-tasks/engine-content.md`，最终日志/截图为 `artifacts/engine-content/verified2/`。64个既有Projects/Shaders/assets文件前后哈希不变，原未提交工程和4个材质保留。

最终Premake Debug常用bin主程序也已构建成功、无警告，日志 `artifacts/engine-content/premake-build.log`；CMake install刷新为最终构建。

公开技术说明同步Architecture/AssetFormat/EditorGuide/GuiDevelopment/EngineDistribution/README；根Content是可公开发行资产，位置规范已同步RepositoryPolicy/LocalDevelopmentGuide，AI/日志/截图依旧本地忽略。首期只分发默认材质；内置网格仍走项目生成兼容路径。没有宣称引擎mesh/纹理/插件挂载、Release或其他平台已验证。本轮未提交。

## Content Mesh 拖入场景（2026-10-28）

按用户澄清实现从 Content 将物体拖入场景，未扩展目录迁移或新的物体移动方式。List/Tiles 共用现有路径payload，视口接收本帧图像区域（排除工具栏、遮挡窗口和弹窗）；拖动显示包围盒与接触点，最近可见三角面/未命中时Y=0地面，bounds支持偏移；释放创建一个Actor、选中Details、一条Place Mesh撤销/重做。Esc统一清payload并抑制source至释放；无效资产/落点给提示，拖动不抢相机/Gizmo/pick。场景选中描边borrowed span改在全部选择编辑之后绑定，避免新选择扩容失效。

最终 Debug 构建退出0、无编译警告；两轮完整编辑器自测均退出0，新增真实Grid/List投递、表面/地面高度、释放前不创建、Details、Undo/Redo、Esc/outside/toolbar/Material拒绝及camera输入隔离通过，原Gizmo/Alt复制/材质/布局回归通过，D3D11验证错误0。最终实际截图已检查预览包围盒/落点/提示与放置选中效果，证据 artifacts/content-scene-drag/final/smoke.log 和同目录 PNG；测试跑在HEAD导出的独立工程副本（自测再次临时复制）、独立布局目录，21个原始工程/Shader文件哈希前后相同。导入偏心mesh、倾斜/负scale投递表面、浮窗遮挡/popup尚未单独新增拖放用例，不外推为逐项运行验证。

本轮未关闭用户进程或覆盖bin产物；新产物为build/cmake-vs2022/Debug/RestArtEngine.exe。公开EditorGuide/GuiDevelopment/UndoTransactions同步；已有其他任务未提交改动及4个未跟踪材质容器均保留，本轮未提交。任务归属和初始差异备份见 artifacts/agent-tasks/content-scene-drag.md。

## Gizmo 负方向提示可配置（2026-10-28）

按用户后续要求，将上一节的固定关闭改为 UiPreferences.gizmoNegativeAxisHints，按用户最新要求默认 true。UI 菜单新增 Gizmo negative-axis hints 勾选项，即时切换并写入 RestArtEngine.ui.ini 的 gizmo_negative_axis_hints=on/off；旧文件缺项默认开启，已有显式开关选择保留。移动／缩放仍使用 ImGuizmo 的轴向和命中逻辑，开启采用原生 6px 条纹，关闭为 0。

独立 Debug 构建已通过，证据目录 artifacts/gizmo-axis-preference/。自测已覆盖旧配置默认值、开／关保存读取及开关实际改变 Gizmo 图像；完整编辑器自测退出 0，移动／旋转／缩放／Alt 复制和撤销回归通过，D3D11 验证错误 0。实际截图确认 UI 菜单入口可见。继续保留用户运行中的 bin EXE，测试使用独立输出、工作目录和临时 Sandbox 副本。公开 GUI／操作／架构说明同步，不提交本地偏好或证据。

## Gizmo 负向轴条纹关闭（2026-10-28）

用户截图中的红黑虚线来自 ImGuizmo 的 DrawHatchedAxis：坐标轴自动翻向负方向时叠加黑色线段。引擎 ViewportInteraction 在绘制前设置 HatchedAxisLineThickness=0，移动／缩放轴改为连续实线，保留翻转和变换逻辑，vendor 未改。GUI 规范已同步。

当前交互引擎进程占用 bin 下的 Debug EXE，常规链接报 LNK1104；保留用户进程，用 MSBuild OutDir 构建到 artifacts/gizmo-solid-axes/runtime，构建退出 0。自测使用隔离 Sandbox 夹具和独立工作目录，证据在 artifacts/gizmo-solid-axes/debug；反向观察截图已确认无条纹，完整编辑器自测退出 0，移动／旋转／缩放／Alt 复制与撤销回归通过，D3D11 验证错误 0。原 bin EXE 未更新，用户关闭后重新构建启动生效。

## Content 类型色（2026-10-28）

本轮在上一轮 Content 优化基础上增加类型色：Mesh 蓝 `#50B2EB`、Material 绿 `#64CD85`、Scene 琥珀 `#EEAF4F`、Shader 紫 `#B891EF`，Unknown 灰。统一入口为 `src/ImGui/EditorTheme.cpp` 的 `assetTypeColor`；卡片底条、列表左标、类型文字、筛选项和无预览图标共用映射。实际缩略图、材质数据和主题选中反馈保持原语义；未增加逐资产颜色编辑器。

Debug 构建通过；最终完整编辑器自测退出 0，D3D11 错误 0。实际复核 Black／Dark Blue 四类型同屏卡片、列表与场景详情；最终证据见 `artifacts/content-asset-colors/final/smoke.log`。测试使用独立 HEAD Sandbox 夹具、独立工作目录和临时工程，夹具额外添加 Shader 显示样本；Projects／Shaders 27 文件哈希不变。GUI 规范与 EditorGuide 已同步。截图、进度仅本地，源码未提交。

## 当前接续：Content 浏览器优化已实现并验证（2026-10-28）

基于 `daa8859` 的工作区改动，未提交。详细行为、证据和剩余范围见 [Content 交付记录](ContentBrowser-2026-10-28.md)。已完成 UE 式 Sources／导航／搜索／筛选／Asset View、响应式卡片与列表、焦点隔离、递归资产加载和 GUID 文件路径保留、v3 初始化顺序、任意材质 ID 与独立预览纹理。

Debug 构建、CPU 65 项检查、最终完整编辑器自测通过，D3D11 验证错误 0；实际检查双主题、低高度与 440px 浮窗截图。Projects／Shaders 27 文件前后哈希一致，4 个预存未跟踪材质保留。符号链接测试因系统权限跳过；Release／其他平台未测。

P02-01～04 已有对应实现与定向运行证据；P02-07/08/09部分改善，详见交付记录。下一优先项仍为描边 Shader 热更新发布、Save As 资产闭环、普通保存刷新 sidecar；本轮没有扩展为完整 UE 资产管理器。公开说明、本地进度和 GUI 技能已同步，AI／日志材料继续仅本地。

## 当前接续：DevLog02 标签后完整审计（2026-10-28）

基线 `DevLog02(cc68a1b)..daa8859`，49个提交（不是下面资产子阶段的18个）。完整逐提交表、源码结论、经验和待办见 [标签后工程审计](DevelopmentChanges-AfterDevLog02.md)。截至本轮起始HEAD与origin/master一致；四个未跟踪Sandbox材质容器保留。本轮仅同步文档/技能，没有重建或运行引擎。

已实现：选中描边与G/H、Scene/Details职责调整与眼睛撤销、双窗口启动、Premake运行配置、Content文件夹/List/Grid/资产详情、GUID `.rasset`/场景v3、CPU缩略图与GPU工具预览、自测临时工程隔离。

优先待办为审计表P02-01～05：非1号材质球预览、同帧多窗口纹理生命周期、v3导入网格首次启动、材质子目录加载、描边Shader热更新发布。P02-06～13覆盖Save As资产落盘、sidecar刷新、取景限幅、测试盲区、隔离边界、原子保存、Rider/画面验收和旧样例问题。源码明确的缺口与尚待运行复现的风险已分开；未在本轮实现修复。

历史PASS叙述不升级为本轮运行结果；现存临时截图只能证明对应画面。13个示例JSON本轮解析仍有RayTracing_Simple五个材质失败。检查结果见 `local/maintenance/devlog02-catchup/checks.json`。下文按日期保留历史状态，若与本节和新审计冲突，以新审计为当前口径。

补充模型使用共同的本地进度/经验/技能体系，未发现独立项目内文档目录；不读取服务配置。DevLog03尚未开始，DevLog02的发布日期/链接与播放验收仍待回填。公开技术文档同步行为，本地规范、经验、任务管理和写作资料继续忽略。

## 文档 / 技能同步审计（2026-10-28）

原资产子阶段审计范围：包含两端的 `d3ea6d2^..98af7ea`，18个提交；它不是DevLog02标签后完整范围。完整49提交审计见页首，原记录中的完成与验证结论按当时取样保留。

**已修正的过期事实**

- `docs/AssetFormat.md` 从“设计提案、尚未实现”重写为已实现状态：容器/GUID/材质与网格资产/内置图元/缩略图/场景 v3/旧格式兼容；清单示例改为真实字段（16 位十六进制 GUID、`rgba8` 缩略图）；场景 v3 示例区分“JSON 数值 ID”与“容器十六进制”；新增 `<scene>.rthumb` sidecar 格式；迁移步骤与未决项按实际实现重排（纹理、压缩、原子保存仍未做）。
- `docs/Architecture.md`：场景持久化改为 v3 GUID 引用 + v1/v2 兼容；材质改为 `.rasset` 容器并说明旧 `.ramat` 不删除；资产目录树、AssetRegistry 缓存字段与场景 sidecar 缩略图同步；删除“统一资产格式尚未实现”。
- `docs/GuiDevelopment.md`：面板职责补 Content 浏览器与 `Asset Details`；新增“资产浏览与详情窗口”和“证据边界”两节，记录网格单元格尺寸、`Selectable` 忽略高度、独立 OS 窗口不能进自测截图等经验；测试要求补充临时工程副本。
- `docs/EditorGuide.md`：Content 面板说明、场景缩略图来源、材质保存路径（`.rasset`，旧 `.ramat` 保留）、资产浏览能力边界同步。
- `README.md`：示例工程目录树、材质保存磁盘列、文档索引（补 `AssetFormat.md`）。

**技能同步（可复用经验，不复制进度快照）**

- `restarengine-gui`：资产浏览器与详情窗口规则（网格尺寸、双击语义、`Open` 与 `Details...` 区分）；证据边界（独立窗口截图、测试不得写用户工程）。
- `restarengine-rendering`：离屏工具预览约定：必须 `offscreenTarget=true`（只关 `editorViewport` 会画到交换链）、预览借用场景目标角落再复制、用 staging 回读验证。
- `restarengine-delivery`：测试必须在临时工程副本上跑、夹具每轮清理、MSBuild 串行避免 tlog 锁；兼容路径示例（`.rasset` 不删 `.ramat`）。
- `restarengine-core`：阶段收尾同时同步领域文档、进度索引和可复用技能经验。

**实现修正**

- `--editor-self-test` 现在把工程复制到 `%TEMP%/RAEngineSelfTest-<pid>` 再运行，退出时删除；验证 Sandbox `Content/**` 的 SHA256 前后一致、无残留临时目录。此前自测会对用户工程执行 `Save All`，是 `.ramat` 被转换/删除事故的根因。

**仍未完成 / 待决**

- 纹理载荷、数据块压缩、保存原子替换（当前直接覆盖写）、`--dump-asset` 调试工具。
- DevLog03 尚未开始；本阶段素材与证据尚未整理成文章。
- `Projects/Sandbox/Content/Materials/*.rasset` 是事故遗留的未跟踪文件，是否并入工程需用户决定。


## 网格视图显示资产名（2026-10-27，提交 f86b357）

用户反馈网格缩略图下方应显示名字。

- 网格单元格文字用 `ImDrawList::AddText` + 裁剪矩形绘制在缩略图下方，居中，超宽截断并保留完整名 tooltip。
- 单元格尺寸改为 `clamp(内容区高度 - 8, 64, 96)`：内容面板较矮时缩小格子，避免名字被面板底边裁掉（之前 96px 固定导致文字落在裁剪区外）。
- 顺带修测试：`SceneV2RoundTrip` 临时目录每轮开始先 `remove_all`，避免上一轮遗留的旧 `.raasset` 让 `ensureBuiltinMeshes` 跳过生成 `.rasset`，导致 Release 下 `copy_file` 找不到文件。

验证：Debug/Release 自测通过，截图确认 Cube / Plane / Sphere 名称居中显示在缩略图下方。


## 可交互材质球 + GPU 场景缩略图（2026-10-27，提交 2062c35）

- 材质预览支持轨道相机：`renderMaterialPreview(material, size, yaw, pitch, distance, error)`，旧三参数签名保留为默认视角包装。编辑器里 160px 预览改成 `InvisibleButton` + 拖拽/滚轮/双击；左键拖拽改 yaw/pitch（pitch 限制 ±1.4）、滚轮改距离（1.6–8）、双击复位；相机变化立即重渲，其余仍走 150ms 节流。
- 场景缩略图改为 GPU 真实渲染：`renderScenePreview(world, assets, size)` 用可见 Actor 顶点的世界包围盒自动取景（中心 + 半径 ×2.6），走同一个离屏预览目标；保存场景时渲染 128px 并写 `<scene>.rthumb`（magic `RTHB` + 版本 + 宽高 + RGBA），路径已加入 .gitignore。
- Content 浏览器对 `.rscene` 优先读 sidecar，缺失时回退到 Actor 布局的 CPU 缩略图；这样没保存过的场景仍有预览。
- 抽出 `renderPreviewFrame`（建立/复用预览纹理 + 渲染 + region 拷贝）供材质与场景复用。
- 修复 `readSceneThumbnail` 先 `valid()` 后 `resize` 的顺序错误（64×64 却判为非法尺寸）。
- 测试：旋转相机后预览像素不同；场景预览亮像素 > 100；sidecar 写入/读回一致。

验证：Debug/Release 0 warning，两配置自测通过。


## GPU 离屏材质球预览（2026-10-27，提交 0f8cdac / fdc49b5）

用户三项中的第三项完成。

- `SceneSettings` 新增 `offscreenTarget`：把绘制定向到场景目标而不是交换链，同时保留 `editorViewport=false`（不跑 outline、不切回背缓冲）。之前只改 `editorViewport=false` 会画到交换链，`sceneTarget` 只剩清屏色，读回才会是 (6,9,14)。
- `SceneRenderer::renderMaterialPreview(material, size, error)`：复用一个单球 Actor 的临时场景 + `defaultAssets` 副本，固定相机（yaw 0.65 / pitch 0.18 / distance 3）、Forward、关闭光追与阴影，渲染 64–160px 后把 region 复制到独立 `previewTexture`。
- `readMaterialPreviewPixels`：staging 纹理回读，供测试断言颜色。
- 材质编辑器顶部显示 160px 预览，参数变化立即重渲、否则每 150ms 一次，避免每帧渲染。
- 测试：红/绿草稿球体中心像素分别以红、绿为主，证明预览确实使用草稿参数；Debug/Release 0 warning，D3D11 校验错误 0。

已知限制：材质编辑器是独立 OS 窗口，`--editor-self-test` 的主窗口截图不包含它，所以证据用像素回读而不是截图；预览借用场景目标的一个角落，主渲染随后覆盖，属于一次 64–160px 的额外小渲染。


## Content 网格视图 + 场景缩略图（2026-10-27）

两项已落地，第三项（GPU 材质球预览）单独下一轮。

- 网格视图：Content 工具栏新增 `List` / `Grid`；网格用 84px 单元格，手动定位（`Selectable` 会忽略高度参数，不能依赖 ImGui 光标推进），显示放大缩略图、悬停显示名称，支持拖拽、右键菜单、双击打开。
- 场景缩略图：`.rscene` 是 JSON，不存图片；`AssetRegistry` 扫描时按 Actor 的 position/scale/meshId 生成 4 色方块布局图（固定 35° 偏航、画家排序），无需 GPU 也无需额外文件。`renderSceneThumbnail` 放在 `AssetThumbnail`，输入是 `ScenePreviewBox` 列表，不依赖 Scene 模块。
- 测试：Content 网格截图、Scenes 文件夹网格截图、`Scenes/Default.rscene` 注册表条目缩略图有效。
- 已知不足：场景缩略图是方块示意而非真实渲染；网格单元格没有内嵌名称（悬停才显示），因为子面板高度不足时文字被裁切。


## 资产后缀改为 .rasset（2026-10-27，提交 ecace7c）

用户觉得 `.raasset` 重复，统一改成 `.rasset`。

- 全仓库替换扩展名字面量与文档；新增 `isAssetContainerFile()`（`kAssetExtension = ".rasset"`、`kLegacyAssetExtension = ".raasset"`），所有加载入口用它判断，因此旧的 `.raasset` 文件仍可只读加载；保存一律写 `.rasset`。
- 本地生成的 `Content/Meshes/Builtin/*.raasset` 清掉后重新生成为 `.rasset`（生成物、gitignore 目录）。
- 测试新增一条：把 `Cube.rasset` 复制成 `Cube.raasset`，`loadMeshes` 仍能读入并覆盖内置网格；其余路径字面量同步更新。

验证：Debug/Release 0 warning，两配置自测通过。


## 资产缩略图（2026-10-27，提交 4e86dd3）

用户要求的第二步：给 `.raasset` 加缩略图并在 Content 面板显示。

- `assets::renderMeshThumbnail` / `renderMaterialThumbnail`：CPU 光栅化 64×64 rgba8，不依赖 GPU/编码器。网格按**最大两个轴向**正交投影（解决地面 Plane 投影成一条线的问题），带 z-buffer 与 lambert；材质是着色球（roughness/metallic 参与高光）。
- 容器：`attachThumbnail` 把像素追加到数据块区并在清单写 `thumbnail{offset,size,width,height,format}`；`extractThumbnail` 校验范围；`readAssetThumbnail` 只按偏移流式读取缩略图，不加载几何。
- 保存：材质与网格写盘时自动附带缩略图；内置图元若文件缺 `thumbnail` 会被 `ensureBuiltinMeshes` 重写补上（旧文件自动升级）。
- 浏览器：`AssetRegistry` 扫描时读缩略图，`drawAssetRows` 用像素块直接绘制（约 20px），缺缩略图回退线框图标；新增 `selectContentFolder` 便于测试与面包屑。
- 测试：材质/网格缩略图非空且尺寸正确、容器往返像素一致、磁盘文件可读缩略图、注册表对生成的 Builtin 网格能取到缩略图；截图确认 Cube/Plane/Sphere 三种预览形状正确。

验证：Debug/Release 0 warning，两配置自测多次通过（期间出现过已知的材质窗口/像素对比时序抖动，重跑即过）。


## 内置图元生成 .raasset（2026-10-27，提交 40c9b2a）

用户要求的第一步：内置图元也生成 raasset；第二步缩略图留待下一轮。

- `AssetLibrary::ensureBuiltinMeshes(folder, error)`：把非 `Imported` 的网格写成 `<名称>.raasset`，已存在同 id 文件则跳过；`loadMeshes` 遇到与内置同 id 的文件时用文件覆盖内置几何（导入网格重复 id 仍报错）。
- 编辑器打开工程时生成到 `Content/Meshes/Builtin/`（`Sphere/Plane/Cube.raasset`），并把 `loadMeshes` 改为递归扫描；该目录是生成物，已加入 `.gitignore`。
- 实测生成结果：Sphere 297 KB、Plane 704 B、Cube 1.3 KB；Content 浏览器里显示为 `Meshes/Builtin` 文件夹下的三个网格资产。
- 测试：生成后文件数为 3、重复调用不产生重复文件、重新加载后内置网格顶点/索引数与程序生成一致。

验证：Debug/Release 0 warning，两配置自测全绿。


## 启动器窗口居中（2026-10-27，提交 a678dba）

用户要求 launcher 保持原来的相对大小、在主屏正中间打开。

- `runProjectManager` 原来用 `CW_USEDEFAULT` 创建 1080×720 窗口；改为 `primaryMonitorRect()` + `centredWindowRect(monitor, 1080, 720, false)`，尺寸不变只改位置。
- 实测（2560×1440）：窗口 `1080×720`、左上角 `(740,360)`，即 `(2560-1080)/2`、`(1440-720)/2`，标题 `RestArtEngine | Project Manager`。
- 文档 `docs/ProjectManagement.md` 补充居中规则。

验证：Debug/Release 0 warning，Release 自测通过。


## 网格资产化 + 场景 v3（2026-10-27，提交 9843248）

用户确认继续后完成：网格也进入 `.raasset`，场景只留 GUID 引用。

- 容器新增 `staticMesh`：清单存 primitive/vertexCount/indexCount/stride/indexFormat/bounds/blobs 偏移，数据块存 `MeshVertex` 顶点与 u32 索引；`makeMeshAssetFile` / `readMeshAssetFile` 负责往返，读取时校验 blob 范围与元素数。
- `AssetLibrary::saveMeshes` / `loadMeshes`：只把 `Imported` 网格写盘，内置图元保持程序生成；按名称写 `<name>.raasset`，保存时删除同 GUID 的旧文件；加载保留内置并追加文件网格。
- `World` 场景格式升到 **v3**：`materials`/`meshes` 都只写 `{"id":guid}`；v3 加载要求库中已解析全部 GUID，缺失时报「Scene references mesh N that is not loaded from Content/Meshes」；v1（内嵌快照）与 v2（材质引用 + 内嵌网格描述）继续可读。
- 编辑器：`initialize`/`openScene` 先加载 `Content/Materials` 与 `Content/Meshes` 再读场景；`saveScene` 依次落盘材质、网格、场景；`importMesh` 现在解析 OBJ 后生成 GUID 并写 `Content/Meshes/*.raasset`，不再复制 `.obj`；Content 里双击网格会选中它供 `Add Actor from mesh`。
- 测试：网格容器往返（3 顶点/3 索引）、v3 场景磁盘往返（材质 + 网格解析）、缺网格引用必须失败；既有 v1/v2 兼容用例保持通过。

验证：Debug/Release 0 warning，两配置自测全绿；`Projects/Sandbox` 未改动。


## 场景 v2：材质改为 GUID 引用（2026-10-27，提交 368fbca / 5ca9841）

用户确认「没问题」后继续：场景不再内嵌材质快照，只保存材质 GUID 引用。

- `World::save` 写 `version: 2`，`materials` 数组每项只有 `{"id": guid}`；网格描述暂保持内嵌（下一步迁 `.raasset`）。
- `World::load` 同时接受 v1/v2：v1 走旧的内嵌快照（替换材质库），v2 用传入的库解析引用、缺失 GUID 明确报错「Scene references material N that is not loaded from Content/Materials」，成功时只替换网格、保留材质库。
- 新增 `World::createDefaultScene(const AssetLibrary&)`：默认场景按库里材质名（Copper/Ground，缺省取第一个）生成引用，避免写死 1/2。
- 编辑器 `initialize`：先 `loadMaterials(Content/Materials)` 再加载场景，然后重建 `AssetRegistry`；`saveScene` 先落盘材质再写场景，保证引用可解析；`createScene` 用库建默认场景。
- 测试：v2 场景磁盘往返（材质文件→GUID 引用→重新加载）、缺材质时必须失败、编辑器用临时工程初始化 v2 场景（演员数量与注册表材质数）。
- 过程中修正：`initialize` 一度被整段替换时丢掉了注册表扫描，已恢复。

验证：Debug/Release 0 warning，两配置自测全绿；仓库内 `Projects/Sandbox` 未改动（测试全部在临时目录）。


## GUID 身份 + `.raasset` 容器（材质先落地，2026-10-27，提交 fcbabd8）

用户决定：先用 GUID，UE 的路径身份以后再说；材质并入 `.raasset`。

- `assets::AssetFile`（`include/.../AssetFile.h`、`src/Assets/AssetFile.cpp`）：`RAAS` magic、版本、flags、manifest 长度、JSON 清单、数据块区；`readAssetFileHeader` 只读头与清单，`readAssetFile` 连数据块一起读，`writeAssetFile` 写临时布局并把 format/version/type/id/name 写进清单。校验：magic、版本范围、清单长度上限、截断、JSON 格式、GUID 十六进制。
- GUID：`generateAssetId()` 64 位随机（0 保留），`assetIdText()` 16 位十六进制，`parseAssetId()` 反向解析；内存仍是 `AssetId = uint64`。
- 材质持久化改为 `.raasset`：`AssetLibrary::saveMaterials` 写 `<名称>.raasset`（名称过滤非法字符），并删除同 GUID 的旧文件（改名后不留重复）；`loadMaterials` 优先读 `.raasset`，再兼容只读 `.ramat`（同 GUID 已被容器占用时跳过旧文件）。
- `AssetRegistry` 对 `.raasset` 读清单得到类型/GUID/显示名，`.ramat` 仍走旧的头解析；Content 面板因此能直接列出新材质。
- 场景**仍内嵌材质快照**，改为 GUID + 路径引用是下一步；文档已注明。

验证：新增容器往返、损坏 magic 拒绝、材质载荷往返、注册表从容器读 GUID 四组断言；Debug/Release 0 warning，两配置自测通过。


## Content 系统第一步：AssetRegistry + 文件夹浏览器 + 活动场景（2026-10-27，提交 d3ea6d2）

按用户列的五点推进：先做 1（AssetRegistry）、4（文件夹树 + 拖动移动）、5（场景可切换），2（ID 策略）与 3（.raasset 格式）留待下一轮评审。

- 新增 `assets::AssetRegistry`：扫描 `<项目>/Content/**`，按扩展名分类 `.rascene` / `.ramat` / `.obj` / `.hlsl|.hlsli`，缓存显示名、相对路径、文件夹、大小与材质 ID（只读 `.ramat` 头部，不解码几何）；`inFolder` / `find` / `count` 供 UI 使用。
- 新增 `assets::moveContentEntry`：在 Content 根内移动文件；移动场景时重算 `sourcePath`（相对新目录），保证导入 OBJ 引用不断。
- Content 面板改成浏览器：文件夹树（根 + 递归）、面包屑、资产行（自绘类型图标、名称、类型与大小）、拖拽到文件夹移动、右键 Open/Rename/Delete、`New folder`/`Refresh`；保留 `Scene mesh library` 供 `Add Actor from mesh` 使用。
- 场景活动化：`scenePath_` 替代写死的 `project_.defaultScene`；支持打开（双击场景或 Scene 面板 `Open...`，有未保存改动弹确认）、`Save as...`、`New`（生成 `Content/Scenes/Scene[_n].rascene`），保存写入当前场景路径。
- `.raasset` 只出设计提案：`docs/AssetFormat.md`（magic/版本/清单/数据块、payload 结构、迁移步骤、未决的 ID 策略），代码未实现，文档明确标注。

验证：新增注册表测试（临时内容根：分类计数、文件夹列表、材质头解析、场景移动到子目录后仍能加载导入网格）；Debug/Release 0 warning，自测两种配置均通过；截图确认文件夹树、资产行与空文件夹提示。


## HLSL 纳入 solution 便于 IDE 编辑（2026-10-27，提交 6a3c2b2）

需求：shader 代码要出现在 sln 里，方便在 Rider / Visual Studio 直接编辑；不参与引擎编译。

- premake（`RestArtEngine.lua`）在 `files` 中加入 `Shaders/**.hlsl`、`Shaders/**.hlsli`；premake 默认把 `.hlsl` 映射成 `FxCompile`（构建时会尝试编译），因此加 `filter "files:Shaders/**.hlsl or files:Shaders/**.hlsli" buildaction "None"`，生成结果是 `<None Include="..\Shaders\...">`，并在 `.vcxproj.filters` 里形成 `Shaders` / `Shaders\Materials` / `Shaders\Private` 分组。
- CMake 侧用 `file(GLOB_RECURSE ... CONFIGURE_DEPENDS)` + `target_sources` + `HEADER_FILE_ONLY TRUE` + `source_group(TREE ... PREFIX "Shaders")`，VS / CLion 里同样可见。
- `settings/` 是 premake 生成物、已被 .gitignore 忽略，所以提交的是生成脚本；本地已重新生成，`RestArtEngine.sln` 打开即可看到 `Shaders` 分组。
- README 构建章节补了一句说明。

验证：重新生成 solution 后 Debug 构建成功（0 warning），`--editor-self-test` 连续 3 次全部通过。


## Activity 状态移入 Details（2026-10-27，提交 6e92804）

用户指出 Viewport settings 底部的 Activity 状态信息应该放到 Details。已把 `SeparatorText("Activity") + message(status_)` 从 Settings 面板移到 Details 面板**顶部**（在 Actor 属性之前），原因是 Details 内容较长，放底部要滚动才看得到。射线追踪摘要仍留在 Viewport settings。

顺带加固了材质拖拽用例：按下后若 `ActiveId == 0` 补一帧重按；失败信息补上 mouseDown / activeId / preview / step，便于下次直接定位。

验证：Debug 连续 6 次、Release 1 次自测全部通过；基线（stash 本次改动）6 次也全过。此前偶发的 1 次失败属于输入注入时序抖动（材质拖拽/Discard 像素对比），本次改动前后均偶现，非本功能回归。


## Outliner 行内垂直对齐修复（2026-10-27，提交 ecd90be）

用户指出眼睛与右侧文字没有对齐。实测两个控件矩形后确认原因：`Selectable(..., ImVec2(0, eyeSize))` 的高度参数未按其值生效（实测 28px，eyeSize 只有 18px），文字在该矩形内垂直居中；而眼睛按钮只有 18px 且顶对齐，于是眼睛偏上约 6px。

改法：先画 `Selectable`（名称、选中、右键菜单），用 `GetItemRectMin/Max` 取到 **真实行矩形**，再把透明眼睛按钮放到同一行左侧（`SetCursorScreenPos(rowMin.x - eyeColumn - 8, rowMin.y)`），高度取 `rowMax.y - rowMin.y`，图标中心取按钮矩形中心；行末用 `SetCursorScreenPos(rowStart.x, rowMax.y + ItemSpacing.y)` 推进下一行。右键菜单改用 `BeginPopupContextItem(label)`，与 Selectable 的 ID 一致。

实测：图标中心 y=180，文字中心 y=179（同一次截图内测量），差值 ≤1px。Debug/Release 0 warning，两配置自测全绿。


## Outliner 眼睛图标返工（2026-10-27，提交 773976d）

用户看图后认为不对。定位到两个真实原因：

1. 空心瞳孔在 16px 行高下无法成像，环和眼形糊在一起，还容易被看成「圆圈套圆圈」；放大预览好看、真实尺寸失效。
2. 眼形用二次贝塞尔时，曲线只到控制点偏移的一半，实际眼高只有预期的一半，形状被压扁成接近圆形的一道缝；改用三次贝塞尔（控制点偏移的 0.75 生效）。

最终方案：图标按 20px 渲染（`max(18, 文本行高 + 4)`），杏仁眼形 halfWidth 0.44 / bend 0.32 / 线宽 0.09×size，实心瞳孔 0.145×size，隐藏时叠加斜线；行高与图标同高，名称用 `Selectable(..., ImVec2(0, eyeSize))` 对齐。可见态描边透明度提到 0.85（`TextDisabled` 太暗，20px 细线看不清），隐藏态 0.55 并加斜线。

`assets/icons/outliner-eye` 的 SVG/PNG、README 的几何与线宽说明同步为最终参数；20px 以下不再使用空心瞳孔写入规范。Debug/Release 0 warning，两配置自测全绿。


## Outliner 眼睛图标定稿 + 图标资源规范（2026-10-27，提交 6c7771e / 802c6c7）

- 用户选定方案 B：空心瞳孔、纯线框，隐藏状态加斜线。`drawEyeIcon` 改为线框实现（`AddCircle` 空心瞳孔替代 `AddCircleFilled`，线宽 `max(1.0, size*0.075)`，斜线 `±0.34/0.30 * size`），仍是 `ImDrawList` 过程绘制，任意 DPI 清晰。
- 图标资源统一放到 `assets/icons/<area>/`：`outliner-eye/` 下是选定方案的 `eye_visible.svg`、`eye_hidden.svg` 与 32/64px PNG；`variants/` 归档 A–F 六版方案和对比图 `contact_sheet.png`。命名与绘制规范写进 `assets/icons/README.md`（24 viewBox、圆头线、`#E6E6E6`、透明底、必须提供可见/隐藏两态）。
- 原 `local/assets/outliner-eye` 保留为本地工作副本，仓库内以 `assets/` 为准；`docs/GuiDevelopment.md` 增加图标目录说明。

验证：Debug/Release 均 0 warning，两配置 `--editor-self-test` 全部通过（Release 无 debug layer），截图确认空心瞳孔与斜线效果、图标列水平居中。


## Outliner 可见性小眼睛（2026-10-27，提交 7c87f76 / bae6db9）

需求：大纲列表每个物件前加小眼睛，标示是否隐藏，并且可点击切换显示/隐藏。

- 每行结构改为：透明 `Button`（`##visible<id>`，尺寸约一个文本行高）+ `SameLine` + 原 `Selectable`。眼睛用 `ImDrawList` 自绘：可见时画眼形（两段二次贝塞尔 + 实心瞳孔），隐藏时画同样眼形加一条斜线；悬停时颜色变亮并显示 "Hide actor"/"Show actor" 提示，光标切手型。
- 隐藏 Actor 的名称用 `ImGuiCol_TextDisabled` 呈现，去掉原来的 " (hidden)" 文本后缀。
- 新增 `SceneEditor::setActorVisible(id, visible)`：一次点击产生一条可撤销记录（`Show Actor` / `Hide Actor`），并置脏标记；Details 的 `Visible` 复选框改走同一入口，两处行为一致。
- 用透明 `Button` 而不是 `InvisibleButton`，因为后者不是 nav item，测试无法通过 `GetID` 定位；透明配色同时保持视觉上只有图标。

测试与稳定性：新增 Outliner 眼睛点击断言（点击后 Actor 隐藏、一次撤销恢复）。为消除既有渲染对比用例的时序抖动：`capture` 在视口矩形退化为 0 时最多重试 3 帧；forward/deferred 对比前增加一帧预热；Details 材质断言改为只在 `--- Assigned material` 到 `--- Mesh` 区间内匹配，避免被 Outliner 文本干扰。

验证：Debug/Release 各跑 `--editor-self-test` 全部通过（Release 无 debug layer），三连跑无 flake；截图确认眼睛图标、隐藏斜线、变暗名称与提示。


## Scene / View 面板再分（2026-10-27，提交 d55b9da）

用户要求把 Viewport settings 里的「Scene 统计、Key light、Direct-light shadows（含阴影方式与说明）」移入 Scene；Exposure 保留在 View 侧，作为所有光照与后处理之后的最终提亮。

- Scene 面板现在：Project、Content、Overview（Actor / Mesh / Material 数量）、Saved、Environment（Sky / Black）、Lighting（Key light，临时场景级，后续迁到 direct-light Actor component）、Direct-light shadows（阴影方式下拉 + 说明）。
- Viewport settings 只剩 View 相关：Exposure（附「最终提亮」说明）、VSync、Reset camera、Analytic GPU rays 状态、Activity。
- 抽出 `drawSceneLighting(settings)`，Scene 面板在 `drawScene()` 之后调用；阴影说明文案原样保留。

验证：Debug/Release 构建 0 warning，`--editor-self-test` 全部 PASS，D3D11 validation errors 0；编辑器截图确认两面板内容已按预期分离。未验证：Scene 面板在 980px 窄宽度下需要滚动才能看到阴影方式（未单独截图）。

## 启动窗口布局：加载页无边框 + 编辑器 80%（2026-10-27，提交 b446f64）

用户要求加载页去掉外边框、放在主屏中央并占横向 28%，启动后的编辑器界面占屏幕 80%、同样主屏居中。按此前选定的 Route A（双窗口 + 重建交换链）实现：

- `SceneRenderer` 改为 `D3D11CreateDevice` + `IDXGIFactory2::CreateSwapChainForHwnd`：设备与交换链解耦，`attachWindow` 只重建交换链和窗口尺寸相关目标，`detachWindow` 在旧 HWND 销毁前释放，避免 DXGI 释放已销毁窗口的交换链。
- 启动分两阶段：`WS_POPUP` 无边框加载窗口（28% 屏宽、按 `load.png` 836×471 比例、主屏居中）承载加载页，完成时销毁；随后创建 `WS_OVERLAPPEDWINDOW` 编辑器窗口（80% 屏宽高、主屏居中、保留原生边框与自定义标题栏），复用同一设备与已编译管线。自测仍走固定 1440×900 单窗口，保证截图可比。
- 期间定位到一个非死锁问题：编辑器窗口创建后没有 `ShowWindow`，看起来像卡死，实际是隐藏窗口；补上后一切正常。

实测（2560×1440 主屏，Release 与 Debug 各跑一遍）：

- 加载窗口 `716×403` @ `(922,518)`，`style=0x94000000`（`WS_POPUP|WS_VISIBLE`，无标题栏），约 400ms 时为 16:9 占位、700ms 已按图片比例修正。
- 编辑器窗口 `2064×1191` @ `(248,124)`，`style=0x14CF0000`（`WS_OVERLAPPEDWINDOW|WS_VISIBLE`），客户区 2048×1152 即 80%。

验证：Debug/Release 构建 0 warning，`--editor-self-test` 全部 PASS，D3D11 validation errors 0；编辑器窗口截图确认面板与新 Scene/Details 分工正常。未截到加载页画面（窗口存活约 1 秒且被前台浏览器遮挡，只记录了矩形与样式）。

## Scene / Details 职责重分（2026-10-27，提交 cdff41e）

用户指出 Scene 里的名称 / 可见性 / 变换 / Mesh 都是 Actor 属性，应全部放到 Details；Scene 只保留场景级参数。改动：

- `drawInstanceDetails()` 接管 Actor 编辑：名称输入、`Visible`、Transform（保留原有 700ms 合并与取消逻辑）、Mesh / Material 下拉、`Edit assigned material`、`Assigned material` 实例按钮，以及只读的 Mesh 几何信息。
- `drawScene()` 改为场景级：工程与 Content 路径、Actor / Mesh / Material 数量、保存状态、`Environment` 的 Sky / Black 背景（新增 `setSceneBackground()`，一次切换记一条撤销并标脏）。
- 自测中所有原先按 `Scene` 窗口定位 `##actorName` 与 `Edit assigned material` 的用例改到 `Details`，并在需要时先切到 Details 页签；全部套件恢复通过。
- 文档同步 `GuiDevelopment.md` 与 `EditorGuide.md` 的面板职责描述。

验证：Debug / Release 构建通过（0 warnings），`--editor-self-test` 全部 PASS，D3D11 validation errors 0。未截图核对新面板的实际观感。

## 编辑器选中描边（2026-10-26）

用户要求选中物体显示屏幕空间外描边，并明确这是编辑器功能而非运行时功能。实现提交 `4f6f87f`（已推送），位置设计：

- 独立通道 `SelectionOutlinePass`：`include/RestArtEngine/Renderer/SelectionOutline.h`、`src/Renderer/SelectionOutline.cpp`，不继续堆进 `SceneRenderer.cpp`。
- 帧内顺序：场景着色（前向／延迟）→ 遮罩通道（只重绘选中 Actor，深度只读 `LESS_EQUAL`，被遮挡部分不外溢）→ 合成通道（屏幕空间膨胀 + alpha 混合）→ 编辑器合成场景纹理。
- 编辑器只写入 `SceneSettings.outlineActors`／`outlineActorCount`（借用当帧选中列表）、`outlineColor`（主题强调色）、`outlineThickness`；运行时 `render(settings, error)` 不填这些字段，遮罩纹理首次有选中时才创建。
- 着色器入口 `PSOutlineMask`／`PSOutlineComposite` 加在 `Scene.hlsl`，新增 `OutlineConstants`（b4）与 `outlineMask`（t5），反射校验表同步登记，热重载与失败保留沿用原流程。

验证：Debug 与 Release 均构建通过；`--editor-self-test` 全部套件 PASS，D3D11 validation errors 0；自测截图确认描边完整贴合球体轮廓（主题强调色，2px）。过程中发现并修复一个真实缺陷：合成通道原先用视口局部 `Input.uv` 采样全场景遮罩，描边被缩放并偏移到视口左上；改用 `SV_Position × texel` 后贴合。

未验证项：没有自动化像素断言（只有自测截图人工核对）；多选同时描边、150% UI 缩放下的表现未单独截图；只覆盖 Windows/DX11 与 Sandbox 工程。本轮未改动 Sandbox 资产；工作区里 `Projects/Sandbox` 的 5 个既有改动（`twoSided` 与场景内容，22:29 早于本任务）不属于本次提交，保持未提交。

### 描边设置：UI 菜单入口 + 独立设置窗口（2026-10-26，提交 2924e8f / 681edb5）

用户要求把描边粗细等设置放到 `UI` 菜单下；随后明确要的是菜单里一个入口，打开**单独的小界面**来调整，而不是把控件塞在菜单里。最终形态（`681edb5`）：

- `UI` 菜单末项 `Selection outline...` 打开居中、自适应高度、不可停靠的独立窗口 `Selection Outline`，含 `Show outline`、`Thickness`（1–6 px）、`Use theme accent`、`Orange`／`White`／`Cyan` 预设色与「当前使用主题强调色」提示；关闭后设置保留。
- 颜色支持自定义（提交 `1fc76d4`）：`Colour` 区新增 `Custom` 行，色块按钮打开取色器，选色即切到非主题色并写入 `outline_color`；与预设色互斥显示选中状态。
- `EditorTheme` 模块扩展为 UI 偏好：`UiPreferences`（主题 + 描边字段），读写 `RestArtEngine.ui.ini`；旧 `RestArtEngine.theme.ini` 仅作兼容读取。
- `SceneEditor::draw` 每帧从偏好填充 `SceneSettings`；窗口获得焦点期间不派发场景快捷键（`outlineSettingsFocused_` 参与两个输入仲裁条件）。
- 自测：偏好读写往返断言；工具栏测试点开 `UI` 菜单最后一项并断言设置窗口打开、含 `Show outline`／`Use theme accent`、点关闭按钮后不再绘制。

验证：Debug／Release 构建通过、`--editor-self-test` PASS、D3D11 validation errors 0。过程中修复两个真实缺陷：`outline_thickness=` 前缀长度按 17 截取（实际 18）导致粗细读回默认值；设置窗口关闭时提前 return 未清 `outlineSettingsFocused_`，使后续视口 Delete 一直被吞掉，由既有 Delete 回归测试捕获。

未验证：没有实际拖动滑块后截图对比粗细变化（只有窗口可达性与偏好往返断言）；多选与 150% 缩放下的描边外观仍未单独截图。
### 描边只取外轮廓、遮挡段虚线、G/H 快捷键（2026-10-27，提交 87dda30）

用户反馈选中地面时描边把网格内部线条也描了，并要求：只描物体外边框、被遮挡部分画虚线；新增 G 切换描边显示、H 切换选中物体可见性。实现：

- 深度纹理改为 `R32_TYPELESS`（DSV `D32_FLOAT` + SRV `R32_FLOAT`），供描边合成读取。
- 遮罩改为双通道：R = 通过场景深度的可见片元，G = 被遮挡片元（深度 `GREATER`）；两次绘制用只写对应通道的 blend state。
- 合成改为像素坐标读取遮罩与深度：只有相邻遮罩像素存在**真实深度差**才画实线，因此同一表面内部的网格线、共面接缝不再产生内边框；G 通道按屏幕空间虚线（`(x+y) & 7 < 4`）绘制。
- `G` 注册为 `view.toggleOutline`，切换并保存 `selectionOutline` 偏好；`H` 注册为 `actor.toggleVisibility`，多选时统一收敛到同一状态并记一条撤销。

过程中修复两个实测缺陷：合成重写后漏了 alpha 混合，透明黑覆盖整屏（被材质预览像素测试捕获）；`PSSetShaderResources(5, 2, &单个指针)` 越界读取导致进程崩溃（exit 2173），改为双元素数组。

验证：Debug／Release 构建通过，`--editor-self-test` 全部 PASS，D3D11 validation errors 0；自测断言覆盖两个命令已注册。**未验证**：G/H 的实际调用行为没有自动化断言（尝试加入 invoke + undo 的用例会使后续材质像素测试失败/自测挂起，已移除）；地面选中不再出现内部线条、以及遮挡虚线两种情况没有截图证据，只有实现层面的深度差规则；Sandbox 的 5 个既有改动仍未提交。
补充（用户提供截图后，提交 b4de534）：虚线错误地变成整片斜线填充，原因是判定只用「相邻像素在 G 通道」而没有排除中心自身也在 G 通道，导致遮挡区域内部每个像素都满足条件。现改为只有 `center.g < 0.5` 且邻居 `g > 0.5` 的**边界环**才画，并按屏幕空间虚线；填充显示保留为独立样式（`Occluded: Dashed contour / Filled`，偏好键 `outline_occluded`，设置窗口可切换，默认虚线）。自测新增 `outlineOccludedStyle` 的偏好往返断言；Debug/Release 构建与 `--editor-self-test` 通过、D3D11 校验 0。仍缺：遮挡虚线形态的截图证据。后续按用户要求（提交 ac13f67）**移除遮挡填充样式**：`outlineOccludedStyle`、偏好键 `outline_occluded`、设置窗口 `Occluded` 单选与着色器填充分支全部删除，遮挡部分只保留虚线轮廓。再按用户反馈（提交 1b99b60）把实线判定改成**单向深度比较**（邻居比中心更近才算轮廓），避免在前方遮挡物上描出实线；同表面内部细节与前方遮挡物的描边都由这一条规则排除。随后按用户要求（提交 40b0469）把「是否描前方遮挡物」做成可配置项：设置窗口 `Outline occluders in front`，偏好键 `outline_occluders`，默认关闭走单向深度比较，开启后改回双向比较；已补偏好往返断言。用户随即澄清「不要描整个遮挡物」（提交 9b876cc）：删除双向比较路径，遮挡物上只画与被遮挡物体**相交的那一圈**；选项语义改为 `Solid intersection line`（默认虚线交线，勾选后为实线），偏好键改为 `outline_intersection=dashed|solid`，设置窗口与文档同步。用户看图确认后（提交 98064d8）再次调整：勾选后应恢复**双向深度比较**，让前方物体获得整圈实线，相交环保持虚线；选项更名为 `Outline front objects`，偏好键 `outline_front_objects=on|off`，默认关闭（不描前方物体）。 用户随后提供色样（提交 cf51731）：从附件采样到 `#FD7804`（R253 G120 B4，归一化 0.992/0.471/0.016），设为 `UiPreferences.outlineColor` 默认值、`outlineThemeColor` 默认改为 `false`，Orange 预设同步为该色；工作目录的 `RestArtEngine.ui.ini` 已改为该默认值（旧文件会覆盖默认，需删除或取消勾选主题色）。顺带为材质 Discard 像素比较补了一帧，降低偶发的单帧竞态。

## 仓库外备份清理请求（2026-10-26，尚未完成）

用户要求删除清理备份并保持当前工程与技能／角色不受影响。已解除备份内 6 个指向当前 vendor 的 junction，仅删除链接本身；备份目录的递归删除两次被执行工具安全策略拒绝（`blocked by policy`，未提供具体原因），目录及其余内容仍在，不标记为已清除。未改动正式文章或用户级配置。

完整性核验通过：当前工程、三个依赖子模块、项目技能／角色及 AGENTS 共 1,571 个文件哈希不变；6 个技能格式、3 个 TOML 和 170 个本地相对链接通过，Git 工作区干净。结果见 `local/maintenance/backup-cleanup/checks.json`，其中 `backup_removed` 为 false。备份清除完成前，原证据位置仍按本地位置索引处理。

## 最新边界：干净基线后重新整理（2026-10-26）

用户进一步明确：只要涉及 AI 或开发过程／项目日志，包括其管理规范本身，都不得上传。此前将 RepositoryPolicy 当作公开规范不符合此边界；本次已将它与协作、进度、DevLog 文档统一放入 `local/docs/`，公开引用移除。公开 `docs/` 保留引擎技术说明，少量提交历史／协作流程描述已移出；运行时代码、测试与构建配置不变。

整理提交为 `8ad6255`，未推送；提交后 Git 普通状态为空。核验 36 个备份文件哈希、26 个本地文件忽略、110 个公开跟踪文件内容和 217 个相对链接，3 个日期／文件名模板链接按示例排除；6 个技能格式校验及3个角色 TOML 解析通过。独立审查发现的 GUI 授权／审批残留已移入本地协作流程后重验通过。检查脚本与结果在外部备份根 `verify.py`、`checks.json`；不以本次文档检查代替引擎运行测试。

按用户确认以远端最新 `ba7311a` 为基准：5 个已跟踪文件的未提交修改和 23 项未跟踪／忽略条目先保存到仓库外，核验 36 个关键文件哈希，再恢复得到 Git 状态为空的工作区。Sandbox 的原编辑与新增材质仅在备份中，不自动应用回工作区；具体恢复位置见 [LocalDevelopmentGuide](LocalDevelopmentGuide.md)。旧构建与证据也已归档，不能把旧构建缓存当作当前有效配置。

项目技能、角色和 AGENTS 已恢复为被忽略的本地配置，并改用 `local/docs/` 入口；用户级服务配置及外部正式文章未改。下方内容是历史记录，若与本节位置／公开边界冲突，以本节为准。已推送的旧提交仍包含历史资料，本次没有改写历史或强制推送。

## premake 生成修复与基线对齐（2026-10-26）

用户报告：Codex 清理工程数据后，premake 生成的解决方案丢了 RestArtEngine 的运行配置。核对发现工作区已有一份未提交的 `Build.lua`／`Config.lua` 改动（当日 18:03 修改）：它把 Rider 运行配置从 `.run/RefreshConfig.run.xml` 迁到 `.idea/.idea.RestArtEngine/.idea/runConfigurations/`，但未提交，且生成函数用 `assert` 直接中断 premake。

本轮修复提交 `b90f541`（已推送）：

- 配置列表收敛为 `Config.lua` 的 `EngineConfigurations`，`Build.lua` 的 `configurations` 与 Rider 运行配置共用同一份，避免两边漂移。
- `.idea` 目录按需创建；创建或写入失败降级为 warning，不再中断整个 premake 运行（中断会让 sln／vcxproj 停在旧版本）。
- 写入幂等：内容相同不重写，避免每次生成都触发 Rider 重载运行配置；旧 `.run/RefreshConfig.run.xml` 删除失败也只 warning。

验证（Windows / VS2022）：删除 `.idea`、`.run`、`RestArtEngine.sln`、`settings/` 后运行 `scripts\GenerateWIN.bat`，sln 含 `RestArtEngine` 与 `Debug|x64`／`Release|x64`／`Dist|x64` 三条映射；生成 `RefreshConfig.xml` 与 `RestArtEngine.xml`，后者含 `configuration_1..3` 对应 Debug／Release／Dist；第二次运行 xml 未被重写。Debug 与 Release 均构建通过，`--editor-self-test` 通过（D3D11 校验 0 错误）。

未验证：Rider 打开解决方案后运行配置下拉的实际显示，需要用户在 IDE 中确认。本轮不改引擎运行时源码。基线：修复前 HEAD `8ad6255`，修复后 HEAD `b90f541` 与 origin/master 一致，工作区干净。

## 规则入口复读与一致性核对（2026-10-26）

本轮按 `AGENTS.md` 入口复读规则体系，核对当前工作区与公开边界。HEAD 为 `8ad6255`，Git 普通状态为空；本轮只读核对，未改引擎代码、未运行引擎、未提交。

- 入口齐全：`AGENTS.md` 指向的 `local/docs/` 四份（DevelopmentStatus／AgentDevelopment／RepositoryPolicy／LocalDevelopmentGuide）、`.agents/skills/` 六份技能（context／core／delivery／devlog／gui／rendering）、`.codex/agents/` 三份角色 TOML 均存在；公开事实入口为 `docs/GuiDevelopment.md` 与 `docs/RenderingDevelopment.md`。
- 忽略边界：`local/`、`local/docs/DevelopmentStatus.md`、`.agents/`、`.codex/`、`AGENTS.md` 五个探针全部命中 `.gitignore`；`docs/` 白名单为 9 份公开文档加 `docs/vendor/{imgui,ImGuizmo}.md`；`开发日志`／`开发日记`／`知乎`／`第 N 期` 四条中文忽略模式经 UTF-8 读取确认有效，不是乱码。
- 公开边界：13 份被跟踪 Markdown（README、9 份公开 docs、2 份 vendor 说明、`vendor/README.md`）对 `local/docs/`、`AGENTS`、`DevelopmentStatus`、`ZhihuSeries`、`AgentDevelopment`、`RepositoryPolicy`、`.agents/`、`.codex/` 的引用计数为 0。
- 引用一致性：6 个技能 front matter 的 `name` 与目录名一致且 `description` 完整；3 个角色 TOML 均含 `name`／`description`／`developer_instructions` 顶层键；`GuiDevelopment.md` 引用的 15 个源码／脚本入口全部存在。
- 链接检查：`local/docs` 与技能内共 155 条相对链接，缺失 3 条均为写作规范中的日期模板示例（`YYYY-MM-DD_第NN期_assets/...`），与既有“按示例排除”记录一致，不是真实断链。

本机没有可用 TOML 解析器（PATH 上的 `python` 是 WindowsApps 占位），角色结构按顶层键与文本核对，未做完整 TOML 语义解析；GUI／渲染的运行证据沿用本页既有条目，本轮不新增 GPU 结论。主题系统的公开说明见 [GuiDevelopment](../../docs/GuiDevelopment.md)，本轮未重复其截图验证。

## 本地资料与公开仓库边界（2026-10-26）

位置与维护职责已汇总到 [LocalDevelopmentGuide](LocalDevelopmentGuide.md)：区分公开仓库、项目内忽略资料、用户级外置配置与外部文章目录；AGENTS、AgentDevelopment、写作规范及底稿均引用此索引。公开 RepositoryPolicy 补充配置位置、同步职责、手工打包与换机规则，Architecture 和 EngineDistribution 接入同一入口。此同步不搬移现有文件、不读取或改动个人模型配置、不改变文章发布状态。

位置规范同步提交为 `ba7311a`，只含三份公开文档；六份本地入口／记录保持忽略。检查 14 份公开 Markdown 与相关本地入口的 97 个相对链接，Sandbox 9 个文件哈希保持不变，记录为 `artifacts/repository-boundary/document-sync-checks.json`。未推送。

用户明确要求 AI 技能／角色、本地协作与阅读记录、DevLog 和开发日志不上传。`.agents/`、`.codex/`、本页、AgentDevelopment、DevelopmentChanges-DevLog02 与 GodotGuiStudy 已移出 Git 索引，文件继续在原路径供本机使用。写作规范、底稿、媒体检查器和外部正式稿继续保留，不改变文章交付状态。公开范围见 [RepositoryPolicy](RepositoryPolicy.md)；新增公开文档须加入 `.gitignore` 的 `docs/` 白名单。

Architecture、GUI、Rendering、UndoTransactions 与 GC 保留引擎契约和复现方法；原来的历史验证段落随完整原文备份至本机 `artifacts/repository-boundary/before/docs/`，可供后续写作查证。`before.json` 记录起始 HEAD、文件清单与哈希；实际核验结果记录于同目录 `checks.json`。原有 Sandbox 编辑不得纳入本次提交。该整理不改运行时实现，不新增 GPU 验证结论。

此前提交已经包含部分本机资料。移出索引和普通删除提交不清除历史对象、远端旧版本、标签或其他克隆；未执行历史改写或推送。

整理提交为 `9239226`。验收通过：68 个本地资料忽略探针、122 个公开文件／新增路径非忽略探针、14 份公开 Markdown 的 49 个相对链接、111 个跟踪文件的本机资料引用扫描；24 个本地资料文件仍在，Sandbox 9 个文件哈希未变。独立只读复核确认公开功能契约完整，提交仅含本轮 26 个文件的规则／文档／索引变更。未重建或运行引擎。

此页供主 agent 和专项 agent 恢复上下文。它是索引与近期交接记录，不替代领域设计文档，也不代表所有已列功能都在当前工作区重新验证。使用方式见 [AgentDevelopment.md](AgentDevelopment.md)。

DevLog02 开发交接已于 2026-10-26 整理到 [DevLog01 之后的变化审计](DevelopmentChanges-DevLog02.md)：逐项核查 `DevLog01..4193f55` 的 20 个提交，映射最终功能、优化、领域文档和运行证据，并单列第 1 期正文终点与标签之间的 3 个差额提交。本轮只核对文档／源码／既有日志，不新增引擎运行结论；该审计完成时尚未写正文。后续第 2 期图文稿已交付，状态见下方 DevLog02 交付节和 `ZhihuSeriesLedger.md`。

审计表的 20 项提交覆盖与顺序、84 个实际本地文档引用、差异空白及新增内容的本机路径检查通过；文档示例里的日期占位图片链接单独排除。独立只读复核未发现提交遗漏或把计划当实现的问题，Sandbox 原文件哈希保持不变。本机核验记录为 `artifacts/devlog02-audit/checks.json`。

审计新发现：标签前 `RayTracing_Simple` 的 5 个独立材质文件含无效 JSON（roughness 数值后多余引号），本轮解析失败已登记，未改工程素材；旧 `Test-Window.ps1` 仍容忍空退出码，严格退出验证应引用最终 `Test-WindowChrome.ps1` 结果。详见上述审计的待办节，不能把这些未处理项写成已完成。

DevLog02 媒体规范补正（2026-10-26）：重新读取 DevLog01 正文与全部 12 个实际媒体文件，确认正文就近引用 10 张编号 PNG，另 1 张 PNG 和 1 段 GIF 未引用。本机规范 v1.11、底稿与 DevLog skill 已补齐逐图动作／来源／正文落位、外部本期 `_assets` 目录和每个最终 GIF ≤ 5,000,000 字节要求。新增本机媒体检查器通过 DevLog01 文件检查与隔离用例：等于上限允许、超 1 字节拒绝、缺失／损坏图片及越界／绝对引用拒绝；skill 格式验证通过。记录为 `artifacts/devlog02-media-rules/`。此轮只修规范与计划，未生成 DevLog02 正文或正式媒体；文件检查不能代替目视隐私和完整动图播放。

## 需求、进度与标准到哪里查

| 范围 | 权威入口 | 使用时关注 |
| --- | --- | --- |
| 产品范围、已有功能与限制 | [README](../../README.md) | “特性”“当前边界”；不要把方向当成已实现功能。 |
| 模块归属、依赖与开发约定 | [Architecture](../../docs/Architecture.md) | 数据流、CPU/GPU 契约、编辑器合成和验证记录。 |
| 渲染需求、跨平台目标与缺口 | [RenderingDevelopment](../../docs/RenderingDevelopment.md) | 已确认范围、源码基线、待讨论设计；DX11 实现与其他 API 骨架分开。 |
| GUI 设计规范、工程基线与验收 | [GuiDevelopment](../../docs/GuiDevelopment.md)、[GodotGuiStudy](GodotGuiStudy.md) | 前者是 GUI 专项设计/开发入口，后者保留研究和阶段快照；后续窗口和工具栏进展见 Architecture。 |
| 编辑器操作与事务边界 | [EditorGuide](../../docs/EditorGuide.md)、[UndoTransactions](../../docs/UndoTransactions.md) | 快捷键、保存语义、多选、Alt 复制、撤销覆盖。 |
| 工程和分发 | [ProjectManagement](../../docs/ProjectManagement.md)、[EngineDistribution](../../docs/EngineDistribution.md) | 工程资产边界、版本关联、构建与发布流程。 |
| 阴影功能 | [ShadowMethods](../../docs/ShadowMethods.md) | 实现差异、资源与验证矩阵。 |
| 资源 GC 与临时截图 | [GarbageCollection](../../docs/GarbageCollection.md) | 定时设置、内存缓存边界、临时截图登记与清理、平台限制。 |
| agent 分工与技能流程 | [AgentDevelopment](AgentDevelopment.md) | 角色路由、任务契约、文件归属、完成条件。 |

## 当前交接基线（2026-10-23）

本次协作体系整理时 HEAD 为 `48797b6`，工作区存在引擎、文档、Sandbox 内容及 agent 配置改动。它们不都由本轮产生；任务启动时重新检查 Git 状态，不将此 SHA 当作全部工作区改动的提交证明。

| 项目 | 已知事实与证据 | 剩余边界 |
| --- | --- | --- |
| 菜单、Alt 拖动复制、自定义窗口栏 | Architecture／UndoTransactions 记录了 2026-10-23 的运行验证；本机 `artifacts/window-chrome-editor/stdout.txt` 可见相关 PASS 与 D3D11 错误 0。 | 历史验证不能自动覆盖后续改动；系统吸附弹窗、跨屏交互仍未据此验证。 |
| 图片 Logo、移除视口底部提示 | 工作区已有对应改动；Logo 的本机运行记录见 `artifacts/window-chrome-logo/stdout.txt`，8 帧且 D3D11 错误 0；提示移除已在此前任务构建通过。 | 本轮是协作配置工作，不重复宣称进行了引擎运行测试。 |
| 核心渲染演进 | RenderingDevelopment 区分实际 DX11 路径与三平台／四后端的设计目标；材质预览任务的最新实现与验证见下一行。 | 真实多后端场景路径仍按领域文档缺口推进，后端枚举不代表可用实现。 |
| 材质参数实时预览 | 材质预览任务已在 Windows/DX11 完成：只读草稿覆盖统一用于光栅与光追，保留 Apply／Save／Discard 边界。独立 MSVC Debug 构建、隔离 Sandbox 编辑器自测、渲染回归通过，D3D11 错误 0；证据见 `artifacts/material-preview-editor/stdout.txt`、`artifacts/material-preview-render-validation.txt`，范围见 RenderingDevelopment。 | UI 自动化实际拖动 Roughness／Metallic；Base color／Grid 和切材质确认分支已审查、未单独注入交互测试；其他平台／后端未运行。本次改动未提交。 |
| 材质 Two-sided | 2026-10-23 在 Windows/DX11 完成逐材质双面开关，含实时预览、面剔除／法线、镜像、反射、阴影、拾取及新旧文件持久化。独立 MSVC Debug 构建、完整编辑器自测和渲染回归通过，D3D11 错误 0；证据见 `artifacts/two-sided-editor/stdout.txt`、`artifacts/two-sided-render-validation.txt`，具体对照范围见 RenderingDevelopment。 | 新材质默认单面，旧缺字段默认双面；其他平台／后端未运行，未新增材质属性通用撤销。本次改动未提交。 |
| agent 协作体系 | core 角色、context／core／delivery 技能已建立，rendering 已接入。两个 TOML 解析、四个开发 skill 校验、41 个本地文档链接检查通过；只读演练实际分派了一个渲染调查子 agent，完成跨模块任务契约与回报。 | 本轮验证了普通子 agent 读取角色／技能的兼容分派；客户端原生命名角色加载未验证。演练没有实现或运行材质预览功能。 |

本机 `artifacts/` 不随仓库分发；不存在时按历史文档记录处理，需要本轮证据则重跑相关验证。详细需求不复制到 skill，未明确排期的缺口不自行提升为当前任务。

## GUI 专项配置与验证（2026-10-23）

按本聊天的 GUI 设计用途新增 [gui 角色](../../.codex/agents/restarengine_gui.toml)、[gui skill](../../.agents/skills/restarengine-gui/SKILL.md) 与 [GUI 规范](../../docs/GuiDevelopment.md)，接入主引擎路由和交付流程。规范记录当前工程入口、Black / Dark Blue 风格基线、外部标准适用范围，以及任务/状态设计、布局原型、视觉规则、实现与验收流程；未在本轮修改运行时 GUI。

三份角色 TOML 和 GUI UI 元数据解析通过；本轮涉及的 core／delivery／gui 三个技能通过格式校验，相关本地 Markdown 引用检查通过。独立普通子 agent 读取新技能后，完成了“窄面板材质编辑器先给方案”的只读演练，交付布局、状态与验收条件，保留预览/Apply/Save/Discard 语义，没有越界实现。另一次只读复核未发现工程事实或职责冲突。本机交接记录见 `artifacts/agent-tasks/gui-agent-setup.md`。

这些结果验证了文件配置、规范与显式读取技能的兼容用法；客户端原生 `restarengine_gui` 角色加载未验证。本轮未重建或运行引擎，也不新增跨屏 DPI、完整键盘导航或可访问性达标结论；没有执行提交。

## 资源 GC（2026-10-24）

已接入 Core 调度器、Renderer／ImGui 缓存回收和受管临时截图清理。Project Manager、编辑器帧末及最小化循环使用同一调度；`UI → Garbage collection...` 支持自动开关、检查间隔、内存闲置时间、截图保留时间、保存设置与手动请求。默认分别为 60 秒、60 秒和 1 小时。内存范围、配置格式和永久／临时截图边界见 [GarbageCollection](../../docs/GarbageCollection.md)。

本轮 Windows/DX11 验证使用独立 MSVC Debug 构建 `build/gc-vs2022` 与隔离 Sandbox：

- Core CPU 回归通过（CTest 1/1）：时间调度、配置校验／替换／失败保旧、跨会话过期文件、修改／未知文件保留、junction／硬链接／锁定文件保护、写入期间目录及文件锁、登记碰撞不覆盖。最终日志为 `build/gc-vs2022/Testing/Temporary/LastTest.log`。目录、截图和登记文件的 3 项 symlink 创建测试因本机权限跳过，不将其记作运行通过。
- GC GPU／UI 自测通过：活缓存保留、闲置 GPU 资源释放、恢复场景画面一致、不同 ray 消费者、字体 CPU 像素／闲置 UI 缓冲、设置草稿／保存／重载、关闭自动后手动请求、Black／Dark Blue 及窄面板滚动。最终证据为 `artifacts/gc-validation/final-gpu.txt` 与 `gpu-final/` 截图。
- 完整编辑器自测与渲染回归通过，D3D11 验证错误为 0；证据为 `artifacts/gc-validation/editor-stdout.txt` 与 `render/validation-results.json`。Premake 工程重新生成后包含新增源文件。
- 实际 CLI 跨进程回归通过：一个进程使用 `--capture-temp` 生成并登记截图，后续进程回收过期文件，同时保留同目录未登记哨兵与永久输出。该场景首轮释放 41,947,604 字节 CPU 缓存（约 40 MiB）；活 GPU 缓存保留。证据为 `artifacts/gc-validation/final-temp-create.txt`、`final-auto-collect.txt`，本机复现脚本为 `verify-temp-lifecycle.ps1`。最后的目录锁／原子发布修正后已重跑 CPU、GC GPU／UI 与此 CLI 回归；没有重复不受影响的完整编辑器／渲染套件。

这属于派生资源／缓存回收，不扫描任意 C++ 对象，不自动删场景、CPU 资产或撤销历史；现有截图及自测证据不回收。跨平台文件保护和其他图形后端未验证，本轮改动未提交。

## 用户 Capture 保存位置（2026-10-24）

按用户要求，工具栏 Capture 与 F9 改为系统“另存为”对话框：由用户选址，默认系统“图片”目录，同次会话记住目录，BMP 扩展名和覆盖确认明确；取消不落盘，保存失败提示且保留编辑器。F9 不随按住自动重复。`--capture-dir` 仅用于批量／自测，手动操作不能通过该参数绕过选框。单独 `--frames N` 不自动导出；自测缺省输出迁到系统临时目录的 `RestArtEngine/Validation`，不再自动生成项目 `screenshots`。

已按本次明确删除指令清除原 `bin/windows-x86_64/Debug/screenshots` 下 3 张用户 Capture 图片（合计 15,552,162 字节）；这不是 GC 自动识别或删除旧截图的能力。工程素材、Logo 和独立历史自测证据保留。

MSVC Debug 构建通过。新增 `scripts/Test-Capture.ps1` 实测 F9 弹框／取消、中文选址保存有效 BMP、覆盖拒绝保旧／确认覆盖、实际鼠标点击 Capture、场景文件不变、干净退出；D3D11 错误 0。测试默认使用系统 TEMP 下的独立工程与图片目录，保存框截图已检查。额外实际运行验证 `--frames` 无输出、显式 `--capture-dir` 输出、`--capture-temp` 登记输出均通过。结果摘要位于本机 `artifacts/capture-dialog/results.txt`。`Test-Window` 与 `Test-WindowChrome` 已同步原生保存框操作并通过解析检查，本轮不重复完整窗口套件。使用说明见 [EditorGuide](../../docs/EditorGuide.md#capture-截图)，未执行提交。

## 系统独立材质编辑器（2026-10-26）

按用户明确选择，材质参数和工程共享 Shader 编辑已迁至可移出主窗口的系统窗口。Details 的 `Edit assigned material`、Mesh 信息中的实际材质引用以及材质库入口打开／复用该窗口；底部 Content 仅保留 Meshes。工具窗关闭保留会话草稿和预览，主程序退出继续全局未保存确认。主窗口最小化时工具窗可独立编辑；五个工作区面板的 Dock 树和主窗口内工作方式保留。行为与边界见 [EditorGuide](../../docs/EditorGuide.md)，工程契约见 [Architecture](../../docs/Architecture.md)。

本轮使用独立 MSVC Debug 构建 `build/gui-material-vs2022` 和隔离 Sandbox，在 Windows/DX11 完成：

- 完整编辑器自测通过，D3D11 debug layer 开启、错误 0。新增验证真实材质入口、独立无 owner HWND、移到主窗外及缩放、重复打开复用、最小化恢复、原生 WM_CHAR、主窗最小化时编辑、两窗最小化后的关闭处理、草稿保留重开、Mesh 多材质真实引用、Shader 草稿关重开和退出无残留窗口；保留参数连续反馈、Two-sided、Shader 编译回滚、拾取、Gizmo、Alt 复制、事务、布局及文本输入隔离覆盖。最终证据为 `artifacts/native-material-validation/pass4/editor-stdout.txt`。
- 渲染回归 14 帧及 `Validate-Render.ps1 -SkipCapture` 图像检查通过，覆盖前向／延迟、光追、Unlit、法线、resize 和 UI；D3D11 错误 0。证据为 `artifacts/native-material-validation/render/stdout.txt` 与 `render/validation-results.json`。
- GC GPU／UI 自测通过，D3D11 错误 0；证据为 `artifacts/native-material-validation/gc/stdout.txt`。窗口外框脚本通过编辑器／Project Manager 命中、最大化／还原、最小化、F11／Esc、实际 F9 另存与脏关闭保留，证据为 `artifacts/native-material-validation/chrome-focus/results.txt`。窗口脚本现显式激活自己启动的测试窗口再注入按键，符合新的原生焦点作用域。
- 材质参数、Shader 与双主题图像从实际原生窗口的 GPU 渲染目标在 Present 前读回，避免桌面遮挡；已人工检查 `pass4/editor/material_native_black.png`、`material_native_blue.png` 和 `shader_native.png`。截图与本机任务记录不提交。

首轮运行发现后端字符串 context 属性在本机不可用，已用整数属性／进程内绑定保证原生输入和关闭，并实际验证该回退；还修复全最小化时待处理关闭不能推进帧的问题。Apply 图像等价检查发现仅 1 像素的 1/255 量化差异，测试仍严格核对全部材质、场景／相机／视口状态，仅该图像比较允许最多 4 像素各一档差异，其余反馈和回滚断言保留。

本机只有一块显示器，跨显示器拖动和逐显示器字体 DPI 未实测；其他平台／图形后端未运行。未修改工程资产格式、运行中的用户工程或用户进程，未执行提交。本机交接为 `artifacts/agent-tasks/native-material-editor.md`。

## Scene / Mesh Details 页签（2026-10-26）

本节为当时实现与验收记录；用户随后纠正 Details 必须以具体场景实例为目标，当前行为以本页“Details 场景实例修正”和领域文档为准。

按用户确认，将原 Actor 属性页改为 Scene，把 Mesh 信息移入 Details；两页默认在左侧 Outliner 下方同组切换，底部 Content 仅保留 Meshes 资源列表及导入／创建入口。选 Actor 显示 Scene，点 Mesh 显示 Details；事件只排队一次，手动切页后不会持续抢回。Details 展示几何信息及真实场景材质引用，材质按钮继续打开独立系统窗口。当前操作与迁移契约见 [EditorGuide](../../docs/EditorGuide.md)、[Architecture](../../docs/Architecture.md) 和 [GuiDevelopment](../../docs/GuiDevelopment.md)。

保留 `RestArtEngine.DockSpace.v1` 和旧面板身份，旧五面板布局仅补入 Scene；旧 Details 自由浮动时按原位置尺寸建立双页签组，已有 Scene 设置继续尊重用户安排，不重置其他区域。

本轮使用独立 MSVC Debug 构建 `build/gui-material-vs2022` 与隔离 Sandbox，在 Windows/DX11 完成验证：

- 完整编辑器自测通过，D3D11 debug layer 开启、错误 0；最终日志为 `artifacts/mesh-details-validation/pass3/editor-stdout.txt`。新增真实 Mesh 点击后的动态几何信息与单处展示、真实 Actor 点击后的 Scene 字段、手动 Details 激活后连续三帧保持；原生材质入口、草稿与连续反馈、Shader 回滚、拾取、Gizmo、Alt 复制、事务及文本输入隔离继续通过。
- 隔离 ImGui context 覆盖旧停靠 Details、旧自由浮动 Details 和已有独立浮动 Scene 三类布局，各自保存后再次创建 context 读回；未关联面板的停靠／初始几何保留，Scene 无重复创建。原生 Dock 拖动、合并、分割、恢复默认及视口重排仍通过。
- 已检查本次实际 GPU 主窗口截图：`pass3/editor/inspector_details_black.png`、`inspector_details_blue.png`、`inspector_scene_black.png`、`inspector_scene_blue.png`，条件为 1440×900、默认字体／样式缩放、隔离 Sandbox 自测场景。另有原工具栏 980／1440 宽及 150% UI 缩放检查；它不等同于全部属性内容或跨屏 DPI 验收。
- 当前说明已同步 README、EditorGuide、Architecture、GuiDevelopment、UndoTransactions 与 ImGui 依赖说明；53 个本地文档链接和差异空白检查通过。

首轮切页测试补足必要的悬停帧后，分别断言自动切页、手动激活和保持，避免把未激活误报为回跳；一次后段截图写入失败在独立输出目录重跑通过，保留失败证据并增加路径／系统错误码诊断，没有降低功能断言或增加写入重试。其他平台／后端及逐显示器字体 DPI 未在本轮验证，未执行提交。本机交接见 `artifacts/agent-tasks/mesh-details-scene-tabs.md`。

## 静态库链接警告（2026-10-26）

已复现并修复 DearImGui 的 3 条 `LNK4006 __NULL_IMPORT_DESCRIPTOR`：Premake `StaticLib` 的系统 `links` 被写入 librarian 的 `AdditionalDependencies`，合并了 d3d11／dxgi／d3dcompiler／dwmapi 导入库。现从 `vendor/imgui.lua` 移除该归档输入，由最终 `RestArtEngine` 目标解析系统依赖；CMake 将 DearImGui 的系统需求明确为 `INTERFACE`，保留导出目标消费者的链接需求。没有添加告警屏蔽或改 vendor 源码。

已重新生成 Rider／Visual Studio 工程，核对 Debug／Release／Dist 的 DearImGui 归档配置均无系统导入库。Premake 全 solution Debug、Release Rebuild 通过，各 0 警告／0 错误；CMake `build/gui-material-vs2022` Debug 的 RestArtEngine 与依赖 clean build 通过，无警告。修复前／后日志位于本机 `artifacts/build-link-validation/`。Dist 未实际重建；本轮仅调整构建依赖，未重跑 GPU／编辑交互测试，未提交。构建源配置、最终链接归属与告警处理规范已写入 [Architecture](../../docs/Architecture.md#构建依赖与警告)。

## Details 场景实例修正（2026-10-26）

按用户纠正，Details 已从 Content 网格资产检查改为主选中 Actor 实例检查：显示名称、Actor ID、可见性、当前材质以及该实例网格的几何／来源。材质入口位于网格统计之前，默认面板高度下可直接操作。两个 Actor 共享 Mesh 时仍分别读取各自的 Material；不再汇总所有使用同 Mesh 的实例。Content 浏览／导入不改变 Details 目标或抢页签；Outliner／视口选择一次性激活 Details，手动 Scene 页保持稳定。多选标识主实例，空选／删除清空信息，撤销恢复后重新解析；Details 纳入 Actor 输入作用域。Scene 编辑控件、共享材质编辑语义、存档格式及原生窗口／Dock 布局保持原契约。

CMake `build/gui-material-vs2022` Debug 与 Premake Debug 构建通过。隔离 Sandbox 的完整 `--editor-self-test` 通过，D3D11 验证错误为 0；新增运行覆盖同 Mesh 不同材质的双向切换、Content 选择隔离、实例材质入口、Outliner／视口选择、空选、删除／撤销恢复、多选主实例及手动页签稳定。既有原生材质窗口、实时参数、Shader 回滚、Alt 复制、变换、输入隔离与布局迁移回归继续通过。最终日志为 `artifacts/instance-details-validation/pass4/stdout.txt`，双主题截图为 `pass4/editor/inspector_instance_details_black.png`／`inspector_instance_details_blue.png`，已检查实例身份和当前材质可见。

初次断言误将 Outliner 的 Ground 实例名当作另一材质；校准为锁定版 ImGui 实际按钮日志 `[ label ]` 后，仍保留材质入口存在及另一实例材质不存在的双向断言。原生 backend context 属性回退日志与既有实现一致。其他后端、跨屏 DPI 未运行；本轮没有重跑无关渲染／GC 套件，未提交。续接记录见本机 `artifacts/agent-tasks/instance-details.md`。

## Capture 弹窗期间外框变白修复（2026-10-26）

已复现并修复用户报告：Capture 原生保存框打开时，主窗口被经典浅色系统标题栏与边框覆盖。消息级像素观察将覆绘定位到 `WM_NCACTIVATE` 默认处理；`WindowChrome` 对非最小化窗口直接返回 `TRUE`，最小化仍走默认处理，保持焦点切换和模态禁用／恢复。未修改 Capture 选址、文件保存或主窗口样式；临时诊断代码已移除。平台处理约定见 [Architecture](../../docs/Architecture.md)。

CMake `build/gui-material-vs2022` Debug 和 Premake solution Debug 构建通过，无编译警告。新增桌面画面回归在修复前失败（标题背景 RGB 从 `31,31,32` 变为 `201,215,229`），最终构建的 Black／Dark Blue 均通过并已检查实际 PNG：F9、鼠标 Capture、嵌套覆盖确认期间自绘标题栏与外框保持主题，取消恢复 owner 可用；Unicode BMP 保存、拒绝／确认覆盖、场景不变和零退出码继续通过，D3D11 验证错误 0。Black 使用 CMake 构建，Dark Blue 使用 `bin/windows-x86_64/Debug/RestArtEngine.exe`。证据分别为 `artifacts/capture-chrome/black/`、`darkblue/` 的 `results.txt`、`owner-before.png`、`owner-modal-f9.png`、`owner-modal-toolbar.png`、`owner-modal-overwrite.png` 和 `owner-after.png`。

`Test-WindowChrome.ps1` 同轮通过编辑器／Project Manager 的标题与边角命中、最小化、最大化工作区、还原、双击、干净关闭，以及编辑器 F11／Esc／缩放／脏关闭保护；结果位于 `artifacts/capture-chrome/window-regression/results.txt`。只操作隔离测试工程与本次测试进程；本轮未重复无关渲染／GC 自测，未验证跨屏和系统吸附弹窗，未提交。

## 启动加载页裁切与空缺修复（2026-10-26）

用户截图中的左侧 Logo／名称／状态文字被裁掉、右侧与底部留空，源于启用 ImGui 多 viewport 后仍把加载页绘制原点写死为 `(0,0)`，并以整个客户区尺寸绘制。`LoadingScreen` 已统一使用主 viewport 本帧 `WorkPos / WorkSize`：完整背景和进度层对齐标题栏下方工作区，明确归属主 viewport 并裁剪到该工作区；调用接口不再接受容易混淆坐标系的 display width／height。保留现有完整图片拉伸与相对比例设计。

CMake 与 Premake Debug 构建通过。新增 `LoadingScreenTests` 通过，覆盖实际 WIC 解码／WARP 纹理创建、缺图回退、完整 UV、标题栏排除、1440×900／980×700／480×360，以及正坐标／负坐标平移后文字与进度几何一致；允许 ImGui 字形像素对齐造成的 1 像素差异。实际启动流程的 15%／65%／100% GPU 帧通过临时诊断导出，已检查背景、Logo、完整名称、状态与进度条，图片位于 `artifacts/loading-screen/loading-stage-1.png` 至 `loading-stage-3.png`；诊断导出代码已移除并重建最终程序，不增加普通启动的自动截图行为。隔离 Sandbox 启动、进入编辑器及退出成功，D3D11 验证错误 0。测试仅模拟负桌面坐标，未声称完成跨屏 DPI 交互验收；未提交。

## 主线集成与提交状态（2026-10-26）

将 `codex/chat-editor-fixes` 的五项交付压缩整合到 `master` 的 `5dfe4b5` 之后，保留主线已有的独立系统材质窗口、Scene／Details 页签、实时材质预览和 Two-sided。整合覆盖自定义图片标题栏、Alt 复制、实例 Details、GC、Capture 选址与弹窗外框修复、加载页工作区适配、构建依赖以及协作技能／文档；Sandbox 用户场景和材质不纳入提交。上文的“未提交”是对应阶段的历史状态，以本次主线集成为准。

集成前逐项比较两条提交线与工作区，补回 Shader UI 自测的 CRLF 归一化：ImGui 输入过滤 CR，UI 回读比较采用可输入文本，API／磁盘原样恢复断言继续逐字节检查。依赖文档同步 Details 的选中 Actor 实例语义。

本次最终代码在 Windows/DX11 的验证：CMake Debug 与 Premake／MSBuild Debug 构建通过；CTest 的 GC 与加载页测试 2/2 通过；从已提交 Sandbox 创建隔离副本，完整编辑器自测、GC GPU／UI 自测、14 帧渲染自测及图像比较均通过，D3D11 验证错误 0。覆盖独立材质窗口、实时预览、Two-sided、实例 Details、Alt 单／多选复制与撤销、Shader 回滚、停靠重排及布局恢复。本机证据为 `artifacts/linear-integration/{editor,gc,render}/`。本轮不重复原生 Capture 保存框的桌面像素测试，其实现与此前通过版本一致，历史证据见上文；不新增跨平台／跨屏验收结论。原分支历史和集成前工作文件已在本机备份。

## 三条任务线完整性复核（2026-10-26）

在整合提交 `36f4a42` 上复核全部相关任务提交，以下六个原始提交均为当前 `master` 的祖先，已提交功能无需再次 cherry-pick 或另造重复提交：

| 任务 | 提交 | 保留内容 |
| --- | --- | --- |
| 渲染规范 | `c94095d` | 渲染角色、技能、工程结构、热编译、实时反馈及跨平台设计边界。 |
| 材质实时预览 | `1d9b8aa` | 只读草稿预览、连续滑块反馈及 Apply／Save／Discard 契约。 |
| 双面材质 | `3c6de25` | 逐材质 Two-sided、光栅／光追／阴影／拾取、持久化与旧文件兼容。 |
| GUI 规范 | `39416f0` | GUI 角色、技能、主题与设计／验收流程。 |
| 原生工具窗基础 | `c95860c` | 独立平台窗口、消息／焦点处理、最小化及销毁生命周期。 |
| 材质窗口与面板 | `5dfe4b5` | 独立材质／Shader 窗口、草稿保留、Scene／Details 页签与旧布局迁移。 |

分别完成渲染和 GUI 的只读专项复核：关键 HLSL、资产结构与序列化和双面材质提交一致；独立材质窗口及材质／Shader 控件核心实现和 GUI 提交一致；后续 GC 与实例 Details 改动保留两侧契约。Details 改为选中 Actor 实例属于后续需求修正。Visual Studio 式显隐／图钉／命名布局仍是设计提案，三平台／四后端仍以 RenderingDevelopment 中的已实现边界为准。

复用上节同一运行时代码的两套 Debug 构建、CTest、完整编辑器／GC／渲染回归证据；新增真实桌面补测 `Test-Capture.ps1`，覆盖 F9、鼠标 Capture、中文选址、取消、覆盖拒绝／确认、模态期间标题像素及关闭恢复，全部通过，D3D11 错误 0，已检查弹窗期间和关闭后的实际截图。证据为 `artifacts/linear-integration/native-capture-confirmed/`。

窗口补测首轮在 Project Manager 双击最大化后的还原步骤失败。脚本原本以同步 `SendMessage` 发送按下、异步 `PostMessage` 发送抬起；`IsZoomed` 观察到状态变化时，原生最大化处理仍可能未退出，同步按下存在重入风险。现将两边输入统一排队，不改引擎运行时、不放宽断言或添加重试。隔离脚本和最终 `Test-WindowChrome.ps1` 均通过编辑器／Project Manager 最大化、还原、最小化、双击标题、命中区域、F11／Esc、实际 F9 保存及脏关闭保护。失败及两次成功证据分别保留在 `native-chrome-confirmed/`、`native-chrome-queued-probe/`、`native-chrome-final/`；未记录消息级追踪，不将重入顺序推断写成已观测的运行时故障。

提交归属核对记录为本机 `artifacts/linear-integration/all-task-commits.json`。Sandbox 原始文件哈希保持不变，仍不纳入本次提交。上述运行范围为 Windows/DX11；跨屏 DPI、系统吸附弹窗及未实现后端不新增通过结论。

## DevLog02 图文稿交付（2026-10-26）

Codex 已按 `restarengine-devlog` 完成第 2 期正文与媒体，当前状态 **drafting，未发布**：

- 标题：`重启 RestArtEngine DevLog 02｜创建可编辑的引擎工作空间`。
- 正文：外部输出根 `2026-10-26_第02期_让编辑成为工作流.md`；媒体 `2026-10-26_第02期_assets/`，10 张 PNG＋1 个 GIF。
- 范围：`6236ce3..4193f55`；版本头 `v0.3.1`，程序内版本仍为 `0.2.0/dev-0.2.0`。正文按用户删节去掉了独立验证节，验证证据留内部底稿。
- 媒体文件检查：`validate_media.py` 本轮重跑通过，11 媒体全部引用，GIF `02-dock-reflow.gif` 1,600,703 字节、70 帧／7 秒；实际循环播放、知乎编辑器和手机预览仍是发布前待验项。
- 原始运行日志在本机清理备份，不在当前工作区；写作状态与证据索引以 `local/docs/ZhihuSeriesLedger.md` 为准。

## 维护方式

协调者在阶段完成或任务交接时更新本页，领域执行者回报证据并更新获准范围内的领域文档。记录日期、实现／验证／提交状态、证据入口和下一步；结果变化时修正当前条目，历史验证保持日期与范围，不以旧结果覆盖新失败。

进行中的复杂任务使用 `artifacts/agent-tasks/` 里的本机记录；共享页保留稳定里程碑与明确的未完成事项。新会话先读本页，再按任务选读领域文档与源码，不依赖私人聊天或旧会话才能工作。
