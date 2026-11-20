# DevLog03 审计：抗锯齿、阴影、材质深度/剔除与诊断工具

> 只读审计，审计日 2026-11-20。区间 `4193f55..26aaf1f`（2026-10-26 13:48 ～ 2026-11-20）。
> 本文只保留在协作库，不提交引擎仓库；不复制公开文档正文，只记录提交事实、源码位置、证据等级与写作建议。
> 本轮**未构建、未运行引擎、未修改被跟踪文件、未提交/reset**。工作区当前有未提交的 GI 修复（11 个已跟踪文件修改 + 3 个未跟踪 Sandbox 资产），本文所有源码结论取自提交 `26aaf1f` 的 blob，不引用工作区状态。

## 0. 口径、时间线与边界

### 0.1 区间事实

- 区间共 **117 个提交**（`4193f55..26aaf1f`，不含起点、含终点），299 个文件变更。
- 起点 `4193f55`（2026-10-26，「test(gui): queue caption input and verify all integrated task commits」）是 DevLog02 正文的冻结终点；DevLog02 标签落在 `cc68a1b`，两者之间只差文档提交。DevLog03 的起点因此可以写 `4193f55`。
- 终点 `26aaf1f`（2026-11-20，SSGI/软件 DDGI 修复）。
- 引擎版本声明仍是 `project(RestArtEngine VERSION 0.2.0)`（`CMakeLists.txt:2`），区间内没有修改。写作头里的 `vX.Y.Z` 需要单独确认，不要沿用「工程内声明＝对外版本」。
- 区间内容分两个明显的时间簇，写作时不能按 commit 顺序讲：
  1. **2026-10-26 ～ 10-31**：编辑器/资产/Content、选中描边、状态栏与命令控制台、诊断工具首版（CPU trace、帧捕获、Profiler/Frame Inspector UI、诊断测试）、材质深度/剔除、三角面统计、基于 DXR 的渐进/实时 GI 首版、README 重写、相机/灯光/网格属性合入。
  2. **2026-11-18 ～ 11-20**：原生 D3D12 主后端与原生 DXR、加载进度、**FXAA/TAA**、**4096²+4×4 PCF 阴影**、网格 Slot 编辑、实时 GI 四项扩展（降噪/SSGI/DDGI/ReSTIR）与其修复。
- 本审计只覆盖「画质（AA/阴影/材质深度剔除）」与「工具（Profiler/帧捕获/三角统计）」，逐提交表也只列这些提交；其余提交属其他审计/其他小节。

### 0.2 证据等级（本次口径）

| 标记 | 含义 | 能怎么写 |
| --- | --- | --- |
| **A期** | 区间内某提交自带的真实运行记录：有命令、退出码、设备、JSON/日志/截图 | 可写成「当时验证过」；若要在文中写「现在能」，发布前须在 `26aaf1f` 重跑 |
| **A图** | 区间内产物、真实 GPU 截图，且已随公开文档提交（`docs/images/`） | 可作配图候选；需核对参数与裁剪说明，必要时重拍 |
| **B** | 只有源码/文档，区间内没有对应运行记录 | 只能写「代码里有，未实测」 |
| **C** | 计划、推测、由源码推导但未跑 | 只能放「下一步 / 边界」，不能写成已完成 |

区间内证据默认都按「A期」，**发布口径仍要求重跑**：AA 与阴影提交都早于原生 DXR、实时 GI 四项扩展和 SSGI/DDGI 修复，`26aaf1f` 上没有任何一份 AA/阴影/诊断自测日志。

## 1. 逐提交表（本审计重点提交）

| 提交 | 日期 | 变化 | 被替代 / 关系 |
| --- | --- | --- | --- |
| `50964d8` | 2026-10-29 | 有界 CPU trace：`TraceProfiler`（65536 事件上限、120 帧摘要）、`TraceScope`、Chrome Trace JSON 导出、`--trace-output` | 首版；后续 `6a243b2` 把它接进 Frame Inspector 快照与 UI |
| `c9342be` | 2026-10-29 | 帧捕获 + GPU 诊断：`RenderDiagnostics.inl`/`.Api.inl`、D3D11 disjoint+timestamp 四槽计时、捕获资源/事件/常量快照 | 首版仅 D3D11；`.raframe` 离线包与原生 D3D12 计时由 `6a243b2` 补上 |
| `5c23e42` | 2026-10-29 | 编辑器接入 Profiler / Frame Inspector 工具窗（DiagnosticsPanel 首版约 290 行，只有两页签） | 首版；Runtime 页签与最终 UI 在 `6a243b2` 后补齐（三页签、双主题、窄窗） |
| `3f497f3` | 2026-10-29 | 诊断专项测试：`DiagnosticsSmoke`、`EditorSmoke` 诊断用例、`Validate-Render.ps1` 支持 `-Project` 隔离工程 | 仍是当前验收入口；数字口径见 §3 |
| `5a5a729` | 2026-10-29 | 公开文档：`docs/Diagnostics.md` 首版 + EditorGuide/README/Architecture 同步 | 部分被 `c2ab76e`（2026-11-19，原生诊断/离线包）替代；现行口径以 `docs/Diagnostics.md` 当前版本为准 |
| `d7d2fe6` | 2026-10-29 | 三角面统计：`SceneGeometryStatistics.h` + `GeometryStatistics.inl`；Scene Overview / 视口叠加 / Profiler 显示；D3D11 四槽 `PIPELINE_STATISTICS` 异步查询 | 仍是最终实现；原生 D3D12 的 GPU 裁剪统计至今未实现（`GeometryStatistics.inl:55-58` 报 Unavailable） |
| `933e2d7` | 2026-10-29 | 材质 `Cull`/`ZTest`/`ZWrite` + 序列化 + 实时预览；相机/阴影视锥剔除；硬件深度兼容门控；千万三角形 DXR GI 验证 | `Cull` 取代旧的 Two-sided 复选框（`docs/EditorGuide.md:212`）；`twoSided` 保留旧资产兼容 |
| `769f192` | 2026-10-29 | 文档：PBR/NPR 双体系目标、裁剪统计口径澄清 | 目标仍有效；缺失/未实现部分已在该文档声明 |
| `4f16de6` | 2026-10-29 | 文档：硬件光追与渐进 GI | GI 侧由其他审计展开；本审计只引用其对 AA 回退的前提 |
| `dda510c` | 2026-10-29 | 文档：实时 GI 模式与贡献控制 | 同上 |
| `8f027db` + `a46432b` + `c5db70c` | 2026-10-30 | 相机/五种灯光/网格 Slot+UV/控制台集成（merge `a46432b`），配套公开文档 | 与画质相关的部分：屏幕空间景深（DOF）、五种灯型与阴影范围、PBR 材质契约；AA 与阴影提交在其之后，不能把 DOF/灯光当成 AA 相关成果 |
| `c86a6de` | 2026-10-30 | 普通浮窗可越出主窗口、SceneViewport 独立目标、跨窗拖放 | 主要属 GUI 小节；对工具的意义是 Diagnostics/Project Settings 等工具窗可移到副屏 |
| `6a243b2` | 2026-11-19 | 原生 D3D12 主后端 + 原生 DXR + **帧检查器终版**：原生 GPU 计时、`.raframe` 离线包（`FrameCaptureArchive`/`FrameCaptureMetadata`）、Runtime/进程内存 | 把 10-29 的诊断首版扩成双 API 终版；10-29 的 artifacts 只证明首版 |
| `c2ab76e` | 2026-11-19 | 文档：后端矩阵 + 原生诊断 | 替代 `5a5a729` 中「仅 D3D11」的口径 |
| `c017ff8` | 2026-11-19 | 纯 D3D12 上跑原生 DXR（阴影/反射/GI 与光栅共用 device/queue） | 影响 AA 的前提：原生 DXR 图像出现后 TAA 会被强制回退 FXAA |
| `64a7c97` | 2026-11-19 | 原生 DXR 在编辑器视口偏移处 resolve；顺带用 AA 自测做回归（AA 关 mismatches 0、FXAA=2/阈值 8） | AA 在原生 DXR 接通后的复验；`artifacts/native-dxr-aa/` 是这次记录 |
| `b142549` | 2026-11-19 | **FXAA/TAA**：Off/FXAA/TAA 项目设置 + 实时 UI、TAA 历史/抖动/重投影、回退规则、`--aa-self-test`/`--aa-ui-self-test`；同时修复原生 D3D12 启动 resize 失败 | 取代此前工作区里「AA 未完成、完整应用不可编译」的状态；启动修复属「稳定」素材 |
| `eaf4193` | 2026-11-19 | **4096² 阴影图 + `ShadowMapPCF16`（4×4、16 次双线性比较）**，设为默认；RenderFeatures/EditorSmoke 同步 | 取代旧默认 2×2 PCF + 2048² 口径；`docs/ShadowMethods.md`、`docs/Architecture.md` 已更新，但 `docs/RenderPipeline.md`、`docs/EditorGuide.md` 未同步（见 §8） |
| `8bbd1c9` | 2026-11-19 | 文档：4×4 PCF 与 4096 阴影图；新增 `docs/images/shadow-pcf-compare.png` | 增补而非替代；纠正了「九种接法/2048²/默认 2×2」的旧描述 |

相邻、但不属本审计的重点提交（会影响本节结论，需与对应小节协调）：`1bd8e58`/`ba44bad`/`23bab37`/`fa5667f`/`f94b313`/`26aaf1f`（实时 GI 降噪、SSGI、DDGI、ReSTIR）；`7f8a585`（Pass/Feature 声明，诊断面板读它）；`fca018a`（README 重写与 16 张图）。

## 2. 最终行为（以 `26aaf1f` 为准）

### 2.1 抗锯齿

**模式与默认值**

- 三种模式：`Off` / `FXAA` / `TAA`（`include/RestArtEngine/Renderer/AntiAliasing.h`）。
- 两层默认值不同，写作时要注意：
  - 工程级 `Project::RenderingSettings::antiAliasing` 默认 **FXAA**（旧工程缺该字段时按 FXAA 读，`include/RestArtEngine/Project/Project.h:59-60`）。
  - 低层 `SceneSettings::antiAliasing` 默认 **Disabled**（`include/RestArtEngine/Renderer/SceneRenderer.h:69`）；工具/自测调用者要显式选。
- 持久化：`rendering.antiAliasing.method`（`disabled`/`fxaa`/`taa`）与 `temporalCurrentWeight`（0.02–1，严格校验）写入 `.raproject`；切换与权重下一帧生效。

**TAA 依赖什么（这是文章里最容易写错的地方）**

- **没有逐物体运动矢量。** TAA 的常量缓冲只有：逆 ViewProjection、上一帧 ViewProjection、当前/上一帧相机位置与朝向、viewport、参数（`AntiAliasing.hlsli:4-14`）；没有任何 motion vector 输入。`23bab37` 的逐物体运动矢量只用于**实时 GI 的时域重投影**，不进 TAA。
- 依赖的是：**相机重投影**（用当前深度反投影到世界，再乘上一帧 VP）+ **3×3 最近表面深度膨胀**（保证轮廓/遮挡处不误拒）+ **3×3 邻域颜色钳制** + **深度兼容判定**（`|storedDepth-expectedDepth| < max(0.025, 0.015·expectedDepth)`）。
- **历史**：两张 `RGBA16F` ping-pong（RGB 颜色 + A 线性深度），尺寸等于目标纹理（不是 viewport）；只有历史图允许跨帧持久。历史不可用时用当前 FXAA 结果兜底，避免第一帧露出原始毛边。
- **抖动**：Halton(2,3) 16 个样本循环，按 viewport 尺寸换算成像素抖动并写入裁剪空间投影偏移（`AntiAliasing.inl:117-123`）。
- **失效**：相机跳变（位移平方和 >4，约 2 个世界单位；或 forward 点积 <0.8，约 37°）、场景键变化（Actor/变换/材质/光照/景深/exposure/shadowMethod/AA 权重/viewport/几何 revision…）、viewId、目标尺寸、投影变化、成功热编译都会重置历史。
- **分辨率/缩放**：在输出分辨率做 1:1 时间重建，没有 render scale、没有上采样；场景色仍是 RGBA8 显示域，**HDR 时间重建未实现**。MSAA 未实现。

**管线位置**

`Depth of field` → `Anti-aliasing（FXAA resolve 或 TAA resolve）` → `Anti-aliasing present`（仅 TAA）→ `Selection composite`。AA 位于场景颜色 / 硬件 resolve / 景深之后，选中描边之前；编辑器 UI 不过滤（`src/Renderer/Pipelines/ScenePipeline.cpp:161-174`）。注意：**选中描边在 AA 之后绘制，所以描边边缘本身不经过 AA**（源码顺序结论，未实测，见 §7）。

**回退规则（谁强制 FXAA）**

`resolveAntiAliasing`（`src/Renderer/AntiAliasing.inl:78-100`）按顺序判断：

1. 硬件图像 + 渐进路径追踪 → **AA 关闭**（PT 自己累积抖动主射线）。
2. `debugView >= 2`（数据视图）→ **AA 关闭**（保留原始数值）。
3. 请求 TAA 且 `offscreenTarget`（工具预览/离屏视口）→ **FXAA**（不消费主场景 TAA 历史）。
4. 请求 TAA 且 `hardwareImage` → **FXAA**（理由：「DXR 图像对齐目前需要稳定主射线；用 FXAA 保住 GI 历史」）。
5. 其余按请求执行。

这里的 `hardwareImage` 是渲染器在每帧算出来的「本帧是否预期出硬件图像」：硬件光追请求 + 管线就绪 + DXR 支持 + 无运行期失败 + **所有可见材质深度状态兼容**（`SceneRenderer.cpp:1829-1841`）。因此：
- **实时 DXR GI / 独立硬件全图 resolve → FXAA**，不是 TAA。
- **光栅 SSGI/DDGI（无硬件图像）→ 仍可用 TAA**（源码没有把这两条 GI 排除）。
- 渐进 PT → 无 AA；工具预览 → FXAA；数据视图 → 不滤。

**UI 位置与参数**

- `Project → Project Settings...` → 左侧 Rendering → `Anti-aliasing` 分隔区：`Off/FXAA/TAA` 下拉、「Current frame weight」滑条（0.02–1，仅 TAA 时出现）、`Requested:` / `Effective:` / `History: N frames` 与原因文本（`src/Editor/ProjectSettings.cpp:111-131`）。
- 底栏右侧 `Tools` 菜单与 `Debug` 菜单**没有** AA 入口；AA 只在工程配置里。写作时可写「F3 打开项目配置」的路径（`docs/EditorGuide.md:282`）。

**启动修复（「稳定」素材）**

`b142549` 除了功能还修了一个启动崩溃：FXAA resolve 曾把调用者目标（非编辑器渲染时就是交换链）写进跨帧成员 `aaResolvedImage`，原生 D3D12 在「加载窗 963×542 → 编辑器 2768×1191」的 resize 时因 backbuffer 仍被借用而拒绝 `ResizeBuffers`。修复是：FXAA 不再缓存目标；原生 D3D12 resize 顺序改为 `endRenderPass` → reset swapchain → `releaseBorrowedUiTextures()` → `waitIdle` → `ResizeBuffers`。这是很好的「修复类」故事，但只有任务记录（[antialiasing/v4](tasks/2026-11-19-antialiasing/v4.md)）：`artifacts/antialiasing/` 里只有三后端 AA 自测日志，没有「正常启动 + 加载窗→编辑器窗 resize」的日志，发布前需补一次。

### 2.2 阴影

**现状**

- 光栅直接光阴影共 **10 种接法**：`2×2 PCF`、`硬比较`、`3×3 PCF`、**`4×4 PCF（默认）`**、`PCSS`、`两级 CSM`、`GTAO`、`Deferred Contact Shadow`、`Analytic rays`、`Disabled`；切换只改常量与 Pass 分支，不重建几何/深度资源。
- 阴影图：**4096² × 2 层**方向光深度数组（CSM 用 2 层），约 **128 MiB**（2 × 4096² × 4B）。
- 新默认 `ShadowMapPCF16`：`shadowParameters.w = 5`，4×4 固定偏移、16 次 `SampleCmpLevelZero`；每次比较自带 2×2 双线性，固定偏移保证静态画面不闪烁。
- 4096 后每 texel 覆盖 30 / 4096 ≈ **7.3 mm**（2048 时约 14.6 mm）。
- 只有「第一盏可见、强度 > 0、Cast shadows 为真的方向光」消费光栅阴影图；其余方向光/局部灯要阴影只能 Analytic rays 或硬件光追；硬件通道覆盖所有投影灯（矩形灯解析路径 4 采样）。
- 选择是**会话状态**，不写 `.rascene`，重启回默认；截图/复现脚本必须显式设置。
- 入口：Scene 面板 `Shadow method` 下拉（10 项，clamp 0..9，`src/Editor/SceneEditor.cpp:1578-1584`）。硬件阴影由 `Project → Project Settings... → Rendering → Ray-traced shadows` 控制。

**代价（必须写清楚的三层）**

1. 每像素 16 次比较（PCF16），成本随覆盖像素线性增长；2×2/硬比较仍保留给低端设备/快速预览。
2. 显存：4096²×2 深度约 128 MiB（对比 2048²×2 约 32 MiB），且没有质量档位、没有级联动态分辨率。
3. **没有实测帧时间**：区间内没有任何「2×2 vs 4×4 / 2048 vs 4096」的耗时对比数字。文档和任务记录只写「每像素 16 次比较」的成本定性结论。文章不能写「性能下降 x%」，除非发布前用 Profiler 的 GPU Pass 计时补测（见 §7）。

**与 AA 的关系（文章可用的判断）**

- FXAA/TAA 只能平滑最终颜色，**恢复不了阴影图缺失的覆盖率**；阴影阶梯的主因是空间采样不足（2048 覆盖 30 世界单位 + 2×2 过滤），所以先加分辨率与核宽度，而不是靠后处理。
- TAA 的相机抖动不能当作阴影 AA 的主方案（只能缓慢平滑静止画面）；PCF16 选择确定性核而不是随机旋转，正是为了静态不抖。

### 2.3 材质深度/剔除与「硬件通道门控」

- 材质新增 `Cull`（Back/Front/Off）、`ZTest`、`ZWrite`（`MaterialAsset`，`include/RestArtEngine/Assets/AssetLibrary.h:147-162`）；`Cull` 取代旧 Two-sided 复选框，旧资产 `twoSided` 仍兼容。三者即时预览，Apply/Save/Discard 语义与数值参数一致。
- `hardwareDepthCompatible() = depthWrite && (ZTest == Less || LessEqual)`。**任一可见材质不兼容，整帧硬件通道停用**：DXR 阴影/反射/GI 与独立硬件图像全部退回光栅，并在状态里报「Hardware ray tracing inactive: material 'X' uses a raster-only depth state.」
- 这条门控同时影响 AA：硬件图像预期为假时，TAA 不再被强制回退 FXAA（`SceneRenderer.cpp:1829-1841`）。也就是说「把材质 ZWrite 关掉」会让整个硬件通道消失，副作用比预期大——这是很值得写进边界的连锁反应。
- 千万面验证（`933e2d7` 的证据）：10,000,024 三角形、DXR 实时 GI 32/32 样本、66 次 dispatch、1920×1080、RTX 5060、Debug + 图形验证、validation 0；首次大场景构建+首帧约 10.26 s，稳定 CPU 提交中位 0.679 ms / 同步墙钟中位 15.46 ms（含 DXR/Bridge 等待），DXGI 进程本地占用约 2.14 GB（前 0.113 GB）。**注意这是 2026-10-29 的 2×2 PCF + 2048 阴影图配置**，不是 4096/4×4 下的数字。

### 2.4 三角面数统计

- 三个显示点同一快照：Scene Overview、Scene Viewport 只读叠加、Profiler 的 Live renderer。
- **Scene triangles**：按 Actor 实例累加 `indices.size()/3`；包含隐藏实例，共享 Mesh 的多个实例分别计数；未被引用资产/缺失 Mesh 不计；缺材质不影响拓扑总数。
- **After clipping (GPU)**：只测主视角 Forward geometry / GBuffer 通道的 `CPrimitives`，用 D3D11 四槽 `PIPELINE_STATISTICS` 查询、`GetData(...DONOTFLUSH)` 异步读取；不含阴影、描边、全屏三角形、工具预览。裁剪可拆分三角形，所以后裁剪数可能大于输入数；不是深度/遮挡后的可见面数。
- 状态诚实：`Pending` / `Unavailable` / `NoViewport` / `N/A` 不显示为 0；环满跳过采样而不等待/复用；resize、显示路径切换、隐藏视口都会废弃旧样本。
- **边界**：完整硬件光追图像覆盖时显示 `N/A`；原生 D3D12 的 GPU 裁剪统计**未实现**（`GeometryStatistics.inl:55-58` 明确报 Unavailable），只有拓扑总数可用。纯硬件成图 N/A，Realtime GI 的光栅主可见性仍能统计。

### 2.5 诊断工具（Profiler / Frame Inspector / Runtime / 帧捕获）

**入口**

- 菜单：`Debug → Profiler... / Frame Inspector... / Runtime...`，以及 `Debug → Capture next scene frame`；菜单里明确写「F9 saves a screenshot; frame capture stores renderer resources.」（`src/Editor/SceneEditor.cpp:991-1001`）。
- 底栏 `Tools` 弹出菜单也有 Diagnostics / Frame Inspector / Project Settings；`Diagnostics` 按钮直接打开 Profiler 页（`src/Editor/EditorStatusBar.cpp:184-198`）。
- 工具窗可悬浮、可拖出主窗口（`c86a6de` 之后）。

**Profiler / CPU Trace**

- 有界录制：**65,536 事件**上限，满了只记丢弃数、不覆盖；`Start` 清空并开始，`Stop` 保留，`Clear` 清空但保留开关；导出 Chrome Trace JSON（`--trace-output <file.json>` 也能自动录主循环）。
- 最近 **120 帧** wall time 曲线（含 Present/等待，不是 CPU 活跃时间）；UI 用最近 **4096** 个完成事件画线程时间线，事件表每帧最多 **256** 行；嵌套是包含时间，自身耗时用同线程直接子区间并集扣除。
- GPU：D3D11 用每帧 disjoint + Pass 边界 timestamp（每次最多 16 个 Pass）；D3D12 用主队列 query heap + `EndQuery/ResolveQueryData` + fence；结果**带原 Frame ID 延迟返回**，`Pending`/`Unavailable`/`Disjoint` 不显示成 0 ms；`gpuMs = (t_end - t_start) × 1000 / frequency`。
- Trace JSON 不含 GPU query。

**Frame Inspector / 帧捕获**

- 捕获**下一次有效主场景帧**；材质球、Asset Details、场景缩略图不消费请求；一次 `render()` ≠ 应用一帧。
- 能看：Frame ID、后端、管线、Shader revision、尺寸、相机投影/近远裁；Pass 列表与 CPU 起止/读写资源；每个 Draw 的 Event ID、Pass、Actor/Mesh/Material ID 与名称、索引/顶点数、first index/base vertex、材质 slot；PSO 深度/剔除/绕序、viewport、附件、采样槽、顶点/索引流、VS/PS 常量字节与版本（十六进制 + float32 解释）；捕获资源的 Pass/Before/After/Final 边界、格式、尺寸、层号与 raw 副本（CSM 两层分别保留）；最近 CPU Trace 快照 + 同帧 GPU 计时。
- 预算：UI raw 16–256 MiB，API 硬顶 256 MiB（raw + 显示纹理合计）；Draw 事件上限 65,536；常量快照 8 MiB；超预算明确标 partial 并保留上一有效捕获。
- 离线包 `.raframe`：版本化二进制容器，metadata ≤16 MiB、payload ≤256 MiB、条目 ≤4096；严格校验长度/版本/字段/尺寸/校验值；损坏/超预算加载失败且保留上一有效捕获；**能离线看冻结资源，不是 GPU 可回放文件**。
- `Export metadata JSON...` 只导事件与描述、不含图像，不能重新打开成完整捕获。
- 捕获失败/预算失败/Shutdown 都有事务语义；Clear 只释放诊断数据，不动工程资产。

**Runtime**

- 结构化消息：单调 ID、Frame ID、进程内稳定 Thread ID、单调时钟、Info/Warning/Error、分类；最多 512 条、溢出计数；分类 128B、文本 8192B 且按 UTF-8 边界截断。
- 图形 Debug 消息单独读当前 D3D11/D3D12 InfoQueue 最近 128 条，不是 stdout/stderr 全量重定向。
- 进程内存用 `K32GetProcessMemoryInfo`（working set / private committed）；Mesh/软件射线缓存字节是**逻辑估算**，不是显存驻留；RHI 计数是累计执行量。

**数据视图**：视口调试模式（Lit/Unlit/Base Color/Roughness/Metallic/Specular F0/World Normal/Position/Linear Depth/GBuffer/主深度等），数据视图不受曝光影响；AA 对 `debugView >= 2` 关闭。

## 3. 现有证据评估

下表路径相对仓库根，全部在 `artifacts/`（本机忽略，未提交）。`A期` 的定义见 §0.2。

| 证据 | 能证明什么 | 等级 | 备注 / 发布前动作 |
| --- | --- | --- | --- |
| `artifacts/antialiasing/{d3d11,d3d12,hybrid,v3}/anti-aliasing.json` + `v3/{gpu11,gpu12,gpuHybrid}.log` | `--aa-self-test` 在 D3D11 / 原生 D3D12 / D3D11+DXR 三条后端执行：AA 本体全 PASS（GI 策略检查只在 hybrid 执行，11/12 为 SKIP/原因文本）；质量数字：边缘 ROI MAE（0..255）Off 23.33 → FXAA 15.78 → TAA(48 帧) **7.38**，3666 个边缘像素；相机绕行 16 帧（yaw 0.008 rad/帧）TAA 16.63 vs Off 23.27；覆盖历史失效、离屏预览、热编译成功/失败；D3D12 validation errors 0 | A期 | b142549 时点；`artifacts/antialiasing/d3d12/anti-aliasing.json` 里 `dxr.skipped:true`（**当时原生 DXR 尚未接通**）。测试图只有 **192×144**，4× 超采样参考 768×576 |
| `artifacts/antialiasing/v3/gpuHybrid.log` | 「Progressive GI bypasses AA; realtime GI explains TAA→FXAA fallback without jitter resets」PASS | A期 | 唯一直接覆盖「AA + GI 回退」的运行证据 |
| `artifacts/native-dxr-aa/anti-aliasing.json` + bmps | 原生 DXR 接通后的 AA 复验（`dxr:「executed」`），多了上一行的 GI 策略检查；仍是同一套 192×144 图 | A期 | `64a7c97` 时点；质量数字与 b142549 完全相同（同一测试场景） |
| `artifacts/antialiasing/ui-resume/{aa-ui-report.json,*.bmp}` | `--aa-ui-self-test`：真实 combo 切 Off/FXAA/TAA、按住拖动权重、Save 往返保留 AA/后端/GI/工程元数据；4 张 **1440×900** 主窗口真实 GPU 截图（黑/深蓝/窄窗/已保存） | A图 | 图上能看出「Effective/History/原因」；发布配图优先用这组或重拍 |
| `artifacts/shadow-aa/deferred_shadows_{map,pcf16,pcss,analytic,csm2,gtao,contact,disabled}.bmp` | 同一台机器同一场景的 8 种阴影捕获（1440×900），EditorSmoke 断言「PCF16 与 Disabled 不同」、各阴影模式生成成功 | A期 | 只是「有变化」断言，不是质量指标；`map` vs `pcf16` 可作为 2×2 对照 |
| `docs/images/shadow-pcf-compare.png`（提交于 `8bbd1c9`，179,951 B）、`docs/images/shadows-compare.png`（176,699 B） | 已提交公开文档的 2×2 / 4×4 与多方案阴影对比图 | A图 | 来源是上面的捕获裁剪；发布前核对裁剪区域/caption，别写「完整帧」 |
| `artifacts/shadow-aa/diagnostics/diagnostics-report.json` + `frame-metadata.json` + 25 张 5 通道 BMP | 诊断工具对 5 个资源 × RGB/R/G/B/A 全部通道的真实 GPU 回读；捕获冻结、异步 GPU 帧身份 | A期 | 2026-10-29 首版；不是最终 `.raframe` 版 |
| `artifacts/triangle-statistics/delivery/smoke.log` + `diagnostics/diagnostics-report.json` | 31 条 geometry case 全部 PASS、`gpuReady=true`、D3D11 validation 0；Fwd/Deferred、视锥开/关、共享 mesh、隐藏实例、空场景、缺材质、阴影/描边排除、Profiler 关闭、near-plane 1→2 拆分、纯硬件 N/A、Resize 失效 | A期 | 任务记录另有一次「提交树 29 cases」，与 delivery 的 31 条不是同一次；引用时写清来源 |
| `artifacts/render-scale-depth-cull/{scale-debug,scale-release}/render-scale-report.json` | 10,000,024 三角形、`sceneTriangles==input==postClip`、66 次 DXR dispatch、32/32 样本、1920×1080、DXGI 本地占用 2.14 GB、首帧 10.26 s、稳定 CPU 提交中位 0.679 ms、同步墙钟中位 15.46 ms、validation 0 | A期 | **2×2 PCF + 2048 阴影图 + hybrid DXR**，非 4096/4×4、非原生 DXR |
| `artifacts/render-scale-depth-cull/material-state/material-render-states.json` | Cull Off/Front/Back、镜像 Actor、九种深度状态、相机视锥剔除（输入 4→2）、反射/阴影射线接受背面、DXR 候选过滤、非标准深度状态保留硬件请求并恢复累积；validation 0 | A期 | 与 §2.3 的门控一一对应 |
| `artifacts/render-scale-commit/editor-v2/diagnostics-report.json`、`artifacts/diagnostics/commit-editor/*` | 提交后诊断回归：捕获、显示通道、异步 GPU 结果、几何统计 | A期 | 2026-10-29 首版诊断 |
| `artifacts/inspector-v4/{d3d11,d3d12}.log`、`ui-d3d12-final.log`、`final-ui-review.png`、`ctest-final.log` | 终版 Inspector：原生 D3D12 详细 Draw/常量/PSO、同捕获 Frame ID 的 GPU 计时 Ready、冻结/预算/损坏事务、CSM 两层、离线包往返、Clear；UI 三页签双主题 760/300 宽；CTest **29/29**（6.21 s） | A期 | 2026-11-19 时点（`6a243b2`）；`final-ui-review.png` 是拼接审阅图，不等于单张运行截图 |
| `artifacts/inspector-v4/hardware-rt.log` | 混合硬件光追 **251 次真实 dispatch**、graphics errors 0 | A期 | 非原生 DXR |
| `artifacts/inspector-v4/render-image-comparison.json` + `render-regression.log` | 严格 D3D11 13 张非 UI 图与基准**逐字节一致**、14 帧退出 0/错误 0 | A期 | 工具改动不影响光栅画面的证据 |
| `artifacts/status-bar/v4/editor/...` | 底栏/Cmd/Output Log/Diagnostics/Tools 的 1440 与 980 宽、双主题、150% 缩放截图；编辑器自测「Diagnostics ...」用例 PASS | A期 | 2026-10-29 状态栏任务；工具窗 UI 的早期证据 |
| `artifacts/floating-windows/*` | 浮窗越界、SceneViewport 独立目标、跨窗拖放的真实窗口证据 | A期 | 主要给 GUI 小节；引用前确认不是本轮重跑 |
| `artifacts/native12-startup-matrix/`、`native12-*` | 原生 D3D12 启动矩阵/回归 | A期 | **不证明 AA/阴影**；AA 启动修复的对口证据是 antialiasing/v3 的 d3d12 日志 + v4 任务记录 |
| `local/docs/experience/AntiAliasing.md`、`ShadowFiltering.md`、`NativeDiagnostics.md` | 可复用的原因/规则/边界表述 | 经验 | 引用其结论时仍需自己核对源码与证据 |

## 4. 源码片段候选（路径 + 提交 + 行号，5–20 行）

片段为候选稿：行号指向提交中的原始位置，缩进已按代码块整理（复制进正文前再与 `git show <commit>:<path>` 对照一次）。

### 4.1 4×4 PCF 核（阴影主证据）

`Shaders/Private/Scene.hlsl` @ `26aaf1f`，L481–491（`eaf4193` 引入）：

```hlsl
    if (shadowParameters.w > 4.5 && shadowParameters.w < 5.5)
    {
        // Deterministic 4x4 grid. Each comparison is already bilinear (2x2
        // hardware PCF), so the effective footprint is eight texels wide;
        // fixed offsets avoid temporal shimmer on still shadows.
        [unroll] for (int y = 0; y < 4; ++y)
            [unroll] for (int x = 0; x < 4; ++x)
                visibility += shadowMap.SampleCmpLevelZero(shadowSampler,
                    float3(uv + texel * float2(x - 1.5, y - 1.5), cascade), depth);
        return visibility / 16.0;
    }
```

写法要点：`shadowParameters.w` 沿用一个常量位做过滤分支，Forward/Deferred 共用同一张阴影图；`texel = 1/4096`。**注意注释里的「eight texels」与源码推导不一致**，见 §7.1-4。

### 4.2 TAA 邻域钳制 + 运动加权（时间重建主证据）

`Shaders/Private/AntiAliasing.hlsli` @ `26aaf1f`，L116–124：

```hlsl
float3 low=current, high=current;
[unroll] for (int y=-1;y<=1;++y) [unroll] for(int x=-1;x<=1;++x) {
    const float3 neighbour=aaSource.Load(int3(AaClampPixel(p+int2(x,y)),0)).rgb;
    low=min(low,neighbour); high=max(high,neighbour);
}
const float3 history=clamp(AaBilinear(aaHistory,historyPixel).rgb,low,high);
const float motionPixels=length(historyPixel-input.position.xy);
const float currentWeight=max(aaParameters.x,saturate(motionPixels*.35));
outputColor=lerp(history,current,currentWeight);
```

### 4.3 TAA 抖动序列（Halton + 裁剪空间偏移）

`src/Renderer/AntiAliasing.inl` @ `26aaf1f`，L116–123：

```cpp
// Apply clip-space offsets to x/y using w, for perspective and orthographic.
const unsigned sample = aaHistoryFrames % 16 + 1;
const float jitterX = (aaHalton(sample,2)-.5f)*2/viewport.z;
const float jitterY = (aaHalton(sample,3)-.5f)*2/viewport.w;
aaJitterPixels = XMFLOAT2(jitterX*viewport.z*.5f,-jitterY*viewport.w*.5f);
XMFLOAT4X4 offset; XMStoreFloat4x4(&offset,XMMatrixIdentity());
offset._41 = jitterX; offset._42 = jitterY;
projection = projection * XMLoadFloat4x4(&offset);
```

### 4.4 回退规则（「谁强制 FXAA」的唯一源码依据）

`src/Renderer/AntiAliasing.inl` @ `26aaf1f`，L82–96：

```cpp
if (hardwareImage && settings.globalIllumination.method == GlobalIlluminationMethod::PathTracing &&
    settings.globalIllumination.mode == GlobalIlluminationMode::Progressive && settings.debugView == 0) {
    status.effective = AntiAliasingMethod::Disabled;
    status.reason = "Progressive path tracing already accumulates jittered primary samples.";
} else if (settings.debugView >= 2) {
    status.effective = AntiAliasingMethod::Disabled;
    status.reason = "Data debug views retain unfiltered pixel values.";
} else if (status.requested == AntiAliasingMethod::TAA && settings.offscreenTarget) {
    status.effective = AntiAliasingMethod::FXAA;
    status.reason = "Tool previews use FXAA and do not consume the main TAA history.";
} else if (status.requested == AntiAliasingMethod::TAA && hardwareImage) {
    status.effective = AntiAliasingMethod::FXAA;
    status.reason = "DXR image alignment currently requires stable primary rays; using FXAA to preserve GI history.";
}
```

### 4.5 启动修复：FXAA 不缓存调用者目标（「稳定」主证据）

`src/Renderer/AntiAliasing.inl` @ `26aaf1f`，L147–156（节选）：

```cpp
rhi::RenderPassDesc pass;
pass.name = temporal ? "TAA resolve" : "FXAA resolve";
pass.colors = {{temporal ? aaHistoryImages[1-aaHistoryRead] : target,rhi::LoadOp::Clear}};
// Only the temporal history image may outlive this pass. FXAA resolves into
// the caller's target (often the swapchain); caching that handle would keep a
// swapchain image borrowed and make a later ResizeBuffers fail.
aaResolvedImage = temporal ? pass.colors[0].texture : rhi::TextureHandle{};
pass.reads = {{aaSourceImage,7},{sceneDepthImage,6}};
if (temporal) pass.reads.push_back({aaHistoryImages[aaHistoryRead],8});
commands.beginRenderPass(pass);
```

### 4.6 AA 的 Pass 位置（顺序证据）

`src/Renderer/Pipelines/ScenePipeline.cpp` @ `26aaf1f`，L161–174：

```cpp
if (inputs.depthOfField)
    add(RenderPassKind::DepthOfField, "Screen-space depth of field",
        rasterColor | PipelineResource::SceneDepth,
        rasterColor | PipelineResource::DepthOfFieldSource);
if (inputs.antiAliasing) {
    add(RenderPassKind::AntiAliasing, inputs.temporalAntiAliasing ? "TAA resolve" : "FXAA resolve",
        rasterColor | PipelineResource::SceneDepth | (inputs.temporalAntiAliasing
            ? PipelineResource::PreviousAntiAliasingHistory : PipelineResource::None),
        inputs.temporalAntiAliasing ? PipelineResource::AntiAliasingHistory : PipelineResource::SceneColor);
    if (inputs.temporalAntiAliasing)
        add(RenderPassKind::AntiAliasingPresent, "TAA present",
            PipelineResource::AntiAliasingHistory, PipelineResource::SceneColor);
}
```

### 4.7 材质深度/剔除与硬件门控

`include/RestArtEngine/Assets/AssetLibrary.h` @ `26aaf1f`，L147–162：

```cpp
    // New materials cull back faces; legacy files without this field retain
    // their previously implicit two-sided visibility when deserialized.
    bool twoSided = false;
    bool cullFront = false;
    MaterialDepthTest depthTest = MaterialDepthTest::Less;
    bool depthWrite = true;
    [[nodiscard]] MaterialCullMode effectiveCullMode() const noexcept {
        return twoSided ? MaterialCullMode::Off : cullFront ? MaterialCullMode::Front : MaterialCullMode::Back;
    }
    void setCullMode(MaterialCullMode mode) noexcept {
        twoSided = mode == MaterialCullMode::Off;
        cullFront = mode == MaterialCullMode::Front;
    }
    [[nodiscard]] bool hardwareDepthCompatible() const noexcept {
        return depthWrite && (depthTest == MaterialDepthTest::Less || depthTest == MaterialDepthTest::LessEqual);
    }
```

`src/Renderer/SceneRenderer.cpp` @ `26aaf1f`，L2001–2012：

```cpp
for (const auto& actor : world.actors) {
    if (actor.light || !actor.visible || !validTransform(actor)) continue;
    const auto* mesh = assets.findMesh(actor.mesh.meshId);
    if (!mesh || mesh->indices.empty()) continue;
    meshAttributes::sections(*mesh, [&](std::uint32_t, std::uint32_t count, std::uint32_t slot) {
        const auto* material = resolveMaterial(assets, actor.mesh.materialForSlot(*mesh, slot), materialOverride);
        if (count && material && !material->hardwareDepthCompatible()) {
            hardwareDepthCompatible = false; incompatibleDepthMaterial = material;
        }
    });
    if (!hardwareDepthCompatible) break;
}
```

### 4.8 三角面数：场景总数与 GPU 后裁剪（工具主证据）

`src/Renderer/GeometryStatistics.inl` @ `26aaf1f`，L16–24：

```cpp
void beginGeometryFrame(const scene::World& world, const assets::AssetLibrary& assets) {
    ++geometryStatistics.frameId;
    geometryStatistics.sceneTriangles = 0;
    for (const auto& actor : world.actors) {
        if (actor.light) continue;
        if (const auto* mesh = assets.findMesh(actor.mesh.meshId))
            geometryStatistics.sceneTriangles += static_cast<std::uint64_t>(mesh->indices.size() / 3);
    }
}
```

同文件 L64–78（异步查询与状态）：

```cpp
D3D11_QUERY_DATA_PIPELINE_STATISTICS result{};
const HRESULT ready = context->GetData(slot.query.Get(), &result, sizeof(result),
    D3D11_ASYNC_GETDATA_DONOTFLUSH);
if (ready == S_FALSE) continue;
slot.busy = false;
if (FAILED(ready)) {
    geometryQueriesUnavailable = true;
    discardGeometrySamples(GeometrySampleStatus::Unavailable, "GPU primitive statistics queries are unavailable.");
    return;
}
if (slot.epoch != geometrySampleEpoch || slot.frameId < geometryStatistics.gpuFrameId) continue;
geometryStatistics.gpuFrameId = slot.frameId;
geometryStatistics.inputTriangles = result.IAPrimitives;
geometryStatistics.postClipTriangles = result.CPrimitives;
geometryStatistics.status = GeometrySampleStatus::Ready;
```

### 4.9 GPU Pass 计时（诊断工具主证据）

`src/Renderer/RenderDiagnostics.inl` @ `26aaf1f`，L106–116：

```cpp
std::array<UINT64, 2 + maxDiagnosticPasses * 2> ticks{};
bool ready = true;
for (std::size_t i = 0; i < 2 + slot.passes.size() * 2; ++i) {
    if (context->GetData(slot.timestamps[i].Get(), &ticks[i], sizeof(UINT64),
        D3D11_ASYNC_GETDATA_DONOTFLUSH) != S_OK) { ready = false; break; }
}
if (!ready) continue;
const double scale = 1000.0 / static_cast<double>(disjoint.Frequency);
auto gpuPasses = slot.passes;
for (std::size_t i = 0; i < gpuPasses.size(); ++i)
    gpuPasses[i].gpuMs = static_cast<double>(ticks[3 + i * 2] - ticks[2 + i * 2]) * scale;
```

### 4.10 有界 Trace（工具主证据 / 架构）

`include/RestArtEngine/Core/TraceProfiler.h` @ `26aaf1f`，L42–57：

```cpp
    explicit TraceProfiler(std::size_t eventCapacity = 65536);
    TraceProfiler(const TraceProfiler&) = delete;
    TraceProfiler& operator=(const TraceProfiler&) = delete;

    // Start a new bounded recording. Stop retains data; clear preserves recording state.
    void start() noexcept;
    void stop() noexcept;
    void clear() noexcept;
    [[nodiscard]] bool isRecording() const noexcept { return recording_.load(std::memory_order_relaxed); }
    // Main application loop only. IDs advance even while tracing is disabled.
    void beginFrame() noexcept;
    void endFrame() noexcept;
    [[nodiscard]] std::uint64_t currentFrameId() const noexcept { return frameId_.load(std::memory_order_relaxed); }
    [[nodiscard]] TraceSnapshot snapshot(std::size_t maxEvents = 512) const;
    // Exports all retained events as Chrome Trace JSON (microseconds, steady clock).
    bool save(const std::filesystem::path& path, std::string& error) const;
```

## 5. 公式候选

按写作规范「一篇文章 2–5 个公式」，建议从下面选 3–4 个；每个都要能对上代码或数字。

**（1）4×4 PCF 的可见度（阴影主公式）**

$$
V(u,v)=\frac{1}{16}\sum_{j=0}^{3}\sum_{i=0}^{3} C\!\left(u+(i-1.5)\,t,\; v+(j-1.5)\,t\right),\qquad t=\frac{1}{4096}
$$

$C$ 是单次带双线性过滤的深度比较（`SampleCmpLevelZero`），$t$ 是一个 shadow texel 的 UV 宽度。对应 `Scene.hlsl:488-490`。

**（2）阴影 texel 的世界尺寸（为什么先加倍分辨率）**

$$
w_{\text{texel}}=\frac{30\ \text{m}}{N},\qquad N=2048\Rightarrow 14.6\ \text{mm},\quad N=4096\Rightarrow 7.3\ \text{mm}
$$

对应「2048² 覆盖 30 世界单位、每 texel≈1.46 cm」的旧口径与 eaf4193 的翻倍决策。

**（3）4×4 核的等效覆盖（需要先核对再写）**

按源码的偏移与双线性宽度：

$$
W_{\text{kernel}}=(N_{\text{taps}}-1)\cdot 1\ \text{texel}+2\ \text{texel}=3+2=5\ \text{texel}
$$

文档与注释写「约 8×8 texel」。两者不一致（见 §7.1-4）；在核对前不要直接抄 8×8。

**（4）TAA 混合权重（时间重建主公式）**

$$
C_{\text{out}}=\operatorname{lerp}\!\left(\operatorname{clamp}\!\left(H,\; \min_{3\times3}C,\; \max_{3\times3}C\right),\; C_{\text{cur}},\; w_{\text{eff}}\right)
$$

$$
w_{\text{eff}}=\max\!\left(w_{\text{req}},\; \frac{1}{n+1},\; \operatorname{saturate}(0.35\,d_{\text{motion}})\right)
$$

$w_{\text{req}}$ 是项目设置里的 Current frame weight（0.02–1，默认 0.1），$n$ 是已累积帧数（启动时抬高权重，`AntiAliasing.inl:137`），$d_{\text{motion}}$ 是历史像素到当前像素的距离（运动时抬高权重减少拖影）。$H$ 是重投影后的历史颜色，3×3 是当前帧邻域。

**（5）Halton 抖动与重投影（可选，公式感强但对读者收益一般）**

$$
j_x=\left(H_2(n)-0.5\right)\frac{2}{W},\quad j_y=\left(H_3(n)-0.5\right)\frac{2}{H},\quad n=\text{frame}\bmod 16+1
$$

**（6）GPU Pass 时间换算（工具公式，适合放工具节）**

$$
t_{\text{pass}}\,[\text{ms}]=\left(T_{\text{end}}-T_{\text{start}}\right)\cdot\frac{1000}{f_{\text{timestamp}}}
$$

**（7）三角面数口径（工具节，可写成文字）**

$$
N_{\text{scene}}=\sum_{\text{actor}}\left\lfloor \frac{\text{indexCount}}{3}\right\rfloor,\qquad N_{\text{clip}}=C_{\text{Primitives}}\ (\text{可小于、等于或大于 }I_{\text{APrimitives}})
$$

后裁剪可能大于输入是 GPU 裁剪可拆分三角形的定义结果，不是 bug。

**（8）AA 质量指标（证据口径）**

$$
\text{MAE}=\frac{1}{3\,|\text{ROI}|}\sum_{p\in\text{ROI}}\sum_{c\in\{R,G,B\}} \left|I_{\text{AA}}(p,c)-I_{\text{ref}}(p,c)\right|
$$

$I_{\text{ref}}$ 是 4× 超采样参考降采样，ROI 是高对比边缘及其 1 像素环（`app/AntiAliasingSmoke.cpp:81-125`）。

**不建议用公式的**：4096 显存 128 MiB（直接写数字）、10M 三角形的生成参数（写表格或一句话）。

## 6. 建议的正文切分

### 6.1 AA 与阴影：建议分成两节，但允许合并

**推荐：分成「抗锯齿」与「阴影」两节。** 理由：

- 两节都有独立源码块、独立证据、独立边界，且各自能写满 600–1000 字：AA 有「三种模式 + TAA 依赖什么 + 回退规则 + 启动崩溃修复」；阴影有「10 种方案 + 4096/4×4 + 代价 + 与 AA 的分工」。
- 合并成「画质：边缘与阴影」会超过单节字数上限（>1500 字），或者被迫把 TAA 的依赖/回退压成边界句，读者最想知道的「为什么 TAA 不能和 DXR GI 同时开」会讲不透。
- 两节共用一条叙事线（**采样不足先修采样，不要用后处理假装修好**），这是很好的跨节呼应，但不等于要合并。

**允许合并的条件**：如果全篇技术模块已经到 5–6 个（比如工程/后端、GI、编辑器/资产、再加工），则合并为「画质：抗锯齿与阴影」一节，取舍是：
- 讲透阴影（4096 + 4×4 + 代价）与 AA 的一条主线（TAA 为什么不配 DXR），
- 把 FXAA/回退分支压成一段 + 边界列表；
- 源码只留 1 段（PCF 或 TAA 二选一），另一段移到证据截图。

### 6.2 工具类：建议独立一节，不要塞进「其他变化」

**推荐：单独一节「诊断与帧捕获：自己的 RenderDoc 长什么样」。** 理由：

- 读者可感知：Debug 菜单/底栏 Tools、Profiler 时间线、Frame Inspector 的 Draw/常量/资源、`.raframe` 离线包、三角面数统计，都有真实 UI 证据。
- 有明确的取舍/限制：只记录引擎自己的 RHI 事件、不是 API 拦截、不能逐 Draw 重放、不是 RenderDoc、GPU 时间不含 Present/独立 DXR/UI。
- 有跨模块故事：这些工具后来反过来证明了 AA 与阴影的代价（GPU Pass 计时、三角面数、10M 规模），可以作为「先有测量再优化」的叙事。

「其他变化」只适合放一句话级的内容（文档同步、命名、浮窗、快捷键）。工具类如果塞进其他变化，等于浪费了本期最强的一组 UI 截图。

### 6.3 与其他审计的边界

- **10M 三角形验证**同时是 GI 与工具的证据。建议只在一个模块写透：如果 GI 节用它证明「实时 GI 撑得住 10M」，工具节就只用「三角面数统计在同一 10M 场景里读到 scene/input/postClip 全为 10,000,024」；不要两节各写一遍完整数字。
- **材质 depth/cull**主要属材质/资产节；本审计建议只在阴影节写「ZWrite Off 会让整帧硬件通道停用，TAA 的回退条件也随之改变」这一条边界，细节留给材质节。
- **浮窗（c86a6de）**属 GUI/编辑器节；工具节最多一句「诊断窗可拖到副屏」。

### 6.4 建议的模块—证据—源码对应

| 模块 | 首选定点 | 源码块 | 证据 | 边界 |
| --- | --- | --- | --- | --- |
| 抗锯齿 | TAA 能做什么、不能做什么（无逐物体 MV、DXR GI 强制 FXAA、启动崩溃） | TAA 邻域钳制或回退规则 | `aa-ui-resume` 截图 + `anti-aliasing.json` 质量数字 | MSAA/HDR/MV/跨平台未做；描边不经过 AA |
| 阴影 | 先修采样（4096+4×4）而不是靠后处理 | PCF16 块 | `shadow-pcf-compare.png`（已提交）+ 1440×900 捕获 | 16 次比较 + 128 MiB；无质量档位；无实测帧时间 |
| 诊断工具 | 自己的帧检查器与测量闭环 | GPU Pass 计时 或 三角统计 | `inspector-v4` UI 图 + `diagnostics-report.json` | 不是 RenderDoc；无重放/Pixel History/采样 profiler |

## 7. 待验证清单与常见坑

### 7.1 发布前必须重跑（A 期 → 本期 A）

1. **AA 三后端重跑**（`26aaf1f`，独立 build 与独立工程夹具）：
   ```powershell
   & $exe --aa-self-test --backend d3d11  --capture-dir <dir>\aa-d3d11
   & $exe --aa-self-test --backend d3d12 --no-backend-fallback --capture-dir <dir>\aa-d3d12
   & $exe --aa-self-test --backend d3d11Dxr --capture-dir <dir>\aa-hybrid
   & $exe --aa-ui-self-test --backend d3d12 --capture-dir <dir>\aa-ui
   ```
   预期：三份 json 全 `passed:true`；原生 D3D12 那份 `dxr` 不再是 `skipped`（原生 DXR 已接通），GI 策略检查应为 PASS。
2. **正常启动 + resize**（AA 启动修复的完整证据）：加载窗→编辑器窗、D3D12 validation 0、`--frames 5` 退出 0。
3. **4096 + 4×4 PCF 的代价实测**：同一相机、同一场景，在 Scene 面板切 `2×2 PCF` / `4×4 PCF`，用 Profiler 的 `Shadow map` GPU Pass 时间做 A/B，记录分辨率/构建/设备；再确认显存（DXGI 查询）与 128 MiB 估算是否一致。**现在没有任何耗时数字**。
4. **4×4 核覆盖口径**：通过 `--editor-self-test` 的 PCF16 捕获或 GPU 回读，量一次阴影边缘过渡宽度；把「8×8 texel」改成与源码/实测一致的表述（当前推导约 5×5）。
5. **AA 质量数字的适用范围**：现有 7.38/15.78/23.33 是 **192×144** 测试图的边缘 ROI MAE。文章配图若用 1440×900，需要重拍同机位 Off/FXAA/TAA 对比，并注明「数字来自 192×144 质量夹具，截图来自 1440×900 场景」，不要混成一句话。
6. **TAA + 光栅 SSGI/DDGI**：源码允许 TAA 与光栅 GI 同开（无硬件图像），但区间内没测过。建议在 Sandbox 用 Deferred + SSGI（D3D11）开 TAA，看收敛/抖动是否可接受；结论不确定就写「未验证」。
7. **原生 D3D12 光栅 TAA**：`b142549` 验收时原生 DXR 还没合并；`64a7c97` 只做了 DXR 偏移的 AA 回归。若文章写「原生 D3D12 上 TAA 可用」，需重跑 `--aa-self-test --backend d3d12`。
8. **10M 与 4096 阴影不能混写**：10M 证据是 2×2 + 2048 + hybrid DXR。若文章要写「4×4 阴影 + 10M GI」，必须重跑 `RenderScaleSmoke`（或明确写「两个数字来自不同配置」）。
9. **诊断工具终版重跑**（若工具节用终版 UI）：`--inspector-self-test`/`--inspector-ui-self-test` 在 d3d11 与 d3d12 各一次；`--editor-self-test` 仍可能卡在原生窗口 focus（桌面前台竞争），不能当 AA/阴影回归。
10. **文档口径**：发布前修 `docs/RenderPipeline.md`（仍写 2048²、特性表缺 PCF16）与 `docs/EditorGuide.md:282`（阴影方案列表缺 4×4 PCF）。文章若引用这两处会与 `docs/ShadowMethods.md`/`docs/Architecture.md` 自相矛盾。

### 7.2 常见坑（写作时容易写错）

1. **重影（ghosting）**：TAA 没有逐物体运动矢量，物体运动、材质/灯光编辑、场景编辑都会让历史失效（保守重置）而不是正确重投影。写「TAA 支持动态场景」是错的；正确写法是「TAA 主要服务静止/相机运动画面，物体运动靠历史失效规避拖影，代价是运动时更不稳定」。
2. **静止抖动（shimmer）**：TAA 第一帧/历史失效帧用 FXAA 兜底；PCF16 用固定偏移保证静态阴影不抖；但「编辑期间每帧重置历史」会让画面在拖动参数时看起来更毛。启动权重 `max(w, 1/(n+1))` 是为了前几帧更快收敛，不是「越高越好」——调高权重会牺牲稳定性。
3. **AA 与 GI 的先后**：AA 在光照/GI/硬件 resolve/景深之后、描边之前；但**抖动是在场景渲染前注入投影矩阵的**，所以 TAA 帧的光栅 GI 看到的是抖动后的 VP，而硬件图像路径被强制 FXAA 正是为了让 DXR GI 历史不接受逐帧抖动。不要把「AA 在最后」理解成「GI 不受 AA 影响」。
4. **4096 显存/性能**：128 MiB 是两层深度；低显存设备、集显、移动端要显式降级到 2×2/3×3/硬比较。每像素 16 次比较是全屏成本，分辨率越高越贵；没有质量档位和动态分辨率。文章不要写「几乎免费」。
5. **「4×4 PCF 覆盖 8×8 texel」**：这是文档/注释的说法，按源码偏移（间距 1 texel）与双线性宽度（2 texel）并集约 **5×5**。要么改注释/文档，要么在文章中写「4×4 个双线性比较」，别把这个数字当卖点。
6. **Shadow method 不持久化**：属于会话状态，重启回默认 PCF16。复现步骤（「照做一遍」）必须显式写「在 Scene 面板选 4×4 PCF」，否则读者重开引擎看到的是默认值而不是他刚选的 2×2。
7. **Requested ≠ Effective**：UI 会显示请求与实际；在实时 DXR GI 下选 TAA 会显示 `Effective: FXAA` + 原因。文章必须解释这条，否则读者会以为开关坏了。
8. **F9 截图 ≠ 帧捕获**：F9 存合成后的窗口图；帧捕获存渲染资源（`.raframe`）。两者不要混称。
9. **工具的证据边界**：`.raframe` 能离线看资源，但不是 API 回放；GPU Pass 时间不含 Present/独立 DXR/UI；进程内存不是显存驻留；RHI 计数是累计量。这些在文章中要写成边界，不能省略。
10. **原生 D3D12 的三角面数**：GPU 裁剪统计未实现，会显示 Unavailable/N/A；拓扑总数仍可用。不要写「原生后端也有裁剪统计」。
11. **编辑器自测的 focus 失败**：`Native Content did not gain focus` 是桌面前台竞争，区间内多次出现；它不是 AA/阴影/诊断回归，不能拿它当失败证据，也不能用「重跑通过」掩盖首次失败。

## 8. 文档与源码不一致（发布前要处理）

| 位置 | 现状 | 与源码/其他文档冲突 | 建议 |
| --- | --- | --- | --- |
| `docs/RenderPipeline.md:62` | 「`ShadowMap` 2048² 方向光深度数组」 | `SceneRenderer.cpp` 已是 4096（`eaf4193`） | 改成 4096²；或文章避开该文档 |
| `docs/RenderPipeline.md:198` | 「设置 2048² 视口」 | 同上 | 同上 |
| `docs/RenderPipeline.md:246` | 特性表列 `ShadowMapPCF/Hard/PCF9/PCSS/CSM2` | 缺 `ShadowMapPCF16`（新默认） | 补 PCF16 行 |
| `docs/EditorGuide.md:282` | 阴影方案列表写「2x2 PCF、硬比较、3x3 PCF、PCSS…」 | 缺 4×4 PCF（新默认） | 补 4×4 PCF |
| `Shaders/Private/Scene.hlsl:483-485` 注释、`docs/ShadowMethods.md:11`、`docs/Architecture.md:224`、`docs/ShadowMethods.md:15` | 「约 8×8 texel 覆盖」 | 源码推导约 5×5（见 §5-3、§7.2-5） | 统一口径或实测后改文案 |
| `docs/AntiAliasing.md` | 只此一处写 AA；`RenderPipeline.md:124-128` 有简述 | 无冲突 | AA 文章以 AntiAliasing.md 为准 |

以上都是公开文档问题，本审计**没有修改**（只读任务）。写作时两种选择：先修文档再引用，或文章中只引用口径正确的 `docs/ShadowMethods.md` / `docs/Architecture.md` / `docs/Diagnostics.md`。

## 9. 红线提醒

- 本审计未构建/未运行、未改被跟踪文件；工作区 GI 修复是 volatile，**不算已验证**。
- `artifacts/` 是本机忽略目录，不能把路径写进公开文章，也不能提交。
- 图片只用真实运行截图；`docs/images/` 里已提交的阴影对比图可用，但要按实际参数写 caption（同场景、4096、裁剪区域），不要标成「完整 1440×900」。
- 10M 数字要带设备、分辨率、构建、配置（2×2/2048/hybrid DXR），不能外推到原生 DXR 或 4096 配置。
- DeepSeek 在文中写「补充模型」；不写 token/provider/本机绝对路径。
