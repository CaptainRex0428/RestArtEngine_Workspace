# DevLog02 之后的引擎能力与管线审计（2026-11-18）

状态：源码与历史记录审计／讨论准备，不含新功能实现授权。引擎代码未修改，本轮未构建或运行GPU。
基线：DevLog02=cc68a1b8e6fe4a6d3cf955d2ce523043217fb7aa（2026-10-26），当前HEAD=14a6b0db35e3d0045978d1d75510ad4f9f50073b（最后提交2026-10-31）。区间83提交（含merge），250文件变化；不把行数当功能数量或效率指标。

## 背景与方法

用户希望理解近期DSH／补充模型及前期集成后的特性、管线、设计动机、收益和问题，再讨论后续开发。按实际功能审计，不从提交标题推断作者模型，也不把11月学习方案当已实现。

核对83提交、公开领域文档、当前源码、协作状态／任务／经验／11月讨论。工程当前只有Sandbox既有4个跟踪修改及Ground/Yellow/R8三个未跟踪资产；这些用户内容不代表公开基线，未读写或提交其载荷。local初始干净，main与origin/main相同。

DevLog02标签与文章冻结点不同：文章功能冻结终点4193f55，tag为cc68a1b；本次按用户所说“从DevLog2”取tag为比较基准。UndoStack、Alt拖动复制、材质草稿、Forward/Deferred、PCF/PCSS/CSM、GTAO/Contact、曝光与ACES近似映射在基线已存在，不列为此阶段新发明。第2期发布状态未确认，不改写写作底稿。

## 主要变化、原因和限制

| 领域 | 本阶段实现 | 为什么／收益 | 现有限制 |
|---|---|---|---|
| 资产身份与容器 | GUID；现代.rasset包材质/网格/缩略图；场景v2/v3引用；后续Slot/UV扩展 | 名称/路径与身份分离，共享资源、移动与重导入仍保持实例绑定，场景不重复存几何 | 无完整Texture资产/贴图导入与DCC材质图转换；旧格式仍需兼容 |
| Engine/Content | 只读Engine默认材质及Plane/Sphere/Cube/Cylinder/Cone/Torus；项目Content独立；Copy to Project新GUID | 引擎提供稳定基础资源，工程只管理自己的内容，防止改模板影响别的工程 | 引用引擎资源依赖匹配安装及固定ID；复制材质不自动改Actor绑定 |
| 内容工作流 | 类型色、网格缩略图、GPU材质球/场景缩略图、Asset Details、拖放预览；材质命中Actor/section并outline | 更接近资产→实例的可观察工作流，预览独立不消耗主GI历史 | 静态预览仍有首次GPU准备成本，不能等同于完整UE资产生态 |
| 导入与生命周期 | OBJ/FBX统一多文件入口、结果/警告；稳定GUID重导入；引用检查删除；命名Slot/section与UV0–UV3 | 源文件变化不用重建场景；按sourceKey恢复材质绑定，避免slot重排错绑 | 同名FBX材质来源不唯一时拒绝重导入；删除成功清场景Undo；无资产级Undo |
| 保存与性能 | Save Scene只存实例/引用/场景设置；Asset存载荷；Save All协调；几何版本缓存、拾取BVH、静态预览缓存 | 解决大网格每Pass哈希/展开、逐三角拾取、保存场景重写全资产导致卡顿 | 首次导入/BVH/真修改仍有同步成本；世界空间DXR变动整场重建；Save All不是跨文件事务 |
| Camera | 平台无关Pose/Lens/View统一矩阵/射线；Camera Actor；透视/正交六向；Orbit/Fly；View/Pilot；默认输出相机与Opening view | 渲染、拾取、Gizmo、光追、预览共享相机语义；只读查看与编辑操纵分开；连续手势一条Undo | 实际后端仍Windows；默认输出与编辑器书签是两个概念，需清楚呈现 |
| 四分屏 | 每格独立相机、镜头、曝光、输入和输出；激活/最大化/小窗降级 | 同时观察正交结构与透视构图，避免多个窗口抢手势 | 仅激活格DXR/GI，其他Raster；切格换ViewId重建主历史，无四套常驻光追历史 |
| 景深 | 光栅/Realtime屏幕景深；Progressive圆孔径薄透镜；焦距由FOV/传感器推导；参数可撤销保存 | 实时成本可控，参考路径正确采样孔径/遮挡；景深后绘制编辑描边 | 屏幕景深64tap/24px上限、已tone mapped颜色上display-linear混合，无法找回遮住的背景；ZWrite Off和正交/数据视图有边界 |
| 光照 | Directional/Sky/Rect/Spot/Point Actor；32可见直接灯+Sky独立累加；共享GPU契约；矩形MIS | 不再局限单默认方向光，光栅/软件射线/DXR/PT消费同一灯数据 | 非物理单位标定；Sky无HDRI；光栅矩形四点近似；普通局部直接阴影依赖软件射线，无每灯shadow atlas/clustered lighting |
| 硬件光追/GI | D3D11主渲染+同卡D3D12/DXR1.1；Progressive完整画面；Realtime间接缓冲；独立漫反射/镜面与艺术强度 | 渐进供质量参考、实时保留即时直接光响应；共享材质与灯光减少语义分叉 | 无运动重投影/成熟时域降噪，动相机清历史；跨API同步/显存成本；DXR并非完整DX12后端 |
| 管线声明 | Pass kind/name/reads/writes；生产者顺序验证；Features请求/构建/设备/当前帧状态；独立ShadowPass | 执行/诊断共用顺序，使依赖、禁用原因、GPU计时可检查，扩展不全靠大函数分支 | 静态顺序列表，非自动RenderGraph，无自动屏障/资源别名/异步调度；多数Pass仍在SceneRenderer |
| 工具与编辑器 | 深度感知描边/遮挡虚线选项、原生浮窗、底栏命令；CPU trace/GPU计时/Frame Inspector/三角统计 | 编辑反馈与数据定位更清楚，能分辨CPU/GPU/资产瓶颈和实际生效特性 | Frame Inspector为指定捕获点冻结资源，不是每draw历史或完整回放；导出元数据不能恢复整帧 |

重要提交：资产体系 d3ea6d2/fcbabd8/368fbca/9843248/ecace7c；预览2062c35/2f717b9；Engine 9d0f194/f6e3295；性能2c84e99；诊断50964d8/c9342be/5c23e42；GI b79d9bc/8c9ae9d/8119e01；生命周期eee716d；相机/景深/灯光/UV/控制台集成8f027db；Cornell合入a46432b；管线声明7f8a585；当前示例配置14a6b0d。

## 当前三种成图路径

1. 普通Forward/Deferred：阴影准备 → 光栅材质/直接光/现有环境近似 → 曝光/ACES近似映射/gamma → 屏幕景深 → 选中描边 → 捕获/显示。
2. Realtime GI：DXR间接采样/有界HDR历史/5×5几何材质引导空间滤波 → 光栅直接光与间接HDR合成 → 显示转换 → 屏幕景深/描边。没有运动矢量重投影，不能称成熟时域降噪；近镜面跳过空间模糊。
3. Progressive：DXR主射线和多跳路径/MIS/薄透镜 → 线性HDR累积 → 曝光与显示解析 → 描边。达到目标停止；并非在光栅结果上叠加反射，屏幕DOF不重复执行。主光栅阶段仍可能为深度/编辑器数据执行，显示颜色由硬件resolve覆盖。

四维需分开：PBR/NPR是着色体系；Forward/Deferred是组织；D3D11/D3D12等是API；GI/DOF/阴影是Feature。PBR已有金属度粗糙度/GGX类基础实现，不等于完整PBR资产/IBL生态；NPR尚未实现。

## 后处理与架构真实状态

- 曝光、ACES近似曲线和gamma在DevLog02就有；现在真正新增镜头效果是DOF，编辑器选择描边也是后续新增。已有GTAO/contact属于先前Deferred着色能力，不能说没有AO，也不能称新建的独立SSAO后处理Pass。
- 尚无Bloom、TAA、运动模糊、完整HDR后处理链/后处理Volume。DOF现在接在已显示转换的颜色后，虽线性化混合避免直接gamma模糊，但无法还原色调映射压缩过的HDR高光；未来若追求高光散景/Bloom/自动曝光，优先明确HDR资源和显示转换职责。
- RHI只有IRenderBackend生命周期骨架；实际SceneRenderer直连D3D11，D3D12目录服务DXR桥。没有已经接通的Vulkan/OpenGL/Linux/macOS后端，没有独立渲染线程。
- 11月RHI/材质Schema/模板API/节点/变体缓存为学习和提案，未实现；手写HLSL共享EvaluateMaterial与候选热编译已实现。材质模板目标可保留，但不能把构想列入现成功能。

## 瓶颈与下一步讨论选项（未授权实现）

建议先选近期主目标，再排投入；不同时展开RHI、节点编辑器和新画面特性。

| 目标 | 候选先后顺序 | 价值／风险 |
|---|---|---|
| 可用PBR场景制作 | Texture资产/导入与采样语义 → 材质Schema/模板/实例 → 统一各Pass材质契约 | 四UV/多Slot终于能承载真实材质；需处理sRGB/linear、法线/切线、资源生命周期和shader契约 |
| 稳定画面与后处理 | 明确HDR SceneColor与显示转换 → 后处理Pass接口 → Bloom/自动曝光等逐项实现 | 避免继续在LDR结果堆效果；需要保证Forward/Deferred/PT/预览、景深与debug数据视图一致 |
| 实时性能 | 测量CPU/同步/显存 → Mesh BLAS与实例TLAS → 视图历史/降噪 | 当前世界展开和同步是明确候选，不能未测就保证FPS；时域方案还需motion vectors/重投影/失效规则 |
| 真跨平台 | 先以D3D11落实最小资源/命令/PSO/能力接口，再选择下一后端 | 避免一次重写渲染器；接口需要承载显式同步而非照搬DX11 |
| NPR | 先定目标画面/光照模型与材质参数，再定义特有Feature | 可以共享相机/资产/几何/调试等；尚无NPR实现，不以现有选择描边冒充美术描边体系 |

我的建议：若下一目标仍是可用PBR/NPR引擎，先收敛材质/纹理数据契约，并明确HDR成图边界；下一步才选具体一个可验收切片。若用户优先迁移平台，则RHI优先级上升。当前不创建实现任务。

## 文档不一致（本轮登记，尚未批量修订）

1. local/docs/conversations/2026-11-11-rhi-material-system.md 写“无Tone mapping/SSAO”过于绝对：Scene.hlsl的DisplayColor已有ACES近似+曝光+gamma；GTAO也存在。没有的是完整后处理栈和独立SSAO后处理阶段。本文作为更正依据，不重写过去聊天。
2. docs/EditorGuide.md尾部重复旧Opening view/lighting段，矩形仅progressive的说法落后于当前LightActor实现。
3. docs/GlobalIllumination.md重复单矩形说明（约50与127行），不同阶段文字遗留。
4. Cornell README仍写4SPF/1024/8，manifest当前16SPF/65536/12，间接强度约0.99；提高样本主要降噪，增加每帧预算会影响交互，不是输运公式优化。
5. RenderFeatures的Realtime硬件阴影原因文案称传输direct shadows，与实现只传indirect矛盾；SceneEditor曝光提示顺序与DOF实际执行顺序不一致。
6. docs/Diagnostics.md部分UV检查说明及docs/Architecture.md示意保留旧字段/旧资产形式，不能据此判定当前没有UV。Engine六个内置网格目前未配UV，未来纹理工作流还需对应补齐。
7. 早期任务里的“Cornell尚未合入”“Camera还没有四分屏/DOF”“未提交”等是历史状态，已由8f027db/a46432b及后续记录覆盖。

## 证据与验证边界

- 最新本地记录：2026-11-10 Debug构建、22/22 CTest通过；完整editor-self-test在Native Content聚焦断言未通过。相关焦点代码未变支持环境竞争判断，但仍不能称最新完整Editor通过。
- 历史GI/Camera/灯光/属性专项有真实DXR dispatch和errors0记录，需按各自构建与任务读取；本轮未重跑，不把不同版本数字拼成当前一次验收。
- 当前7处Sandbox用户改动保留；引擎源码审计以HEAD为准。日志、学习和方案只在local协作库，不进入引擎库；本轮不写DevLog03文章或生成截图/GIF。

主要源码/文档：

- [渲染声明](../../../src/Renderer/Pipelines/ScenePipeline.cpp)、[Feature策略](../../../src/Renderer/RenderFeatures.cpp)、[管线说明](../../../docs/RenderPipeline.md)
- [Camera](../../../include/RestArtEngine/Camera/Camera.h)、[Camera说明](../../../docs/Camera.md)、[视口路由](../../../src/Editor/SceneEditorViewports.inl)
- [屏幕景深](../../../Shaders/Private/DepthOfField.hlsli)、[路径采样](../../../Shaders/Private/PathTracing.hlsli)、[显示转换](../../../Shaders/Private/Scene.hlsl)
- [资产格式](../../../docs/AssetFormat.md)、[导入](../../../docs/Importing.md)、[GI](../../../docs/GlobalIllumination.md)、[灯光](../../../docs/Lighting.md)、[诊断](../../../docs/Diagnostics.md)
- [材质提案](../design/MaterialTemplateSystem.md)、[学习笔记](../learning/RenderingArchitecture.md)、[经验索引](../DevelopmentExperience.md)

## 同步记录

本记录按AgentEntry讨论归档规则进入协作库main，并在收尾核对origin/main；提交号与远端状态见本次交付及Git历史。引擎仓库不新增提交。

## 逐提交核对清单

以下为DevLog02..14a6b0d全部83提交（逆时间序，含merge）；职责归纳见上文。

| Commit | 日期 | 内容 |
|---|---|---|
| 14a6b0d | 2026-10-31 | chore(samples): raise Cornell Box GI sampling and fix material reference |
| fca018a | 2026-10-31 | docs: rewrite README and illustrate every subsystem |
| f9796d3 | 2026-10-31 | fix(samples): repair malformed RayTracing_Simple materials |
| 7f8a585 | 2026-10-31 | feat(renderer): declare frame passes and feature states |
| a46432b | 2026-10-30 | merge: bring the Cornell Box sample and area lighting onto master |
| c5db70c | 2026-10-30 | docs: document camera, lighting, mesh attributes, and console workflows |
| 8f027db | 2026-10-30 | feat(engine): integrate camera, lighting, mesh attributes, and console work |
| c86a6de | 2026-10-30 | fix(editor): let floating panels extend beyond the main window |
| 638ae2e | 2026-10-30 | feat(samples): add Cornell Box path tracing scene and area lighting |
| 8119e01 | 2026-10-30 | feat(renderer): add configurable indirect diffuse intensity |
| eee716d | 2026-10-30 | feat(assets): add reimport and safe asset deletion |
| f6e3295 | 2026-10-29 | feat(assets): complete import, engine meshes and viewport material workflows |
| 769f192 | 2026-10-29 | docs(renderer): define PBR and NPR goals and clarify clipping statistics |
| b7f77fe | 2026-10-29 | chore(workspace): add optional collaboration entry and sync wrapper |
| 933e2d7 | 2026-10-29 | feat(renderer): add material depth and cull controls with 10M DXR GI validation |
| d7d2fe6 | 2026-10-29 | feat(editor): show scene and post-clipping triangle statistics |
| 2c84e99 | 2026-10-29 | perf(engine): cache static mesh geometry and accelerate viewport picking |
| dc3ceeb | 2026-10-29 | fix(editor): rename asset sources to Engine and Content |
| ff65873 | 2026-10-29 | feat(samples): use painted materials and realtime GI in Sandbox |
| 9db4815 | 2026-10-29 | fix(editor): distinguish GI activity from hardware tracing |
| dda510c | 2026-10-29 | docs(renderer): describe realtime GI modes and contribution controls |
| 8c9ae9d | 2026-10-29 | feat(renderer): add realtime GI and independent indirect lighting controls |
| eb833a6 | 2026-10-29 | test(editor): select a visible material drag fixture |
| 4f16de6 | 2026-10-29 | docs: document hardware ray tracing and progressive GI |
| b79d9bc | 2026-10-29 | feat(renderer): add progressive DXR global illumination and project settings |
| 5a5a729 | 2026-10-29 | docs: document engine diagnostics and viewport debug modes |
| 3f497f3 | 2026-10-29 | test(diagnostics): validate captured resources and editor workflows |
| 5c23e42 | 2026-10-29 | feat(editor): integrate profiler and frame inspector tools |
| c9342be | 2026-10-29 | feat(renderer): add frame capture and GPU diagnostics |
| 50964d8 | 2026-10-29 | feat(core): add bounded CPU trace profiling |
| 812c513 | 2026-10-28 | docs: align engine guides with content and asset workflows |
| 960c1e9 | 2026-10-28 | feat(editor): integrate engine assets and improve content interactions |
| 9d0f194 | 2026-10-28 | feat(assets): mount shared engine content and preserve project identities |
| 25e1c0b | 2026-10-28 | fix(renderer): isolate tool previews and resolve material identities |
| daa8859 | 2026-10-28 | docs: sync references with the .rasset pipeline and content browser |
| d87156f | 2026-10-28 | test(editor): run self-tests against a temporary project copy |
| 98af7ea | 2026-10-27 | fix(assets): keep legacy .ramat files when saving container materials |
| 2f717b9 | 2026-10-27 | feat(content): asset details window with live preview |
| 8727ffa | 2026-10-27 | test(content): rebuild the scene fixture directory each run |
| f86b357 | 2026-10-27 | feat(content): show asset names under grid thumbnails |
| 2062c35 | 2026-10-27 | feat(preview): orbitable material ball and GPU scene thumbnails |
| fdc49b5 | 2026-10-27 | docs(editor): note the live material sphere preview |
| 0f8cdac | 2026-10-27 | feat(material): GPU offscreen sphere preview in the material editor |
| 433c204 | 2026-10-27 | feat(content): grid view and scene thumbnails |
| ecace7c | 2026-10-27 | refactor(assets): rename the container extension to .rasset |
| 4e86dd3 | 2026-10-27 | feat(assets): generate and show 64px container thumbnails |
| 40c9b2a | 2026-10-27 | feat(assets): generate built-in primitives as raasset files |
| a678dba | 2026-10-27 | fix(launcher): open the project manager centred on the primary monitor |
| 9843248 | 2026-10-27 | feat(assets): static mesh assets and scene v3 mesh references |
| 5ca9841 | 2026-10-27 | feat(editor): resolve scene v2 materials from Content on load |
| 368fbca | 2026-10-27 | feat(scene): scene v2 references materials by GUID |
| fcbabd8 | 2026-10-27 | feat(assets): GUID identity and .raasset container for materials |
| 06db9db | 2026-10-27 | docs(assets): decide materials live in .raasset |
| d3ea6d2 | 2026-10-27 | feat(content): asset registry, folder browser with drag move, active scenes |
| 6a3c2b2 | 2026-10-27 | build: list HLSL sources in the solution for IDE editing |
| 6e92804 | 2026-10-27 | feat(editor): show the activity status at the top of Details |
| ecd90be | 2026-10-27 | fix(editor): share the Outliner row rect between the eye and the label |
| 773976d | 2026-10-27 | fix(ui): readable 20px eye icon with eye-shaped lens and solid pupil |
| 802c6c7 | 2026-10-27 | feat(ui): line-art visibility icon and assets/icons convention |
| 6c7771e | 2026-10-27 | fix(editor): centre the Outliner visibility icon in a fixed column |
| bae6db9 | 2026-10-27 | docs(gui): note the Outliner visibility eye row structure |
| 7c87f76 | 2026-10-27 | feat(editor): clickable visibility eye on Outliner Actor rows |
| d55b9da | 2026-10-27 | feat(editor): move key light and shadow settings into the Scene panel |
| b446f64 | 2026-10-27 | feat(boot): borderless loading window at 28% width, centred 80% editor window |
| cdff41e | 2026-10-27 | feat(editor): move actor properties to Details and leave Scene to scene-level parameters |
| cf51731 | 2026-10-27 | feat(editor): default the selection outline to the brand orange |
| 0ebaaa8 | 2026-10-27 | update scene sandbox |
| cd021a8 | 2026-10-27 | chore(test): drop unused variables flagged by C4189 |
| 98064d8 | 2026-10-27 | feat(editor): make outlining front objects an explicit outline option |
| 9b876cc | 2026-10-27 | feat(editor): offer a solid occluder intersection line instead of whole-occluder outlines |
| 40b0469 | 2026-10-27 | feat(editor): make outlining front occluders an outline option |
| 1b99b60 | 2026-10-27 | fix(editor): stop outlining the occluder in front of the selection |
| ac13f67 | 2026-10-27 | fix(editor): keep occluded outline dashed-only, drop the fill mode |
| b4de534 | 2026-10-27 | fix(editor): draw occluded outline as a dashed contour instead of a fill |
| 87dda30 | 2026-10-27 | feat(editor): depth-aware outline, dashed occluded edges and G/H toggles |
| 1fc76d4 | 2026-10-26 | feat(editor): allow a custom selection outline colour |
| 681edb5 | 2026-10-26 | feat(editor): move selection outline settings into a dedicated window |
| 2924e8f | 2026-10-26 | feat(editor): expose selection outline settings in the UI menu |
| 4f6f87f | 2026-10-26 | feat(editor): add screen-space selection outline for the viewport |
| b90f541 | 2026-10-26 | fix(premake): regenerate Rider run configurations after editor cleanup |
| 8ad6255 | 2026-10-26 | docs: limit published documentation to engine usage and architecture |
| ba7311a | 2026-10-26 | docs: clarify configuration locations and publication boundaries |
| 9239226 | 2026-10-26 | chore(repo): keep AI workflows and devlogs local |
