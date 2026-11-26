# DevLog03 审计：全局光照（GI）主线

> 只读审计记录，仅本地，不提交、不发布。审计对象是提交历史，不是工作区。
> 审计日期：2026-11-20（Asia/Shanghai）。范围：`4193f55..26aaf1f`。
> 本页给 DevLog03 的 GI 模块提供事实底稿；证据等级按 [ZhihuSeries](ZhihuSeries.md) §3.4：A＝本轮亲自运行并观察，B＝代码/文档/历史运行记录存在但本轮未运行，C＝计划。
> **本轮没有构建、没有运行引擎、没有截图、没有改任何被跟踪文件。** 所有历史运行数字都是 B；要写进正文的“现在能”必须先重跑升 A。

## 0. 口径与结论摘要

| 项 | 值 |
| --- | --- |
| 区间起点 | `4193f55`（2026-10-26，DevLog02 正文终点/标签差额提交） |
| 区间终点 | `26aaf1f`（2026-11-20 18:23，“fix(gi): repair SSGI and add software ray-traced DDGI fallback”） |
| 区间提交数 | **117**（`git rev-list --count 4193f55..26aaf1f`） |
| 其中 GI 主线提交 | **34**（功能/修复/文档/示例/项目清理，见 §1.1） |
| GI 相邻支撑提交 | 7（见 §1.2，不计入 GI 能力清单） |
| 与上期审计重叠 | GI 提交全部晚于 `daa8859`（2026-10-28，[DevelopmentChanges-AfterDevLog02](DevelopmentChanges-AfterDevLog02.md) 终点），与那 49 提交审计**零重叠**；本页可独立作为 DevLog03 GI 的逐提交清单 |
| 工作区状态 | 有未提交 GI 修复：`Shaders/Private/Scene.hlsl`、`src/Renderer/SceneRenderer.cpp`、`D3D11Rhi.cpp`、`D3D12Rhi.cpp`、`Rhi.h`、`RhiInspection.h`、`docs/GlobalIllumination.md`、Sandbox 资源。**结论一律以 `26aaf1f` 提交为准**，工作区改动不算已验证（见 §6.4） |
| 读过的快照 | `git show 26aaf1f:<path>`（文档与源码）、`git log/show/diff` 只读命令、`artifacts/` 下文本/JSON/日志名、`local/docs/tasks/` 任务记录 |

**一句话结论**：GI 在 11-19/11-20 从“只有 PathTracing”扩成**三档可配置**（PathTracing / SSGI / DDGI），实时路径追踪补上了相机与逐物体重投影降噪、多尺度空间滤波和 ReSTIR 采样层；DDGI 先做光栅投影、再修 atlas 与自动拟合、最后升级为 DXR 逐 probe 光线追踪并带软件回退；SSGI 从单 Pass 改成 trace/composite 两 Pass 并修掉自反馈。实现已经全部提交，但**四项扩展只有任务目录里的 20 张 PNG 和任务记录里的数字，仓库内没有对应原始日志/exit-code/validation JSON**；`artifacts/` 里的 GI 运行证据都停在 10-29/10-30/10-31 的旧构建。因此本期正文的 GI 质量与实时画面**目前只有 B**，需要等用户手上这轮 GI 修复落定后重跑统一升 A。

### 证据总判定（先给结论）

| 断言 | 当前等级 | 说明 |
| --- | --- | --- |
| 三档 GI 的模式、参数、JSON 字段、UI 名称、后端门槛 | **B（源码确认）** | 以 `26aaf1f` 源码与 `docs/GlobalIllumination.md` 交叉核对，见 §2、§3 |
| SSGI/DDGI/ReSTIR 在 11-20 的某个构建上跑过 GPU 并通过 validation 0 | **B（历史记录）** | 任务记录 + 20 张 PNG；无原始日志、无本机可复现命令记录 |
| Progressive DXR GI、Realtime 贡献开关、颜色溢出、Cornell 矩形光 | **B（历史运行，证据较全）** | `artifacts/gi*`、`cornell-*` 有 JSON/日志/指标，但都是旧构建 |
| 当前 HEAD（或用户修复后）画面质量、稳定性、性能 | **C/未验证** | 没有本轮运行；性能数字均为 10-29 旧构建 |
| 连续运动/拖影、ReSTIR vs Uniform、DDGI 泄漏基准 | **缺失** | 无录屏、无对照基准 |

## 1. 逐提交表

### 1.1 GI 主线提交（34 个，按时间）

类型缩写：**功**＝运行时功能，**修**＝修复，**档**＝文档，**例**＝示例/工程，**清**＝项目清理。  
“是否被后续替换”只描述 GI 语义；被后续提交扩展但仍保留为可选项的不算替换。

| 提交 | 日期 | 类型 | 一句话变化 | 是否被后续替换 |
| --- | --- | --- | --- | --- |
| `b79d9bc` | 10-29 | 功 | 首次加入 Progressive DXR GI：路径追踪、项目配置、GPU 自测（混合 D3D11+DXR 通道） | 否；保留为 PathTracing/Progressive，后续 `8c9ae9d` 扩展出 Realtime |
| `4f16de6` | 10-29 | 档 | 公开文档记录硬件光追与渐进式 GI（GlobalIllumination/HardwareRayTracing 等 9 文件） | 被后续文档扩写覆盖部分段落，见 §2.7 |
| `8c9ae9d` | 10-29 | 功 | 拆出“算法 method”与“更新模式 mode”，加入 Realtime 间接光输出、独立 indirect diffuse/specular 贡献开关、连续采样与有界历史 | 否；Realtime 保留，后由 `ba44bad/23bab37/1a3dc57` 补时域降噪 |
| `dda510c` | 10-29 | 档 | 文档说明 Realtime 模式、共享间接光消费者、资源成本与 Windows/DXR 边界 | 部分段落后仍有效，部分被 11-20 文档改写覆盖 |
| `9db4815` | 10-29 | 修/功 | 编辑器把“GI 实际生效状态”与“硬件光追活跃”分开显示；补颜色溢出 GPU 回读检查（双向传递、零通道吸收、着色金属反射） | 否；状态入口保留 |
| `ff65873` | 10-29 | 例 | Sandbox 改用涂装材质并默认请求 Realtime GI（写入 `Sandbox.raproject`） | 资产在后续工作区被用户继续修改；`26aaf1f` 后不再是最新样例值 |
| `638ae2e` | 10-30 | 例 | 新增 `Projects/PathTracing_CornellBox`：红绿墙＋顶灯＋三金属球，单矩形发光面＋面积/BRDF MIS，含场景校验与 GPU 回归 | 否；中间被 `5cafa4b` 删除、`86dab47` 恢复 |
| `8119e01` | 10-30 | 功 | 新增 `indirectDiffuseIntensity`（0–8，默认 1）：艺术增益只作用在首个接收面的漫反射分量一次，PDF 同步；实时/渐进一致 | 否；保留 |
| `c5db70c` | 10-30 | 档 | 文档补相机/灯光/网格属性/控制台，顺带更新 GI 与硬件光追对矩形灯、相机、环境的表述 | 部分段落后来过时（见 §2.7） |
| `14a6b0d` | 10-31 | 例 | Cornell Box 提高 GI 采样：16 spp/帧、65536 目标、12 次表面着色、diffuse 0.99；修银球材质引用 | 否；`86dab47` 恢复的工程保留这组值 |
| `f9796d3` | 10-31 | 修/例 | 修复 `RayTracing_Simple` 五个非法 JSON 材质（roughness 后多引号） | 是；该示例随后被 `86dab47` 整体删除，此修复只为过渡状态 |
| `fca018a` | 10-31 | 档 | README 重写并给每个子系统加首图；新增 `docs/images/gi-compare.png`，GI 文档 22 行改动 | 否；`gi-compare.png` 是当前公开文档配图 |
| `1bd8e58` | 11-19 | 功 | GI 设置契约：`GlobalIlluminationDenoiser`、`GlobalIlluminationMotionVectors`、`denoiseIterations`，JSON 读写/校验/UI；默认保持旧 Spatial | 否；为 M1 铺路，行为由 `ba44bad` 才生效 |
| `ba44bad` | 11-20 | 功 | 实时 PT 相机重投影 temporal+spatial 降噪：`DenoiseConstants`、历史图、上一帧 ViewProjection、法线/深度拒绝、邻域 clamp、状态上报有效降噪/运动向量 | 否；`CameraOnly` 仍可选，后由 `23bab37` 增加 PerObject |
| `23bab37` | 11-20 | 功 | 逐物体运动向量：`RayTriangle` 增加上一帧世界位置，主表面上一帧位置写入 u7；历史键不再因 Actor 变换整帧重置 | 否；保留 |
| `1a3dc57` | 11-20 | 功 | `denoiseIterations` 从“未使用配置”变成 1–4 轮多尺度 5×5 tap（粗尺度权重衰减） | 否；保留 |
| `1768b21` | 11-20 | 功 | 首版 SSGI：`GlobalIlluminationMethod::ScreenSpace`，Deferred 内联屏幕追踪，采样上一帧颜色副本；D3D11/native D3D12 光栅共用 | **是**；被 `fa5667f` 拆成 trace/composite，数据源再被 `26aaf1f` 改为当前帧 direct-lit 副本 |
| `f52eb1f` | 11-20 | 功 | 首版 DDGI：`ProbeGrid`，1024×32 RGBA16F probe atlas ping-pong，`PSProbeUpdate` 从 G-buffer 投影更新，Deferred 三线性采样 8 probe | **是（部分）**；投影式单像素更新被 `fa5667f`/`b97f305`/`f94b313`/`26aaf1f` 逐层替换 |
| `9dd0639` | 11-20 | 功 | ReSTIR 采样层首版：`Uniform/Restir`，direct/indirect reservoir、候选数；打包进 `traceOptions` 保持 208B 常量 | **是（部分）**；首版无 reservoir 历史，被 `e7defe8`/`e1591f1` 补历史、`0d93c0a` 补空间 reuse |
| `e7defe8` | 11-20 | 功 | ReSTIR indirect reservoir 时域历史（u8 写/t14 读，上一帧世界位置＋ViewProjection 重投影，20% 混合） | 否；保留 |
| `e1591f1` | 11-20 | 功 | ReSTIR direct reservoir 时域历史（t15/u9），并把重建资源声明提前以允许 PathTracing.hlsli 访问 | 否；保留 |
| `0d93c0a` | 11-20 | 功 | `restirSpatialReuse`：direct/indirect 平均上一帧 3×3 邻域估计（20%），非正式 reservoir 合并 | 否；保留，但仍是近似（见 §6） |
| `fa5667f` | 11-20 | 修 | SSGI 拆 trace/composite：trace 采样 direct-lit 历史副本消除自反馈；composite 做 3×3 几何滤波＋时域 clamp/0.1 混合＋albedo 调制＋emitter 拒绝。DDGI probe 对齐世界格点、3×3 屏幕 footprint、置信度 alpha | 否；但其 SSGI 数据源（上一帧 direct-lit 历史）被 `26aaf1f` 改为当前帧 direct-lit 当前副本 |
| `b97f305` | 11-20 | 修 | DDGI ProbeUpdate 改用 1024×32 atlas 专用 viewport（此前沿用 scene viewport，atlas 大半没写，表现像 DDGI 完全无效）；新增 `probeAutoFit` 默认开启，按可见网格包围盒推导 center/spacing | 否；保留 |
| `9237cd3` | 11-20 | 功 | 新增 debug view 11（GI indirect）与 12（DDGI probe 可视化）；`GiDebugOverlay` pass、probe debug VS/PS、`--debug-view` CLI | 否；视图保留，标记形态后改（见 §1.3） |
| `f94b313` | 11-20 | 功 | 完整 DXR DDGI：`HardwareRayTracing` 逐 probe 追踪（`probeRayCount` 1–32，默认 16），输出 irradiance＋mean/mean² hit distance atlas，hysteresis、view/epoch 重置；Deferred 用 Chebyshev visibility 加权 | 否；保留，strict D3D11 保留 fallback |
| `3733d68` | 11-20 | 修 | 在 DXR-capable 后端关闭硬件光追时，DDGI 由“静默跑旧光栅投影 fallback”改为报告不可用并提示开启硬件光追 | **是**；该 UX 被 `26aaf1f` 反转：改为运行新的软件光追 fallback，并用 `Software ray-traced DDGI` 明确标注 |
| `4e9a8dc` | 11-20 | 修 | probe debug 标记改成小圆点：修正 NDC 偏移按视口宽高比，尺寸减小，去掉着色球 PS | **是（形态）**；HEAD 为 2D 圆点 billboard，工作区未提交版改为真实球体实例（未验证） |
| `2e6fb59` | 11-20 | 修 | GI probes 视图不再跳过 DDGI 间接光贡献，切视图不丢间接光，probe 点叠加其上 | 否；保留 |
| `79511b8` | 11-20 | 档 | 项目设置提示文案说明“哪些 GI 方法需要硬件光追” | **是**；同提示随后被 `26aaf1f` 重写为软件 fallback 语义 |
| `5cafa4b` | 11-20 | 清 | 删除 `Projects/PathTracing_CornellBox` 并从 README/Editor/Lighting/GI 文档移除引用 | **是**；被下一个提交 `86dab47` 反转 |
| `9dbdc7b` | 11-20 | 档/清 | 文档去掉 Cornell Box 引用 | **是**；被 `86dab47` 恢复引用 |
| `86dab47` | 11-20 | 清/档 | 纠正上一步：恢复 `PathTracing_CornellBox`，删除已不需要的 `RayTracing_Simple`；README/EditorGuide/GI/Lighting 引用同步 | 否；当前工程集合为 `Sandbox`＋`PathTracing_CornellBox` |
| `26aaf1f` | 11-20 | 修 | SSGI 修复：trace 改采样当前帧 direct-lit 副本、composite 补 albedo 绑定、GI indirect 视图保留 direct、厚度加 `0.5×radius` 下限、去掉错误法线拒绝。DDGI 无 DXR 时改为软件光追 fallback（每 probe 8 方向、最多 8 步屏幕空间 march，采样当前 direct-lit color），native D3D12 光栅与 strict D3D11 均可用 | 否；HEAD 最终状态（工作区另有未提交后续，见 §6.4） |

### 1.2 支撑/相邻提交（未计入 GI 主线能力）

| 提交 | 日期 | 为什么相邻 | 对 GI 的作用 |
| --- | --- | --- | --- |
| `6a243b2` | 11-19 | 原生 D3D12 后端与帧检查 | 提供 native D3D12 光栅/DXR 运行环境；是 DDGI 软件 fallback 能跑在 native raster 的前提 |
| `c017ff8` | 11-19 | 把 DXR 跑在纯 D3D12 后端（复用 device/queue） | 让 native D3D12 也能做 PathTracing/DDGI 逐 probe 追踪；`ImportedTexture`、间接光纹理由光照采样 |
| `64a7c97` | 11-19 | 修 native DXR 在编辑器视口子矩形的 `(0,0)` 复制错位 | 硬件预览/Realtime GI 在视口内正确落位；GI 画面位置验收依赖它 |
| `7f8a585` | 10-31 | 声明式 Pass 图＋RenderFeatures 三层状态 | SSGI/DDGI/GiDebugOverlay pass 与 feature 状态都挂在这次建立的骨架上 |
| `933e2d7` | 10-29 | 材质 Cull/ZTest/ZWrite＋10M 三角形 DXR GI 验证 | GI 的“接收面材质深度状态”门槛与一千万三角形规模证据来源；本身属材质/规模模块 |
| `8f027db` | 10-30 | 集成相机、灯光、网格属性、控制台（含 PathTracing/矩形光） | Cornell 矩形光、相机、GI 消费端在主线的一次大集成 |
| `a46432b` | 10-30 | 把 Cornell 示例与面积光合入 master | 工程与 GI 集成的合并点，无独立 GI 能力 |

（阴影 `eaf4193/8bbd1c9`、抗锯齿 `b142549` 属于其他模块；GI 只沿用其光栅直接光/阴影结果，不列为本表。）

### 1.3 被后续替换的中间方案（写正文时不要写成现状）

| 中间方案 | 提交 | 被谁替换 | 现状 |
| --- | --- | --- | --- |
| SSGI 单 Pass、在 Deferred lighting 内联屏幕追踪、采样上一帧颜色 | `1768b21` | `fa5667f` 拆 trace/composite；`26aaf1f` 改采样当前帧 direct-lit 副本 | 单 Pass 逻辑已不存在 |
| DDGI `PSProbeUpdate` 单像素投影（一个 probe 只抄一个可见像素/3×3 附近） | `f52eb1f` | `fa5667f` 3×3 footprint＋格点对齐；`b97f305` atlas viewport＋auto-fit；`f94b313` DXR 逐 probe；`26aaf1f` 软件多方向 tracer | 单像素投影已被替换；DXR 不可用时运行的是“软件光追 fallback”而不是旧投影 |
| DDGI 在 DXR-capable 后端关闭硬件光追时报告“不可用、请开启硬件光追” | `3733d68` | `26aaf1f` 改为运行软件光追 fallback，并用状态字符串区分 | 回退策略两次反转；最终选择“可跑但明确标注近似” |
| ReSTIR 首版无 reservoir 历史（提交说明写着 temporal/spatial reuse 属 future work） | `9dd0639` | `e7defe8`（indirect 历史）＋`e1591f1`（direct 历史）＋`0d93c0a`（空间 reuse） | 已有 t14/t15/u8/u9 历史，但空间 reuse 仍是邻域平均 |
| probe debug 着色球 billboard → 平面圆点 | `9237cd3`→`4e9a8dc` | HEAD 为圆点；工作区未提交版改为 Engine Sphere 实例化＋法线光照 | 正文若写 debug 标记，只能写 HEAD 的“小圆点”，不能写工作区球体 |
| `79511b8` 的“DXR-capable 后端 DDGI 报不可用”提示 | `79511b8` | `26aaf1f` 重写提示为“硬件关时跑软件光追” | UI 文案已换 |
| `5cafa4b`/`9dbdc7b` 删除 Cornell Box 示例与文档引用 | `5cafa4b`/`9dbdc7b` | `86dab47` 恢复工程、删除 RayTracing_Simple | 示例最终存在；`f9796d3` 对 RayTracing_Simple 的修复已被删除 |
| 实时路径追踪只有 5×5 空间滤波 | `8c9ae9d` | `ba44bad` 增加相机重投影；`23bab37` 逐物体；`1a3dc57` 多尺度 | `Spatial` 仍是默认档，不是被删实现 |
| 相机重投影（CameraOnly） | `ba44bad` | `23bab37` 增加 PerObject；`Automatic` 在 temporal 下解析为 PerObject | CameraOnly/PerObject/Automatic 三个选项都在 |
| 16 spp/65536/12 bounces 的 Cornell 参数 | `14a6b0d` | 工程被删又恢复，参数保留；工程 README 仍是旧的 4/1024/8 | README 与 `.raproject` 不一致（见 §6.2） |

## 2. 最终行为（以 `26aaf1f` 为准）

### 2.1 编辑器里能选到的 GI 模式

入口：`Project → Project Settings... → Rendering`（F3）→ `GI method` 下拉。列表字符串就是 UI 事实：

- `Disabled`
- `Path tracing`
- `Screen space (SSGI)`
- `Probe grid (DDGI)`

`GI mode`（仅 Path tracing 可编辑）：`Progressive accumulation` / `Realtime`。  
`Sampling`（仅 Path tracing＋Realtime）：`Uniform (all lights)` / `ReSTIR reservoirs`。  
`Denoiser`（仅 Path tracing＋Realtime）：`Off` / `Spatial (5x5)` / `Temporal + spatial`。  
`Motion vectors`：`Camera only` / `Per object` / `Automatic`。  
项目 JSON 的 `method` 值为 `disabled` / `pathTracing` / `screenSpace` / `probeGrid`；`sampling` 为 `uniform` / `restir`。

| 模式 | 需要什么后端/硬件 | 更新模式 | 谁消费 | 关键参数 | 调试视图 |
| --- | --- | --- | --- | --- | --- |
| Path tracing | **必须硬件光追**：native D3D12 或 D3D11+DXR；strict D3D11 不可用；需 DXR 1.1/SM 6.5/DXC | Progressive 或 Realtime | Progressive 输出完整画面；Realtime 输出线性 HDR 间接光，Forward/Deferred 各自合成 | `samplesPerFrame`(1–16)、`targetSamples`/`History samples`(1–65536)、`maxBounces`(1–12)、两贡献开关、`indirectDiffuseIntensity`(0–8)、denoiser/motion/iterations、ReSTIR 字段 | 11（GI indirect，Realtime） |
| Screen space (SSGI) | **不需要 DXR**；**只支持 Deferred**；只在编辑器/离屏场景目标启用；本帧硬件光追实际运行时 SSGI 被跳过 | 固定 Realtime | SSGI composite 在 Deferred lighting 之后写回 SceneColor | `screenSpaceSteps`(1–32，默认 8)、`screenSpaceRadius`(默认 2.0，UI 0.05–20)、`screenSpaceThickness`(默认 0.2，运行时最低 `0.5×max(radius,0.5)`) | 11（GI indirect） |
| Probe grid (DDGI) | **只支持 Deferred**；只在编辑器/离屏目标启用；DXR 后端逐 probe 光追（native/hybrid）；无硬件光追（硬件关 / strict D3D11 / 非 DXR 适配器）走**软件光追 fallback** | 固定 Realtime | ProbeUpdate 写 atlas（DXR 时由 HardwareTransport 写），Deferred lighting 采样上一版 atlas | `probeGridX/Y/Z`(2–32，默认 16/8/16)、`probeSpacing`(UI 0.1–20，默认 1.0)、`probeHysteresis`(0–1，默认 0.95)、`probeAutoFit`(默认 true)、`probeRayCount`(1–32，默认 16，仅 DXR 路径有含义) | 11（GI indirect：probe 辐照度×albedo）、12（GI probes：场景叠加 probe 标记，仍执行 probe update） |

另有：GI 工具栏状态入口显示实际生效模式、暂停/不可用与原因；`Restart accumulation` 清 GI 历史。

### 2.2 参数与默认值（写文章可直接引用的 JSON 段）

`rendering.globalIllumination` 全部字段（`26aaf1f` 的 `docs/GlobalIllumination.md` §项目格式与验证入口）：

```json
{
  "method": "pathTracing",
  "mode": "realtime",
  "indirectDiffuse": true,
  "indirectSpecular": true,
  "indirectDiffuseIntensity": 1.0,
  "samplesPerFrame": 1,
  "targetSamples": 256,
  "maxBounces": 4,
  "denoiser": "temporalSpatial",
  "motionVectors": "cameraOnly",
  "denoiseIterations": 2,
  "screenSpaceSteps": 8,
  "screenSpaceRadius": 2.0,
  "screenSpaceThickness": 0.2,
  "probeGridX": 16, "probeGridY": 8, "probeGridZ": 16,
  "probeSpacing": 1.0,
  "probeHysteresis": 0.95,
  "probeAutoFit": true,
  "probeRayCount": 16,
  "sampling": "restir",
  "restirCandidates": 4,
  "restirDirect": true,
  "restirIndirect": true,
  "restirSpatialReuse": true
}
```

缺失时默认：method=disabled、mode=progressive、两贡献=true、intensity=1、denoiser=spatial、motionVectors=automatic、denoiseIterations=2、SSGI 8/2.0/0.2、DDGI 16/8/16/1.0/0.95/autoFit=true/16 rays、sampling=uniform/4/true/true/true。非法枚举、越界整数、NaN/Inf、错误类型一律拒绝并保留原 manifest；**设备能力不改写项目请求值**（`requested` 与 `effective` 分开）。

### 2.3 调试视图

视口 debug combo（`src/Editor/SceneEditor.cpp:3677`）共 13 项，索引 11/12 为 GI：

- `GI indirect`（`debugView == 11`）：只显示当前 GI 的间接贡献。SSGI 照常跑 trace/composite 但 composite 只输出 indirect；DDGI 输出 `probe 辐照度 × 接收面 albedo`；Path tracing Realtime 显示硬件间接图并应用曝光；GI 关闭输出黑色。SSGI trace 仍需要 direct-lit 当前副本（`PSDeferred` 在 debug 11 下保留 direct 输出）。
- `GI probes`（`debugView == 12`）：正常场景叠加每个 DDGI probe 的标记，颜色来自 atlas 辐照度，青色表示 probe 尚未有效更新（HEAD 是圆点 billboard）；该视图仍执行 DDGI probe update 保持 atlas 活跃。`2e6fb59` 起不再跳过 DDGI 间接光贡献。

无编辑器时可用 `--debug-view 11|12 --frames N --capture-temp` 复现，参数在项目加载后应用。

### 2.4 状态与 UI 文案（写正文引用“实际生效”时注意）

- `GI requested: ...` / `GI effective: ...`
- `GI effective mode: Realtime deferred SSGI (previous-frame color)`（此文案已过时，见 §2.7）
- `GI effective mode: Realtime DDGI probe atlas (previous-frame update)`
- `GI denoiser: Off|Spatial (5x5)|Temporal + spatial`；`GI motion vectors: Camera only|Per object|Automatic`
- DDGI 状态原因：`Ray-traced DDGI ...`（DXR 实际运行）或 `Software ray-traced DDGI ...`（无 DXR/硬件关）＋有效 probe spacing＋是否 auto-fit；`Ray-traced DDGI probe atlas active (...)` 出现在硬件通道消息里。
- ReSTIR 状态：`Sampling: ReSTIR (direct on, indirect on, candidates 4)`（硬件通道消息）。
- SSGI 状态：`Realtime screen-space GI consumes the deferred G-buffer and the previous frame's lit colour.`（同样过时，见 §2.7）
- 不可用原因示例：`SSGI requires the Deferred raster path.` / `DDGI requires the Deferred raster path.` / `SSGI currently requires the editor/offscreen scene target.` / `Hardware ray tracing resolved this frame; screen-space GI is skipped.`

### 2.5 源码入口（`26aaf1f`，文件＋行号）

| 位置 | 内容 |
| --- | --- |
| `include/RestArtEngine/Renderer/GlobalIllumination.h:8–23` | `GlobalIlluminationMethod`(Disabled/PathTracing/ScreenSpace/ProbeGrid)、`Mode`、`Denoiser`、`MotionVectors`、`Sampling` 枚举 |
| `include/RestArtEngine/Renderer/GlobalIllumination.h:43–87` | `GlobalIlluminationSettings` 全字段与上限常量（`kGiMax*`） |
| `include/RestArtEngine/Renderer/GlobalIllumination.h:89–102` | `GlobalIlluminationStatus`（requested/effective/mode/denoiser/motion/reason） |
| `src/Renderer/SceneRenderer.cpp:2029–2110` | 每帧 GI 判定：`realtimeGiRequested`、`hardwareTransport`、`hardwareProbeGi`、`rasterProbeGi`、`screenSpaceGi`、`probeGridGi`、`giDebugProbes`，以及 DDGI/SSGI 的 `giStatus.reason` |
| `src/Renderer/SceneRenderer.cpp:2148–2246` | `ProbeConstants` 打包、`probeAutoFit` 场景包围盒拟合、非 auto-fit 的格点对齐、debug probe 顶点生成 |
| `src/Renderer/SceneRenderer.cpp:2511–2543` | SSGI trace（复制 direct-lit 当前副本）与 composite（绑定 albedo/raw/history，写回并交换历史） |
| `src/Renderer/SceneRenderer.cpp:2544–2560` | DDGI ProbeUpdate：**显式设置 1024×32 atlas viewport**，再恢复 scene viewport，交换 atlas |
| `src/Renderer/SceneRenderer.cpp:2660–2678` | `GiDebugOverlay` pass：读 SceneDepth＋probe atlas，画到 SceneColor |
| `src/Renderer/SceneRenderer.cpp:2910–2944` | `globalIlluminationStatus()`：SSGI/DDGI 的 effective/reason，`Ray-traced DDGI` vs `Software ray-traced DDGI` 判定 |
| `src/Renderer/RenderFeatures.cpp:130–224` | 硬件光追分层判定与 `PathTracingGI`/`RealtimeGI`/`ScreenSpaceGI`/`ProbeGridGI` 状态 |
| `src/Renderer/Pipelines/ScenePipeline.cpp:127–143,185–189` | SSGI trace/composite、DDGI probe update、GiDebugOverlay 的 pass 顺序与资源边 |
| `src/Renderer/D3D12/HardwareRayTracing.cpp:1041–1070` | DXR 能力入口：同适配器 DX12 设备、DXR 1.1 tier、SM 6.5、UAV 格式 |
| `src/Renderer/D3D12/HardwareRayTracing.cpp:1493–1502,1523–1580,1692–1730` | probe/ReSTIR 常量打包、1024×32 atlas 创建、probe dispatch 与 history 回读 |
| `src/Renderer/D3D12/HardwareRayTracing.cpp:1797–1838` | `Hardware DDGI`/`ReSTIR`/`Denoiser` 状态与消息 |
| `Shaders/Private/Scene.hlsl:72–96` | `GlobalIlluminationConstants`(b6, 112B)、`ProbeConstants`(b9, 48B) |
| `Shaders/Private/Scene.hlsl:780–855` | `ScreenSpaceTrace`＋`PSScreenSpaceGi`（世界空间步进、厚度下限、亮度拒绝） |
| `Shaders/Private/Scene.hlsl:857–925` | `PSScreenSpaceGiComposite`：3×3 几何加权、时域 clamp/0.1 混合、albedo 调制、debug 11 只输出 indirect |
| `Shaders/Private/Scene.hlsl:927–966` | `ProbeIrradiance`：8 probe 三线性＋置信度；DXR 路径再乘 Chebyshev visibility/hit-ratio |
| `Shaders/Private/Scene.hlsl:968–1066` | `SoftwareProbeTrace`（8 方向×≤8 步屏幕 march）与 `PSProbeUpdate`（atlas 映射、3×3 footprint、hysteresis、`w>2.5` 走软件路径） |
| `Shaders/Private/Scene.hlsl:1068–1111` | `VSProbeDebug`/`PSProbeDebug`（HEAD 为 billboard 圆点） |
| `Shaders/Private/Scene.hlsl:1114–1146` | `PSDeferred`：debug 11、probe 辐照度叠加消费者 |
| `Shaders/Private/HardwareRayTracing.hlsl:9–59` | ProbeConstants(b9)、DenoiseConstants(b8) |
| `Shaders/Private/HardwareRayTracing.hlsl:61–171` | `ResolveRealtimeGi`：5×5 空间/多尺度、temporal 重投影、几何历史写入 |
| `Shaders/Private/HardwareRayTracing.hlsl:178–245` | `ResolveProbeAtlas`：逐 probe Fibonacci 方向、命中 direct+area light、hysteresis、depth moments |
| `Shaders/Private/HardwareRayTracing.hlsl:269–320` | ReSTIR 间接 reservoir 选择/历史混合 |
| `Shaders/Private/PathTracing.hlsli:307,337–419,539–542` | `PathDirectLight`、`PathDirectLightReservoir`（候选/校正/时域 20%）、采样层分支 |
| `src/Editor/ProjectSettings.cpp:150` | 硬件光追提示（哪些 GI 方法需要硬件） |
| `src/Editor/ProjectSettings.cpp:180–227` | `GI method` 下拉、SSGI/DDGI 参数与提示 |
| `src/Editor/ProjectSettings.cpp:228–306` | `GI mode`、贡献、intensity、samples/history/bounces、Sampling/ReSTIR、Denoiser/Motion/Iterations |
| `src/Editor/ProjectSettings.cpp:308–351` | `GI requested/effective` 状态显示 |
| `src/Editor/SceneEditor.cpp:3677–3678,3781–3782` | debug combo 13 项与 11/12 图例 |
| `src/Project/Project.cpp:60–107,162–250` | GI 字段解析/校验（枚举、范围、非法值拒绝、旧工程缺省） |

### 2.6 最终边界（代码与文档一致的部分）

- SSGI/DDGI 只跑 Deferred，且只跑编辑器/离屏场景目标（runtime swapchain 路径未启用）；Forward 报告不可用。
- 本帧硬件光追实际传输时，SSGI/DDGI 被跳过（`hardwareTransport` 为真 → SSGI/DDGI 状态 `BlockedByDependency`）。
- DDGI 首帧没有有效 atlas，第二帧开始贡献；DXR 路径与软件路径共用同一份 1024×32 RGBA16F irradiance atlas（DXR 另有 depth atlas）。
- ReSTIR 只作用于 Path tracing Realtime；SSGI/DDGI 不受影响。ReSTIR 不是严格无偏（direct 乘灯数校正、indirect 按亮度选样本、spatial reuse 只是邻域平均）。
- 无透明/发光材质、无体积散射、无环境重要性采样、无神经网络降噪；Vulkan/OpenGL/Linux/macOS GI 未实现；DXR 主射线要求可见材质 ZTest Less/LessEqual 且 ZWrite On，否则 GI 报告不可用并保留请求。
- 资源：每像素约 60B（4K≈475 MiB，不含加速结构/上传缓冲/光栅目标），这是文档估算，不是本轮测量。

## 3. 三档实现路径差异与“光追能力判定”

### 3.1 三档差异（一句话版本）

| 维度 | Path tracing（DXR） | Screen space（SSGI） | Probe grid（DDGI） |
| --- | --- | --- | --- |
| 光传输 | 逐像素/逐样本 DXR 路径积分，支持多次反弹 | 屏幕空间世界坐标 march，只对可见表面一次性间接近似 | probe 体积采样：每 probe 一组方向光线/屏幕 step，再三线性插值 |
| 数据来源 | BLAS/TLAS＋场景材质＋灯光/环境 | G-buffer position/normal＋当前帧 direct-lit 颜色副本 | DXR：逐 probe ray；无 DXR：position buffer 的屏幕空间 march；atlas 上一帧历史 |
| 时域 | 相机＋逐物体运动向量重投影，邻域 clamp；历史键排除相机/Actor 变换 | 上一帧 indirect 历史＋上一帧 ViewProjection 重投影，0.1 当前帧权重；无逐物体运动向量 | hysteresis 混合 atlas（默认 0.95），view/epoch 变化重置；DXR history 同样 |
| 输出/消费 | Progressive 完整画面；Realtime 线性 HDR 间接光给 Forward/Deferred | 在 Deferred lighting 之后把 indirect 加回 SceneColor（display-space 合成） | Deferred lighting 采样 atlas，乘接收面 albedo；indirect specular 不参与 |
| 硬件门槛 | DXR 1.1＋SM 6.5＋DXC＋深度状态兼容 | 无 DXR 要求 | DXR 可选；没有时软件 fallback |
| 主要代价 | 每帧采样预算、历史重建、60B/px | 屏幕外信息缺失、自反馈风险、display-space 非 HDR | atlas 分辨率/probe 数固定、probe 泄漏/噪声、软件 fallback 更慢更近似 |
| 当前验证状态 | 历史 B（Progressive/Realtime 均有 10-29/10-30 证据） | 历史 B（11-20 任务截图，非本轮） | 历史 B（同上） |

### 3.2 能力判定链（写“为什么某个模式不生效”时的正确顺序）

1. **后端请求**：项目 `backendPreference` 为 `auto`/`d3d11` 时 strict D3D11 不初始化 DXR；`d3d11Dxr` 走混合 bridge；`d3d12` 走 native DXR。`ProjectSettingsRules` 只允许在 native D3D12/混合后端请求硬件光追。
2. **设备/管线能力**（`HardwareRayTracing::initialize`）：同适配器 DX12 设备 → `D3D12_FEATURE_DATA_D3D12_OPTIONS5.RaytracingTier >= 1.1` → SM 6.5 → 输出格式 UAV 支持 → DXC 编译管线。失败保留原因，不重写项目请求。
3. **每帧传输条件**（`SceneRenderer`）：主诊断场景＋可见材质深度状态兼容＋后端允许＋`settings.hardwareRayTracing`＋`hardwarePipelineReady`＋`supported()`＋本帧未运行失败 ⇒ `hardwareTransport`。
4. **feature 状态**（`RenderFeatures`）：build→backend→device→pipeline→frame preconditions 逐层报告；GI 的四个 feature 由 `globalIllumination.method/mode` 与 `hardwareActive` 推导。
5. **GI 实效**：PathTracing 需要 `hardwareActive`；SSGI 需要 Deferred＋编辑器/离屏＋本帧无硬件传输；DDGI 需要 Deferred＋编辑器/离屏，DXR 路径需要 `hardwareTransport`，否则走光栅 ProbeUpdate（`probeData.parameters.w = 3` → `SoftwareProbeTrace`）。
6. **报告**：`requested`/`effective` 与 `reason` 同时保留；DDGI 用状态消息里的 `Ray-traced DDGI` / `Software ray-traced DDGI` 区分实际路径。

### 3.3 同帧互斥/降级规则

- 硬件传输实际运行 ⇒ SSGI/DDGI 本帧跳过（避免和 DXR 整幅图像重复/冲突）；GI 的 PathTracing Realtime 与硬件预览互斥（`Realtime` 时独立 ray-traced shadows 被禁用并保留偏好）。
- DXR-capable 后端但硬件光追关闭：SSGI 可跑；DDGI 跑软件光追 fallback（`26aaf1f` 起），状态明确标注。
- DDGI 的 DXR 路径不替换光栅 SceneColor，只发布 probe atlas；硬件预览整幅替换时才走 `HardwareResolve`。
- `Automatic` 运动向量在 temporal 降噪生效时解析为 PerObject（`HardwareRayTracing.cpp:1792–1795`），否则 CameraOnly；`GlobalIlluminationStatus` 报告 effective 值。

## 4. 现有证据清点

### 4.1 `artifacts/` 历史目录（全部是 2026-10-29～10-31 旧构建，B）

| 目录 | 关键文件 | 能证明 | 不能证明 |
| --- | --- | --- | --- |
| `artifacts/gi/` | `commit-gi/gi-report.json`（RTX 5060，182 dispatches，validationErrors 0，收敛/墙色互染/GGX/历史重置/Forward-Deferred/Shader 回滚 checks；`diffuseRedBlueTransfer≈0.0154`，`floorMae1To256≈0.0724`）；`commit-source/`、`commit-build/`、`install.log` | 10-29 那个 build 的 Progressive DXR GI 与颜色传递、历史规则跑过 | 当前 HEAD、Realtime 扩展、SSGI/DDGI/ReSTIR |
| `artifacts/gi-realtime/` | `commit-gi.log`（18 条 PASS，`dispatches=781, graphics errors=0`）；`candidate.json`（21 文件清单＋测试夹具）；`delivery.json` | 10-29 的 Realtime 间接光、贡献开关、相机/物体运动重置、Forward/Deferred 消费、视口裁剪、Shader 回滚 | 时域降噪/运动向量（11-20 才有） |
| `artifacts/gi-colour-transfer/` | `candidate-gi/gi-report.json`（7678B）、`candidate-gi.log`、`candidate-hardware-rt/`、`project-settings-ui.txt` | 10-29 的颜色互染 GPU 回读与配置 UI 证据 | 之后任何修改 |
| `artifacts/gi-paint-tuning/` | `changes.json`、`baseline.json`、`painted-direct.log`、`painted-gi.log`、`captures/` | Sandbox 涂装材质的直接光/ GI 对照过程 | 当前 Sandbox（用户已改过资产）；不能作最终样张 |
| `artifacts/gi-gain-commit/v1,v2` | `v2/gi.log`（含 gain 1x/3x 校验）、`results.log` | `8119e01` 的 0/1/3 倍语义与纯金属隔离在候选构建上通过 | 当前构建 |
| `artifacts/cornell-box/v1/` | `gi/gi-report.json`（8012B）、`sample/`、`capture/` | 10-29 Cornell 示例＋矩形光 MIS | 示例后来被删/恢复，参数已变 |
| `artifacts/cornell-commit/` | `gi-retry.log`（1261 dispatches，23 条 PASS 含矩形灯 MIS/彩色接收面）、`ctest.log`（10/10）、`sample.log`、`commit.txt` | 10-30 提交基线的 Cornell 示例与 GI 专项通过；`gi.log` 首轮失败、`gi-retry.log` 重试通过 | 合并到最新 master 后的回归 |
| `artifacts/cornell-bleeding/v1,v2` | v1 `display-roi.json`（显示域 ROI RGB）、`run.log`；v2 `gi.log`（1568 dispatches）、`results.log`（gi/hardware/cornell-1/cornell-3 exit=0）、`final-hash-check.json` | 颜色互染存在且随墙反射率变化；gain 1x/3x 的隔离图像与 ROI 数字 | 物理参考验证（文档自己强调是显示域数据） |
| `artifacts/r8-performance/` | `final-comparison.json`（10,000,024 三角形；raster Application Frame 5.537ms/8 帧，hardware 48.088ms/6 帧，DXR scene 42.161ms）、`gi-final/gi-report.json` | 10-29 构建的一千万三角形＋实时 GI 规模运行与计时 | 当前 native DXR/新 GI 模式的性能；不能当帧率承诺 |
| `artifacts/hardware-rt/` | `hardware-rt-report.json`、`project-settings-ui.txt`、`raster-regression/validation-results.json` | 硬件通道与配置交互 | GI 画质（只证明通道运行） |
| `artifacts/native-dxr-aa/`、`native-dxr-editor(2)/` | `anti-aliasing.json`、`diagnostics*` | 11-19 native DXR/AA 通道与诊断 | GI 质量；与 GI 无直接证据关系 |

### 4.2 11-19/11-20 四项扩展唯一的运行证据：任务目录

`local/docs/tasks/2026-11-19-realtime-gi/` 下有 **20 张 PNG**（无原始日志、无 JSON 报告、无 exit code 文件）：

- SSGI：`ssgi-native-d3d12.png`、`ssgi-strict-d3d11.png`（首版）、`ssgi-fixed-trace-composite.png`、`ssgi-cornell-indirect.png`（修复后）
- DDGI：`ddgi-native-d3d12.png`、`ddgi-strict-d3d11.png`、`ddgi-stabilized-probes.png`、`ddgi-real-effect.png`、`ddgi-off-reference.png`、`ddgi-raytraced-native.png`、`ddgi-raytraced-hybrid.png`、`ddgi-raytraced-probes.png`、`ddgi-raytraced-indirect.png`、`ddgi-software-cornell-lit.png`、`ddgi-software-cornell-probes.png`
- 调试视图：`gi-probe-debug.png`、`gi-indirect-debug-ddgi.png`
- ReSTIR：`restir-native-d3d12.png`、`restir-temporal-reservoir.png`、`restir-direct-reservoir.png`

配套记录：`m1.md`–`m5-debug-and-full-ddgi.md`、`acceptance.md`。**注意**：`artifacts/` 里没有任何一份文本/JSON 含 `DDGI/SSGI/ReSTIR/probeRayCount/screenSpaceSteps`（已用 `grep` 全目录确认）；D:\tmp 下的 `RAEngineSsgiProbe`、`RAEngineDdgiProbe` 等是运行临时副本，不是仓库证据，不能引用为“日志路径”。

### 4.3 任务记录里的验证数字（B，可直接抽进底稿；正文用前必须重跑）

| 提交 | 任务记录数字 | 记录位置 |
| --- | --- | --- |
| `ba44bad` | native/hybrid self-test 通过；denoiser 三模式 validation 0；CTest 30/30；移动相机/物体前后仍 active | `tasks/2026-11-19-realtime-gi/m1.md` |
| `23bab37` | 移动 Actor 的 native self-test；`effectiveMotionVectors=PerObject`；hybrid stride 回归修复 | 同上 |
| `1a3dc57` | native smoke 用最大 4 轮；native/hybrid 通过 | 同上 |
| `1768b21`＋`fa5667f` | native D3D12 8 帧、strict D3D11 8 帧，exit 0、validation 0；`GI effective: screenSpace` | `m2.md` |
| `f52eb1f` | native 6 帧、strict D3D11 5 帧，validation 0；`ProjectSettingsTests 1141 checks`、`RenderPipelineTests 154 checks`、CTest 30/30 | `m3.md` |
| `fa5667f` | SSGI/DDGI native 与 strict D3D11 各 8 帧 validation 0；DDGI 稳定化截图 | `m3.md`/`acceptance.md` |
| `b97f305` | DDGI on/off `meanAbsRGBPerPixel≈9.35`；native/D3D11 各 8 帧 exit 0、validation 0 | `m3.md` |
| `9237cd3` | native D3D12 与 strict D3D11 6–8 帧，validation 0 | `m5-debug-and-full-ddgi.md` |
| `f94b313` | native DXR 8 帧、hybrid 8 帧，validation 0，DXR dispatches 10，`Ray-traced DDGI`；CTest 30/30 | `m5`/`acceptance.md` |
| `26aaf1f` | 软件 DDGI fallback：native D3D12 raster 与 strict D3D11 各 6 帧，validation 0，`Software ray-traced DDGI`、DXR dispatches 0；SSGI 修复后 validation 0；CTest 30/30 | `acceptance.md` |
| `9dd0639`–`0d93c0a` | native 8–10 帧、hybrid 6–8 帧，validation 0，状态 `Sampling: ReSTIR (...)` | `m4.md` |
| `638ae2e`/`a46432b` | GI 专项 1261 真实 DXR dispatch、graphics errors 0；矩形灯正背面/遮挡/MIS/历史重置通过 | `artifacts/cornell-commit/gi-retry.log`＋任务 v1/v2 |
| `8119e01` | 隔离 Debug 9/9 CPU；GI 1458 dispatch、硬件/UI 230 dispatch、validation 0；3:1 近似反演 2.9918 | `artifacts/cornell-bleeding/v2/gi.log` 等 |
| `933e2d7` | 10,000,024 三角形＋实时 GI；raster 5.537ms vs hardware 48.088ms（8/6 帧均值） | `artifacts/r8-performance/final-comparison.json` |

### 4.4 证据可用性判定

**能证明（B）**
- 这些能力在历史某个提交/构建上实现并运行过；validation 0、dispatch 数、exit 0、关键状态字符串都留有记录（10-29/10-30 有日志/JSON；11-20 只有截图与任务记录）。
- Progressive/Realtime 的贡献开关、颜色传递、历史重置、Cornell 矩形光 MIS 有较完整的历史数字与产物。

**不能证明**
- 当前 HEAD（`26aaf1f`）或用户修复后的画面、稳定性、性能；工作区仍有未提交 GI 改动。
- 画面质量：validation 0 只证明“没报错/像素有变化”，不证明颜色、泄漏、噪声、拖影达标；截图是单帧，不能证明时间稳定性。
- ReSTIR 相对 Uniform 的增益/闪烁；DDGI 泄漏基准；软件 fallback 与 DXR 的质量差；相机/物体运动下的拖影。
- 任何 FPS/帧时间承诺；`10M triangle` 数字属于 10-29 构建，且当时的 DXR/GI 实现与 HEAD 不同。
- 文档自述的“60B/px、4K≈475MiB”只是解析估算，未测量。

**缺失**
- 11-20 四项扩展的原始日志、exit code、validation JSON、可复现命令；仓库内只有 20 张 PNG。
- 连续录屏/GIF（运动、probe 更新、hysteresis、SSGI 历史）。
- UI 操作证据（F3 下拉实际选择、GI 工具栏状态、debug combo 11/12 的编辑器截图——现有 GI 截图多为无 UI 的渲染结果）。
- 干净构建的当前构建哈希/可执行文件哈希，与图像绑定。

### 4.5 重跑升 A 的最小清单（等用户 GI 修复提交后做）

1. 干净 Debug 构建，记录 commit、exe 哈希、GPU 型号、驱动；`ctest -C Debug`（目标 30/30）。
2. 同一隔离工程副本（`git archive`/复制，固定 `engineRoot`，不写真实 Sandbox）分别跑：
   - strict D3D11：`--gi-self-test --capture-dir artifacts/devlog03-gi/d3d11`
   - native D3D12：`--backend d3d12 --gi-self-test --capture-dir artifacts/devlog03-gi/d3d12`
   - hybrid：`--backend d3d11Dxr --hardware-rt-self-test`、`--native-d3d12-self-test`
   记录 exit code、`validationErrors`、每个模式的 `GI effective:`/`Ray-traced DDGI`/`Software ray-traced DDGI`/`Sampling: ReSTIR` 状态行。
3. 固定相机/曝光/视口，各出一组同机位对比 PNG：
   - Cornell：GI off / SSGI / DDGI(DXR) / DDGI(软件) / PathTracing Realtime / Progressive；每张带生效模式与参数。
   - debug 11/12 各一张（native 与 D3D11 至少各一套），并说明当前 HEAD 的 probe 标记形态。
4. 真实连续录屏 1–2 段：相机/物体运动下的 temporal 降噪与 ReSTIR 闪烁；DDGI probe 随场景变化的稳定性（按规范 ≤5,000,000 字节，真实播放检查）。
5. F3 项目设置实际下拉/滑杆操作截图；GI 工具栏状态可读；保存重开校验 JSON 值与 effective 值。
6. 若写性能：在同一构建、同一场景分别测 GI off/各模式，报告分辨率、采样预算、帧时间口径；不要复用 10-29 数字。

## 5. 建议正文切分与素材

### 5.1 模块切分（GI 部分，落在 DevLog03 的 3–6 个技术模块内）

推荐 **3 个 GI 模块**；如果整期还要给 native DXR、帧检查、AA/阴影、资产等留位置，GI 压到 **2 个**（把“三档与判定”并进模块一开头）。

1. **模块 A：GI 从一种算法变成三档可配置**（约 600–800 字）
   - 现状→改动：之前只有 PathTracing（Progressive/Realtime）；现在 `method` 扩为 PathTracing/SSGI/DDGI，`requested/effective` 分层，能力不改写项目请求。
   - 源码：`GlobalIllumination.h` 枚举＋`RenderFeatures.cpp` 的 GI feature 分支。
   - 证据：F3 设置页与工具栏状态（需重拍）；模式矩阵表（可用文字表）。
   - 边界：SSGI/DDGI 只 Deferred/编辑器目标；Forward 不可用；本帧硬件传输时跳过 SSGI/DDGI。
   - 取舍：为什么把 ReSTIR 做成“采样层”而不是第四种 method（ReSTIR 不是传输算法）。
2. **模块 B：SSGI——两 Pass 与自反馈/数据源修复**（约 700–900 字）
   - 现状→改动：首版单 Pass 采样场景色会自反馈（firefly）→ trace/composite 分离；trace 采样 direct-lit 副本；composite 做空域＋时域＋albedo；`26aaf1f` 又修“采样当前帧副本/补 albedo/厚度下限”。
   - 源码：`Scene.hlsl` composite 的 spatial/temporal 段（5–20 行）＋`ScenePipeline.cpp` 的 pass 声明（说明资源边即数据流）。
   - 公式：时域混合与厚度下限（见 §5.3）。
   - 证据：Cornell SSGI indirect 与 GI off 同机位；debug 11（需重跑）。
   - 边界：display-space、屏幕外缺失、无逐物体运动向量、硬件传输同帧跳过。
3. **模块 C：DDGI——probe atlas 的三个坑与两条路径**（约 800–1000 字）
   - 现状→改动：光栅投影更新“看起来完全无效” → atlas viewport（`b97f305`）→ 场景自动拟合 → DXR 逐 probe＋depth visibility（`f94b313`）→ 软件光追 fallback（`26aaf1f`）。
   - 源码：`SceneRenderer.cpp:2552–2558`（atlas viewport＋交换）或 `HardwareRayTracing.hlsl:194–232`（逐 probe 光线＋depth moments）。
   - 公式：hysteresis 混合、三线性×置信度、Chebyshev visibility（§5.3）。
   - 证据：`ddgi-raytraced-probes.png`/`ddgi-raytraced-indirect.png`、软件 fallback 截图、debug 12；DDGI on/off（须重跑并说明 meanAbsRGB 只证明差异不是画质）。
   - 边界：首帧无效、软件 fallback 依赖屏幕可见表面、无 probe relocation、非无偏、indirect specular 不参与。
4. **可选模块 D：实时路径追踪的时域重建与 ReSTIR 采样层**（约 600–800 字）
   - 内容：`1bd8e58` 配置→`ba44bad` 相机重投影→`23bab37` 逐物体位置→`1a3dc57` 多尺度→`9dd0639/e7defe8/e1591f1/0d93c0a` ReSTIR。
   - 源码：`PathTracing.hlsli:380–419`（reservoir 选择与 20% 时域混合）。
   - 公式：reservoir 估计。
   - 边界：近似无偏、空间 reuse 非正式合并、没有量化闪烁指标。
   - 若整期模块超 6 个，这一节可并入模块 A 的结尾或与“native DXR”模块合并（GI 相关部分才提）。

叙述原则：不要按 commit 顺序写；按“限制→改动→证据→边界”写。三个最值得展开的坑见 §5.5。

### 5.2 可贴源码片段候选（5–20 行，路径＋commit）

| 编号 | 位置 @ `26aaf1f` | 行数 | 说明 |
| --- | --- | --- | --- |
| S1 | `include/RestArtEngine/Renderer/GlobalIllumination.h:8–23` | 16 | 三档 method＋mode＋denoiser/motion/sampling 枚举，讲统一配置模型 |
| S2 | `src/Renderer/SceneRenderer.cpp:2057–2067` | 11 | `dxrProbeCapable`／`rasterProbeGi`／`hardwareProbeGi`/`probeGridGi`，讲 DDGI 两条路径与降级 |
| S3 | `Shaders/Private/Scene.hlsl:882–923` | 20（可删掉部分权重行） | SSGI composite：3×3 几何滤波＋上一帧重投影 clamp＋0.1 混合＋albedo 调制＋debug 分支 |
| S4 | `Shaders/Private/Scene.hlsl:1023–1035` | 13 | `PSProbeUpdate`：atlas 像素→probe 坐标、`w>2.5` 分流软件光追 |
| S5 | `Shaders/Private/HardwareRayTracing.hlsl:194–232` | 20（删掉部分行） | DXR 逐 probe：Fibonacci 方向、命中求直接光、hysteresis、depth moments |
| S6 | `Shaders/Private/PathTracing.hlsli:386–419` | 20 | ReSTIR 直接光 reservoir：候选、加权选择、时域 20% 混合 |
| S7 | `src/Renderer/D3D12/HardwareRayTracing.cpp:1061–1066` | 6 | 能力判定最小片段：DXR tier＋SM 6.5 |
| S8 | `src/Renderer/Pipelines/ScenePipeline.cpp:127–143` | 17 | 声明式 pass：SSGI trace/composite、DDGI probe update 及其资源边 |

优先选 S1/S3/S5 或 S1/S4/S6；S2 适合讲“为什么在 DXR-capable 后端关硬件光追还能跑 DDGI”的取舍。

### 5.3 可配公式候选（2–5 个，每个对应代码）

1. **SSGI 时域混合**（`Scene.hlsl:907–918`）：  
   `I_t = lerp(clamp(I_{t-1}, L, H), I_{spatial}, w_t)`，其中当前帧权重 `w_t = giHistory.z = 0.1`，`L/H` 为 3×3 邻域 min/max。正文配一句“历史不是直接平均，而是先 clamp 到当前邻域”。
2. **DDGI 采样置信度/三线性**（`Scene.hlsl:936–965`）：  
   `I(p) = Σ w_i·conf_i·E_i / Σ w_i·conf_i × intensity`，`conf` 来自 atlas alpha；DXR 路径再乘 `0.35 + 0.65·visibility·hitRatio`。
3. **Chebyshev 可见性**（`Scene.hlsl:952–960`）：  
   `v = σ²/(σ² + (m - d)²)`（`d < m` 时），`σ² = E[d²] - E[d]²`；用 mean/mean² depth moments 判断接收面是否大概被遮挡。
4. **ReSTIR 估计与复用**（`HardwareRayTracing.hlsl:298–309`、`PathTracing.hlsli:390–419`）：  
   `L = selected × totalWeight / (selectedWeight × N)`；时域 `estimate = lerp(previous, estimate, 0.2)`。正文必须同时写“这是近似，不是严格无偏”。
5. **间接漫反射艺术增益只乘一次**（`PathTracing.hlsli` 首接收面分支，`8119e01`）：  
   `f_first = gain·f_d + f_s`（接收面），后续顶点和直接光估计器仍用 1；解释“为什么不能逐跳相乘/乘 throughput”。

### 5.4 可复现小实验（读者 3 步内可做）

1. 打开 `Projects/PathTracing_CornellBox`，F3 → Rendering → `GI method` 依次切 `Progressive accumulation` / `Realtime`，看工具栏 GI 状态与画面。
2. 同一场景切 `Screen space (SSGI)`：确认必须先 Deferred；Forward 会报告不可用；把 `SSGI thickness` 调到很小，观察 `0.5×radius` 下限仍在生效（画面不整体变黑）。
3. 切 `Probe grid (DDGI)`：开/关 `Hardware ray tracing`，对比状态区 `Ray-traced DDGI` 与 `Software ray-traced DDGI`；视口 debug combo 选 `GI probes`，看 probe 辐照度是否随周围几何变化。
4. 若重跑证据齐：`--debug-view 11` 与 `12` 各截一张固定相机图，作为“间接光只显示”和“probe 体积”的可视化。

### 5.5 最值得写进正文的坑/取舍（按叙事价值排序）

1. **自反馈：SSGI 采样自己**（`1768b21`→`fa5667f`→`26aaf1f`）。第一版在一个 pass 里把 indirect 加回场景色，下一帧又去采样场景色，于是亮点越滚越亮；拆 trace/composite 后仍不够，因为 trace 采样的是“上一帧已经加了 SSGI 的颜色”，最终改成 trace 只采样当前帧 direct-lit 副本。**取舍**：多一张 direct-lit 副本和一次 copy，换来稳定；这是“屏幕空间里最容易被自己污染”的经典坑。
2. **DDGI atlas 的 viewport 继承**（`b97f305`）。ProbeUpdate 是“全屏画 1024×32 的 atlas”，但 pass 沿用了 scene viewport，绝大多数 atlas 像素没被写过，表现像“DDGI 完全无效”。**取舍**：pass 自己设 viewport 再恢复；同时补 `probeAutoFit`，否则旧工程保存的手工 spacing 会让网格错位。
3. **降级策略的两次反转**（`3733d68`→`26aaf1f`）。先决定“DXR-capable 后端关硬件光追时不跑慢且漏光的投影 fallback，直接报不可用”，后发现“能跑一个明确标注的软件光追 fallback 对调试/低端设备更有价值”。**取舍**：不静默跑坏的近似，但也不把设备挡在门外；状态字符串必须让用户知道自己在看哪种路径。写这一段能带出“能力/请求/原因”三层设计。
4. **ReSTIR 是采样层，不是第四种传输算法**（`9dd0639` 起）。它不改变 `method`，只改变 PathTracing Realtime 的样本选择；direct 乘灯数、indirect 按亮度选、spatial reuse 只是邻域平均，**至今不是严格无偏**。写在正文里比吹“实现 ReSTIR”诚实。
5. **probe 噪声/预算的取舍**（`f94b313`）。`probeRayCount` 默认 16、固定 Fibonacci 方向、hysteresis 0.95；少光线=快但有 Monte Carlo 噪声，多光线=贵；没有 probe relocation。适合配公式和性能段。
6. **调试视图作为取证工具**（`9237cd3`/`4e9a8dc`/`2e6fb59`）。GI indirect / GI probes 把“看不见的间接光”变成可截图对象；顺带两个小坑：probe 标记在宽视口变椭圆（aspect 修正）、切视图后 DDGI 间接光消失（`2e6fb59`）。

## 6. 待验证/已知问题清单

### 6.1 必须重跑才能写成“现在能”（影响正文措辞）

| ID | 事项 | 现状 | 验收条件 |
| --- | --- | --- | --- |
| V1 | 三档 GI 在当前 HEAD 的实际画面与状态 | 只有 11-20 任务记录/截图（B） | 干净构建后 strict D3D11＋native D3D12 各跑 SSGI/DDGI/PathTracing，记录 `GI effective`、`Ray-traced/Software ray-traced DDGI`、validation 0、exit code |
| V2 | 26aaf1f 的 SSGI 修复（当前 direct-lit 副本、albedo、厚度下限） | 任务记录称 native/D3D11 validation 0，无日志导出 | 同机位 Cornell SSGI indirect/on-off 图＋状态行＋debug 11 |
| V3 | 软件 DDGI fallback（native raster/严格 D3D11） | 只有任务记录 6 帧、状态 `Software ray-traced DDGI` | 同场景 DXR vs 软件两图＋两种状态行；说明性能差 |
| V4 | DXR 逐 probe DDGI（16 rays、depth atlas、Chebyshev） | 8 帧任务记录；无原始 report | native/hybrid 各 ≥8 帧，validation 0，抓 dispatch 数、probe 截图、on/off 差异 |
| V5 | temporal 降噪/逐物体运动向量 | native self-test 记录存在，无录屏 | 真实连续录屏：相机推进＋移动 Actor，观察拖影/重置，GIF ≤5MB 且完整播放 |
| V6 | ReSTIR vs Uniform | 只有单帧截图与状态字符串 | 同一相机/预算的 Uniform/ReSTIR 对比（含闪烁判断，最好录屏） |
| V7 | 编辑器实际 UI：F3 模式下拉、参数滑杆、GI 工具栏状态、debug combo | 没有 HEAD 的 UI 截图 | 1440×900 固定窗口，两主题至少一套；保存重开校验 JSON |
| V8 | 当前性能 | 无新 GI 模式的帧时间数据；10M 数字是 10-29 旧构建 | 同构建、同场景、同分辨率下 GI off/各模式帧时间（明确口径） |

### 6.2 公开文档与源码不一致（文章不要照抄；发布前建议修）

| ID | 位置 | 问题 |
| --- | --- | --- |
| D1 | `docs/GlobalIllumination.md:186–200` | 末尾重复整节“单矩形发光面示例”（与 57–63 重复）与“场景可选 camera”（与 63 重复）；`扩展与迭代` 仍写“当前 `GlobalIlluminationMethod` 枚举只有 Disabled 和 Path tracing”“逐物体运动向量仍待扩展”，与 HEAD 三档＋已实现冲突 |
| D2 | `docs/HardwareRayTracing.md:3,37,53` | 仍写 `GI method` 只有 Disabled/Path tracing、项目格式只列 `disabled`/`pathTracing`（实际 4 值）；第 53 行“不包含运动重投影”与 89 行的 temporal 描述矛盾 |
| D3 | `docs/Architecture.md:232` | “实时模式有边缘感知空间滤波，尚无运动重投影”已过时（`ba44bad`/`23bab37` 已接） |
| D4 | `docs/RenderingDevelopment.md:99` | “当前仅 PathTracing 算法及 Disabled；无运动重投影，其他算法尚未实现”已过时 |
| D5 | `docs/RenderPipeline.md:97` | SSGI trace 的输入仍写 `ScreenSpaceDirectHistory`；同页 72 行与代码已改为 `ScreenSpaceDirectCurrent`（`26aaf1f`） |
| D6 | `src/Editor/ProjectSettings.cpp:187,302` | 提示仍写 SSGI “samples last frame's lit color”“single deferred pass”；实际是当前帧 direct-lit 副本＋两 Pass |
| D7 | `src/Editor/ProjectSettings.cpp:300` | “temporal stability still comes from the GI history, not a separate reservoir history”已过时：`e7defe8`/`e1591f1` 已加 reservoir 历史 |
| D8 | `src/Renderer/SceneRenderer.cpp:2093,2921,334,336` | SSGI effective 状态文案仍写 “previous-frame color”；DDGI 文案写 “previous-frame update”（DXR 路径是逐帧 probe 追踪，只是光照采样上一版 atlas），容易误导 |
| D9 | `src/Renderer/SceneRenderer.cpp:2080–2081` | 仍然保留“DXR-capable 后端关硬件光追 → 报不可用”的 reason 分支；`26aaf1f` 后该分支在常规 DDGI 下不可达（只有 debugView 非 0/11/12 等边角才命中），属残留死文案 |
| D10 | `Projects/PathTracing_CornellBox/README.md` | README 写“4 samples/frame、1024 target、8 次着色”，`.raproject` 实际是 16/65536/12（`14a6b0d` 后未同步 README；`86dab47` 恢复时保留旧 README） |
| D11 | `include/RestArtEngine/Renderer/GlobalIllumination.h:60` | 注释写 probe grid “camera-target centred and rebuilt per frame”；实际 `probeAutoFit` 默认按场景包围盒拟合（`b97f305`），只有关掉 auto-fit 才用 cameraTarget |
| D12 | `docs/GlobalIllumination.md:7,101` | “SSGI 可在 DX11+DXR 后端运行”成立但仅限该帧硬件传输未实际运行；文档未写“本帧硬件传输时 SSGI/DDGI 被跳过” |

### 6.3 实现层面的已知边界（可写进各模块末尾）

- ReSTIR：direct 估计乘灯数校正、indirect 按亮度选样本、spatial reuse 只是上一帧 3×3 邻域平均；不是正式 reservoir 合并，未做质量量化。
- DDGI：DXR 路径每 probe 固定 Fibonacci 方向（16 默认），有 Monte Carlo 噪声；无 probe relocation；软件 fallback 依赖屏幕可见表面、无硬件 depth/visibility atlas；首帧无贡献。
- SSGI：display-space 合成（非线性 HDR）、屏幕外信息缺失、无逐物体运动向量、快速相机运动有历史滞后、无 object/emissive ID（用亮度阈值拒绝发光体）。
- 通用：无透明/发光材质、无环境重要性采样、无神经网络降噪；DXR 主射线要求材质 ZTest Less/LessEqual＋ZWrite On；runtime swapchain 未启用 SSGI/DDGI；Vulkan/OpenGL/Linux/macOS 未实现。

### 6.4 工作区未提交 GI 改动（只作线索，不算已验证）

`git diff`（审计期间）显示：`Shaders/Private/Scene.hlsl`（+60 行左右，probe debug 改为真实球体实例＋法线光照）、`src/Renderer/SceneRenderer.cpp`（+133 行，Engine Sphere 网格/实例缓冲、`probeDebugGeometryValid` 缓存、`GiDebugOverlay` 改 instance draw）、`Rhi.h`（`VertexAttribute::perInstance`、`drawIndexedInstanced`）、`D3D11Rhi.cpp`/`D3D12Rhi.cpp`/`RhiInspection.h`（instanced draw 实现与捕获）、`docs/GlobalIllumination.md` 一行（改为“实际低多边形小球网格/icosphere”描述）、Sandbox 材质/场景/工程；审计过程中 `tests/RhiInspectionTests.cpp` 也新出现在修改列表，说明用户仍在持续改这批文件。**这些都不是 `26aaf1f` 的事实**：

- 正文若写 debug probes，只能按 HEAD 写“圆点 billboard”，或等这批提交并验证后再写“球体网格”。
- 这批改动可能随时变化；本轮不依赖其结果，也没有验证它能否编译/通过。
- Sandbox 资源（`Copper/Red/Yellow/Ground.rasset`、`Default.rascene`、`Sandbox.raproject`）是用户工作区改动，**不能当可复现样张**；正文引用样例应使用 `Projects/PathTracing_CornellBox`（干净提交）或明确“用户本地 Sandbox”。

### 6.5 其他待核实

- 11-20 的截图是否由当前 HEAD 的 shader/代码生成、对应哪个 exe，没有记录；不能默认“截图 = 26aaf1f”。
- 文档说 DDGI 软件 fallback 在 hybrid 后端也可用？代码上 `rasterProbeGi` 在 hybrid 下若 `hardwareTransport=false`（硬件光追关）走 D3D11 raster ProbeUpdate，应可用，但任务记录只验证了 native raster 与 strict D3D11；**hybrid + 硬件关** 未单独验证。
- `--debug-view` 在无编辑器下是否真能稳定截图（`9237cd3` 加了 CLI，但任务记录用它验证的是 native/strict 的 debug 图）——需要和 V7 一起补。
- 8-30/10-29 的旧证据是否值得作为“演进起点”写进正文（PathTracing 的渐进/实时、颜色互染、矩形光 MIS）——可以，但必须标 B，且不能说成当前 HEAD 的结果。

## 7. 阅读覆盖与限制

- 读了：根 `AGENTS.md`、`local/docs/AgentEntry.md`、`ZhihuSeries.md`（§2–§6 相关章节）、`ZhihuSeriesLedger.md`（当前状态/第2期交接/候选池/承诺）、`DevelopmentStatus.md` 顶部 1–60 行（11-19 GI 四条记录与 26aaf1f 数字）、`DevelopmentExperience.md`、`DevelopmentChanges-AfterDevLog02.md`；`local/docs/tasks/2026-11-19-realtime-gi/{README,acceptance,m1–m5}`、`2026-10-29-cornell-box`、`2026-10-29-lighting`、`2026-10-30-cornell-bleeding`、`2026-10-29-remaining-commits`、`design/RealtimeGiOptions.md`、`experience/PathTracingExamples.md`。
- 读了 `git show 26aaf1f:` 的：`docs/GlobalIllumination.md`、`docs/HardwareRayTracing.md`、`docs/RenderPipeline.md`（GI 相关）、`docs/Architecture.md`（渲染段）、`docs/RenderingDevelopment.md`（GI 段）、`docs/EditorGuide.md`（GI 段）、`include/.../GlobalIllumination.h`、`RenderFeatures.h`、`RenderPipeline.h`、核心源码与 shader 的 GI 区段（见 §2.5）、`Projects/PathTracing_CornellBox/*`。
- 读了 `artifacts/` 下 GI 相关文本/JSON/日志（`gi*`、`hardware-rt`、`cornell-*`、`r8-performance`、`native-dxr-*` 的 JSON 清单），未逐张打开大图；未读 vendor、未读所有 117 提交的全量 diff（只读 GI 相关提交与文件）。
- 未做：构建、运行引擎、截图、GIF、修改任何文件（本页除外）、commit/reset。
- 结论以 `26aaf1f` 提交为准；工作区改动已按 §6.4 单列，未来若用户提交新的 GI 修复，应先更新本页再写正文。
