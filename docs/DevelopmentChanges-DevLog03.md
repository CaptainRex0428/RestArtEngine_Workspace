# DevLog03 准备：范围、模块与证据计划

> 本页只保留本地，不提交、不发布。它是 DevLog03 的审计汇总与写作计划；逐提交细节分散在四份专项审计里，本页负责把它们拼成可执行的准备状态。
> 准备日期：2026-11-20（Asia/Shanghai）。写作规范 [ZhihuSeries](ZhihuSeries.md)，底稿 [ZhihuSeriesLedger](ZhihuSeriesLedger.md)。

## 0. 现在到哪一步

用户本轮要求：开始准备 DevLog03；等 GI 问题修好后再写正文；中间提交很多，重点讲 GI、RHI、抗锯齿、硬件光追等渲染层，UI 与其他简单开发只简单提。

本轮完成的是**准备**，不是正文：

- 确认起点、当前 HEAD、两期之间的 117 个提交和时间分布；
- 四份只读专项审计（GI / RHI-DXR / AA-阴影-工具 / UI-资产），全部只读，未构建、未运行引擎、未改任何被跟踪文件；
- 把 117 个提交逐条归到模块，找出四份审计没覆盖的 16 个提交并归类，做到 117/117 有归属；
- 定模块方案、证据现状、升 A 的重跑清单、媒体拍摄清单、文档漂移清单和待确认问题。

**结论**：现在可以停在「等 GI 修复提交」这一步。文章结构、源码候选、对比图方案和重跑命令都已就位；缺的是终点 commit 和最后的证据重跑。

**2026-11-21 用户确认**：正式终点取「GI 修复提交之后，再补一组公开文档漂移修复」的最后一个引擎提交；对外版本写 `v0.4.0`；计划发布日 `2026-11-23`（文件名日期同）；正文按**方案 A（6 个技术节）**。

工作区注意：审计期间 `Shaders/Private/Scene.hlsl`、`src/Renderer/SceneRenderer.cpp`、`Rhi.h`、`D3D11Rhi.cpp`、`D3D12Rhi.cpp`、`RhiInspection.h`、`tests/RhiInspectionTests.cpp`、`docs/GlobalIllumination.md` 和 Sandbox 资产持续被并发修改（GI probe 可视化收尾 + RHI instanced draw）。所有审计结论以提交 `26aaf1f` 为准，工作区改动不算已验证，也不进正文。**文档漂移修复不要现在做**：等工作区 GI 改动提交后再改公开文档，避免把两份改动混进同一个提交。

## 1. 边界

| 项 | 值 | 说明 |
| --- | --- | --- |
| 起点 | `4193f55`（2026-10-26） | DevLog02 正文头写的终点，按规范优先于日期兜底 |
| 上一期标签 | `DevLog02` = `cc68a1b`（同为 `v0.3.1`） | 比文章终点多两次收尾文档提交，正文没覆盖，也不在本期算引擎进展 |
| 当前区间终点 | `26aaf1f`（2026-11-20，SSGI/软件 DDGI 修复） | 只是当前 HEAD |
| 正式终点 | **GI 修复提交 + 文档漂移修复提交之后**（用户 2026-11-21 确认） | 用户选择先顺手修文档漂移再冻结；终点取这组提交里的最后一个引擎提交，写作/台账提交不算 |
| 区间提交数 | 117（含 1 个 merge `a46432b`） | 300 文件、+87442/−2323 行；vendor/ufbx 占大头 |
| 对外版本 | `v0.4.0`（2026-11-21 用户确认） | 程序内 `CMakeLists.txt`/`.raproject` 仍是 `0.2.0`，本次不改；文章头只写对外版本 |
| 文章日期 | `2026-11-23`（用户确认的计划发布日） | 文件名前缀等于发布日；实际改期要同步改名与底稿 |
| 时间分布 | 10-26:10、10-27:39、10-28:6、10-29:19、10-30:7、10-31:4、11-18:1、11-19:10、11-20:21 | 两个明显时间簇，叙事不能按 commit 顺序 |

区间里叠了三层工作，写正文时要分开：

1. **10-26～10-31 补课期**：选中描边、面板职责、内容浏览器与 `.rasset`/GUID、Asset Details 与网格 Slot、诊断工具首版、相机/五灯/网格属性/控制台集成、渐进 DXR GI 与实时 GI 首版、README 重写、Cornell Box 示例。
2. **11-18～11-19 后端期**：加载进度、原生 D3D12 主后端（RHI 契约 + D3D11 适配器 + D3D12 后端一次落地）、FXAA/TAA 与原生 D3D12 启动修复、4096²+4×4 PCF、原生 DXR（同 device/queue）、编辑器视口偏移修复。
3. **11-19～11-20 GI 期**：实时 PT 降噪（相机/逐物体重投影、多尺度空间滤波）、SSGI、DDGI、ReSTIR，以及它们连着的三轮修复。

## 2. 覆盖核对：117 个提交都有归属

四份审计的详细逐提交表：

| 审计文件 | 覆盖角色 | 提交规模 |
| --- | --- | --- |
| [audit-devlog03-gi](audit-devlog03-gi.md) | GI 主线 34 个 + 相邻支撑 7 个 + 被替换中间方案 12 条 | 约 481 行 |
| [audit-devlog03-rhi-dxr](audit-devlog03-rhi-dxr.md) | RHI/后端/DXR 主线 8 个 + 前置相邻 + 证据盘点 | 约 356 行 |
| [audit-devlog03-quality-tools](audit-devlog03-quality-tools.md) | AA、阴影、材质深度剔除、三角统计、诊断工具 | 约 597 行 |
| [audit-devlog03-ui-assets](audit-devlog03-ui-assets.md) | UI/编辑器/资产，归成 5 组 + 一段话建议 | 约 27 行（简报） |

四份审计合起来提到 108 个区间提交。剩下 **16 个**没有被任何专项展开，按提交内容归类如下（按标题与 diff stat 归类，未逐 diff 审核；它们都不单独成节）：

| 类别 | 提交 | 一句话 |
| --- | --- | --- |
| 仓库治理/文档归属 | `9239226`（26 文件，回收 AI 工作流/DevLog 到本地）、`ba7311a`、`8ad6255` | 公开库只留引擎说明与源码；写作资料本地化 |
| 上一期收尾文档 | `ffb7936` | DevLog02 的审计交接文档，属上期边界，不算本期引擎进展 |
| 协作工具 | `b7f77fe` | 可选的协作入口与同步包装脚本；对外文章不展开 |
| 构建/IDE | `6a3c2b2` | 把 HLSL 列进 solution，方便 IDE 编辑（不参与 MSBuild） |
| 测试夹具/清理 | `d87156f`（自测跑临时工程副本）、`8727ffa`（每轮重建场景夹具）、`eb833a6`（选可见材质拖拽夹具）、`cd021a8`（C4189 清理） | 都在“证据可信度”里用，不单独讲 |
| 启动/窗口小修 | `b446f64`（无边框加载窗 28% 宽、编辑器 80% 居中）、`a678dba`（Project Manager 居中主屏） | 归 UI/启动组，一句话带过 |
| 文档补条 | `fdc49b5`（材质球实时预览说明）、`06db9db`（材质放进 `.rasset` 的决定）、`bae6db9`（Outliner 眼睛行结构） | 与对应模块一句话同步，不单列 |
| 示例内容 | `0ebaaa8`（Sandbox 场景更新） | 示例资产更新，不当能力 |

另外，DevLog02 已写过的内容不在本期重复：Docking 布局持久化、视口矩形、Alt 组复制与 Undo、实例 Details 与材质窗口草稿/Two-sided、资源 GC 与 Capture、加载页外观。本期只接「真实加载进度」和「Scene/Details 分工」。

## 3. 模块提案

规范要求正文 = 协作方法 + 3～6 个技术模块，每模块 600～1000 字。按用户重点（GI、RHI、AA、硬件光追）给两套：

### 方案 A（推荐，6 个技术模块）

| # | 标题方向 | 核心内容 | 主要证据 |
| --- | --- | --- | --- |
| 0 | 这期怎么和 AI 一起做的 | M1–M5 分阶段、每阶段构建+GPU 测试+提交；先证明一条 D3D11 调用链再换 API；失败保留原画面；审计与实现分离 | 任务记录、角色/技能文件、失败日志 |
| 1 | 把一帧写成声明，再让两种 API 跑同一份契约 | `RenderPipeline.h`（17 种 Pass、20 个资源位）+ `RenderFeatures.h`（请求/能力/有效三层、6 态）；RHI 契约（139 行、无 D3D 类型、无 Compute）；后端选择与回退只包设备创建 | Pass 声明源码、FeatureState 源码、诊断面板同一张表、后端启动矩阵 6 案例 |
| 2 | 原生 D3D12 与原生 DXR：先换 API，再共享设备 | M2 用 13 张图逐字节一致证明 D3D11 真实执行；M3 原生 D3D12 不建 D3D11 device；M5 DXR 复用同一 device/queue；两个坑：FXAA 缓存交换链导致 resize 失败、DXR 合成写死 `(0,0)` 导致编辑器视口错位 | 启动四行日志、`native-d3d12-report.json`、视口偏移回归 18007→0/2 mismatch、13 图对照 |
| 3 | 三档 GI：屏幕空间、probe、路径追踪 | PT（DXR，Progressive/Realtime）、SSGI（trace/composite 两 Pass，采样当前帧 direct-lit 副本）、DDGI（atlas + auto-fit + DXR 逐 probe / 软件光追 fallback）；debug view 11/12；请求≠生效与报告原因 | GI 三档同机位对比、debug 11/12 截图、atlas 尺寸/60 B/px 数字、Cornell 渐进收敛 |
| 4 | 实时 GI 的质量层：降噪与 ReSTIR | 相机与逐物体重投影、多尺度 5×5、邻域 clamp；ReSTIR direct/indirect 历史 + 3×3 空间 reuse；为什么空间 reuse 只是平均、不是无偏 reservoir | 降噪 off/spatial/temporal 对比、ReSTIR vs Uniform、拖影说明、motion vector 复用 |
| 5 | 抗锯齿与阴影：先修采样，别靠后处理 | AA：Off/FXAA/TAA、TAA 无逐物体 MV、五条回退规则（DXR GI 强制 FXAA 等）、起始权重；阴影：4096²+4×4 PCF（16 次比较、约 128 MiB、texel 7.3 mm）、十种接法、ZWrite Off 会让整帧硬件通道停用 | AA ROI MAE 23.33/15.78/7.38、Off/FXAA/TAA 同机位裁剪、2×2 vs 4×4 PCF 裁剪、GPU Pass 计时 |
| 6 | 自己的帧检查器：先能测，再谈优化 | Profiler/Frame Inspector/Runtime/`.raframe` 离线包/三角统计；边界：不是 RenderDoc、无重放、GPU 时间不含 Present/独立 DXR；用它量 GI/AA/阴影的代价 | 工具 UI 截图、Pass 计时表、三角统计三个显示点 |

### 方案 B（紧凑，5 个技术模块，未采用；保留作篇幅不足时的退路）

2026-11-21 用户确认采用**方案 A**。下面是退路：

模块 1+2 合成「RHI 与两种 API」，模块 5 保留（AA/阴影合节），模块 6 压成模块 2 的证据段，模块 4 并入模块 3。适合全文控制在 5000 字左右。取舍：DXR 视口错位和 TAA 回退这两个最有故事性的坑只能各留一段。

### 其他变化（一段话，不单独成节）

内容浏览器与资产身份（GUID/`.rasset`/Engine 内容只读挂载/导入与 Reimport/删除查引用）、Asset Details 与网格逐 Slot 材质、选中描边终态、Details/Scene 分工、Outliner 眼睛、浮动面板、底栏命令控制台、真实加载进度、Project Manager 居中、文档重写。边界：无纹理载荷/压缩/节点材质/父子层级，文件操作无 Undo，描边多选/缩放终态缺截图。

## 4. 每模块的事实与坑（写作时直接取）

### 4.1 RHI 与声明式管线

- 起点（`7f8a585` 之前）：一帧是约 450 行顺序代码，Pass 依赖不可见，文档会漂移。
- `7f8a585` 只做声明与执行分离，执行器仍是原生 D3D11；`6a243b2` 才引入 `rhi::` 契约和 D3D11/D3D12 两个实现，`Rhi.h` 从引入到 HEAD 一直是 139 行，契约没被推翻。
- 三层建模：管线组织（Forward/Deferred）、图形后端（D3D11/D3D12；Vulkan/OpenGL 只有枚举占位）、可选特性（阴影/DXR/GI/AA/DOF/描边）。
- `FeatureState` 六态：`Off`/`Active`/`Degraded`/`UnavailableInBuild`/`UnsupportedByDevice`/`BlockedByDependency`；能力检查不改写用户请求，只并列记录请求与有效态。
- 边界：固定顺序执行，没有 Render Graph 编译、瞬态别名、多队列；RHI 契约只有 Vertex/Pixel，没有 Compute；DXR 走派生接口的 native 互操作，`SceneRenderer` 里存在 `if (native12)` 分支。
- 叙事：`Auto` 当前直接选严格 D3D11，是实验阶段策略，不是“测不出 D3D12”。

### 4.2 原生 D3D12 与原生 DXR

- 三个执行方式（项目设置下拉原文）：`D3D11 + D3D12 ray tracing`（混合）、`Auto`、`D3D11 (strict)`、`D3D12 (native DXR)`。回退复选框只在选 `d3d12` 时可编辑，且只包 device/窗口目标初始化失败。
- 原生自证：D3D12 生效却创建了 D3D11 device 就抛错——“原生”是可断言条件。
- 坑 1（最有故事性）：`a28f38c` 让加载窗 963×542 → 编辑器 2768×1191 resize；FXAA 把交换链目标存进持久成员，`ResizeBuffers` 一直看到借用图像而拒绝。修法：FXAA 不缓存目标、`releaseBorrowedUiTextures()`、resize 顺序重排。教训：交换链图像不能有跨帧持久句柄。
- 坑 2：编辑器视口是 scene target 的子矩形，原生 DXR 合成却复制到 `(0,0)`，右侧一条浅色竖带。修法：`copyTextureRegionTo(..., viewportX, viewportY, ...)`；回归测试还原修复会报 18007 个错位像素，修复后 AA 关 0、FXAA 2。
- 坑 3：DXR 间接光以 `sampled=true` 导入，被 UI 状态机改成 0xC0，DXR 自己按 0x80 起点 → validation error。修法：DXR 资源只当 copy source，间接光每帧复制到 RHI 自有纹理再采样。
- 边界：DOF/描边/解析光追/GPU primitive 未迁移；无热切后端、无设备丢失恢复；同步 fence 不承诺性能；Vulkan/OpenGL 未实现。

### 4.3 三档 GI

| 模式 | 需要什么 | 算法一句话 | 主要限制 |
| --- | --- | --- | --- |
| Path tracing | 必须 DXR（native 或 hybrid）；Progressive/Realtime | 逐样本路径积分 + 历史累积；Realtime 只输出间接光给光栅消费 | 唯一主射线最近命中，可见材质必须 ZTest Less/LessEqual 且 ZWrite On |
| Screen space (SSGI) | 不需 DXR，只 Deferred + 编辑器/离屏目标 | 屏幕空间 march 当前 direct-lit 副本，trace/composite 两 Pass + 时域混合 | 屏幕外信息缺失；同帧硬件传输时跳过 |
| Probe grid (DDGI) | 只 Deferred + 编辑器/离屏 | probe atlas；DXR 时逐 probe 光线追踪，无 DXR 时 8 方向×≤8 步屏幕 march | 软件 fallback 仍依赖屏幕可见表面；间接镜面不参与 |

- 三轮关键修复（正文最有价值）：
  1. SSGI 自反馈：首版单 Pass 采样场景色 → 拆 trace/composite → 采样当前帧 direct-lit 副本，避免自己给自己供能。
  2. DDGI atlas 大部分没写：`PSProbeUpdate` 沿用 scene viewport 而不是 1024×32 atlas viewport，表现像 DDGI 完全无效；再加 `probeAutoFit` 用场景包围盒推 grid center/spacing。
  3. 降级两次反转：先在 DXR-capable 后端关硬件光追时直接报不可用；后来改为跑软件光追 fallback 并标注 `Software ray-traced DDGI`，选择“可跑但明确说近似”。
- Debug 视图：11 = GI indirect；12 = GI probes。HEAD 是小圆点 billboard（`4e9a8dc`）；工作区未提交版改真实球体实例，未验证，正文只能按 HEAD 写。
- 边界：SSGI/DDGI 只在编辑器/离屏目标，runtime 交换链与 Forward 不启用；DDGI 首帧无有效 atlas；无透明/发光材质/体积。

### 4.4 降噪与 ReSTIR

- TAA 与 GI 的运动历史是两套东西：`23bab37` 的逐物体运动向量只服务实时 GI 时域重投影，不进 TAA。
- 降噪三层：5×5 空间滤波（按法线/平面距离/albedo/粗糙度边缘感知，粗糙度 <0.12 跳过）→ `denoiseIterations` 多尺度 tap（1–4 轮，粗尺度衰减）→ `Temporal + spatial` 用上一帧 VP + 主表面上一帧世界位置重投影，法线/深度/平面距离 + 邻域 clamp 拒绝失效历史。
- ReSTIR 是 Path tracing 实时模式的采样层：direct/indirect 各自候选数与 reservoir，上一帧 reservoir 20% 重投影，空间 reuse 是上一帧 3×3 邻域平均。
- 必须写清楚：direct 估计乘灯数并做 reservoir 校正、indirect 按亮度选样本，**不是严格无偏 ReSTIR**；空间 reuse 是估计平均，不是正式 reservoir 合并。
- 边界：渐进模式没有降噪器（靠累积收敛）；HDR 时间重建未实现；快速运动遮挡边界仍可能拖影。

### 4.5 抗锯齿与阴影

- AA 三模式：`Off`/`FXAA`/`TAA`；工程默认 FXAA，低层 `SceneSettings` 默认关闭。
- TAA 依赖：相机重投影 + 3×3 深度膨胀 + 3×3 邻域 clamp + 深度兼容判定；Halton(2,3) 16 样本抖动；两张 RGBA16F 历史；**没有逐物体运动矢量**，物体/材质/灯光编辑直接重置历史。
- 五条回退规则：硬件图像+渐进 PT → AA 关；数据视图 → 关；TAA+离屏 → FXAA；TAA+硬件图像 → FXAA（保 DXR GI 历史稳定投影）；其余按请求。光栅 SSGI/DDGI 仍允许 TAA（未实测）。
- 阴影：默认 `ShadowMapPCF16`（4×4、16 次 `SampleCmpLevelZero`、固定偏移不抖动）+ 4096²×2 深度（约 128 MiB，texel 约 7.3 mm）；十种接法；选择是会话状态不写场景文件。
- 关键判断：FXAA/TAA 补不回阴影图缺失的覆盖率，所以先加分辨率与核宽；PCF16 用确定性核而不是随机旋转，正是为了静态不抖。
- 边界（不可省）：每像素 16 次比较、128 MiB、无质量档位、**区间内没有任何帧时间数字**；4×4 核“覆盖 8×8 texel”是旧说法，按源码推导约 5×5；MSAA/渲染缩放/HDR 时间重建未做；描边在 AA 之后，描边边缘不过 AA。
- 材质深度门控：任一可见材质 ZWrite Off 或非 Less/LessEqual，整帧硬件通道停用，并连带改变 TAA→FXAA 的回退——把“关一个材质开关”的连锁反应写进边界。

### 4.6 诊断工具

- 入口：`Debug → Profiler... / Frame Inspector... / Runtime...`、`Debug → Capture next scene frame`、底栏 `Tools`。
- Profiler：65536 事件上限、120 帧摘要、Chrome Trace、GPU Pass 计时带原 FrameID。
- Frame Inspector：下一主场景帧、Draw/PSO/常量版本、Pass Before/After/Final、CSM 两层 raw、`.raframe` 离线包、raw 预算 256 MiB。
- 边界必须写：不是 RenderDoc，不能逐 Draw 重放；GPU 时间不含 Present/独立 DXR/UI；进程内存不是显存驻留；原生 D3D12 无 GPU 裁剪统计；F9 截图 ≠ 帧捕获。
- 用法：用 GPU Pass 计时量 GI/AA/阴影代价；三角统计在同一 10M 场景读到 scene/input/postClip 全 10,000,024（10M 证据是 2×2/2048/hybrid 配置，不能外推 4096）。

## 5. 证据现状与升 A 计划

当前结论：**全部 B**。四份审计都只读；区间内的运行记录是“当时跑过”（A 期），`26aaf1f` 上没有 AA/阴影/GI 的自测日志；DXR 与视口偏移的最强证据只在仓库外临时目录，不能发布也不能当本轮证据。

### 5.1 可复用的历史候选（B，可讲演进，不能写“现在能”）

- `artifacts/rhi-before|after` + `rhi-image-comparison-final.json`：D3D11 RHI 迁移前后 13 张非 UI 图逐字节一致。
- `artifacts/native12-*`：原生 D3D12 14 帧、不建 D3D11 device、validation 0；`native-d3d12-report.json`（不含 DXR）；跨 API 9 张图最多 2 像素单通道差 1。
- `artifacts/native-dxr-aa/anti-aliasing.json`：DXR 阶段 AA 三后端；ROI MAE off 23.33 / FXAA 15.78 / TAA 7.38（192×144 夹具）。
- `artifacts/backend-startup*`、`artifacts/native12-startup-matrix.log`：启动矩阵与四行启动报告（注意旧文案“native DXR not available yet”）。
- `artifacts/gi*`、`cornell-*`、`r8-performance`：渐进 GI 收敛误差 0.07238/0.01262/0.00557（1/16/64 vs 256）、颜色互染 ROI、10M 三角形 hybrid DXR 计时（中位 15.46 ms，2×2/2048 配置）。
- `docs/images/`：`gi-compare.png`、`hrt-compare.png`、`pathtracing-cornell.png`、`shadow-pcf-compare.png`、`shadows-compare.png`、`diagnostics-pipeline.png` 等公开文档图，可作候选，但参数/构建要按实际 caption 写，必要时重拍。

### 5.2 必须在 DevLog03 终点重跑（P0 → P2）

前提：GI 修复提交完成、工作区干净、HEAD = 终点 commit、隔离工程副本、记录 exe SHA256 + HEAD + 源文件哈希。

| 优先级 | 命令 | 验收 |
| --- | --- | --- |
| P0 | CMake Debug/Release 构建 | 无 warning/error，记录实际 CTest 总数（不能沿用历史的 23/24/25/29/30） |
| P0 | `scripts/Test-BackendStartup.ps1 -Executable <exe> -CaptureDirectory artifacts/devlog03-backend-matrix` | 6/6 PASS；严格 11 与 Auto 图像逐字节一致 |
| P0 | `--editor-self-test`（D3D11） | exit 0、D3D11 errors 0；桌面 focus 竞争失败保留首次失败证据 |
| P0 | `--native-d3d12-self-test --project <隔离 Sandbox> --capture-dir ...` | `native-d3d12-report.json`：`dxr.active`、`dxrViewport.mismatches`、`validationErrors:0` |
| P0 | `--gi-self-test`、`--hardware-rt-self-test` | 颜色溢出/收敛/历史重置/模式与贡献开关；记录 dispatch 数与 validation |
| P1 | `--aa-self-test` ×（默认/d3d11/d3d12 禁回退）+ `--aa-ui-self-test` | 三份 JSON `passed:true`；原生 D3D12 的 dxr 不再 skipped |
| P1 | 截图组：GI 三档同机位、debug 11/12、Cornell 渐进 1/16/256、AA off/fxaa/taa、2×2 vs 4×4 PCF、后端切换、视口偏移前后 | 同机位同参数；每张记命令、构建、尺寸 |
| P1 | 录屏：GI method 切换（Off→SSGI→DDGI→PT）或 AA 切换 | 真实连续录屏；≤5,000,000 字节；逐帧隐私检查 |
| P2 | 4×4 PCF 与 4096 的实际代价（Profiler `Shadow map` Pass A/B）、ReSTIR vs Uniform、SSGI/DDGI 帧时间 | 同场景同机位；没有数字就不写性能结论 |
| P2 | TAA + 光栅 SSGI/DDGI（D3D11）、原生 D3D12 TAA | 未测就写“未验证”，不能推断 |

### 5.3 证据身份

沿用 `native12-source-identity` 的做法：每次重跑保存 `git rev-parse HEAD`、exe SHA256、相关源文件哈希、命令与退出码、设备、分辨率、主题、隔离工程副本。这一轮要写成**终点 commit**，不是 `14a6b0d + 未提交快照`。

## 6. 媒体拍摄清单（沿用 DevLog02 规则）

发布素材放外部栏目根的 `YYYY-MM-DD_第03期_assets/`；原图/录屏留在独立证据目录。每个最终 GIF ≤ **5,000,000 字节**（十进制，实测字节数）。对比图必须同机位、同曝光、同渲染路径。

| # | 文件（暂名） | 内容 | 生成方式 | 正文落点 | 图注要点 |
| --- | --- | --- | --- | --- | --- |
| 01 | `01-backend-settings.png` | 项目设置 Rendering 页：后端下拉、回退勾选禁用态、requested/effective/原因 | 编辑器实拍（F3） | 模块 1 后端选择段后 | 四个选项原文；切换需保存重启 |
| 02 | `02-d3d11-vs-d3d12.png` | 同场景严格 D3D11 vs 原生 D3D12 | 两次启动截同机位，必要时并排 | 模块 2 开头 | 只差 API，画面应一致；标 commit/设备 |
| 03 | `03-dxr-viewport-before-after.png` | 视口偏移前（右侧浅色竖带）vs 修复后 | 一次性分支还原旧 `(0,0)` 复制截“前”，回退截“后” | 模块 2 视口偏移段 | 18007 个错位像素 vs 0/2；不要直接改工作区 |
| 04 | `04-gi-off.png` / `04b-gi-pt.png` | Cornell Box：GI 关闭 vs 渐进 PT | `--gi-self-test` 或样例工程同机位 | 模块 3 开头 | 间接反弹、粗糙反射、可见发光面 |
| 05 | `05-gi-ssgi-ddgi-pt.png` | 同机位三档 GI（SSGI/DDGI/PT realtime） | 同一相机逐档切换截图 | 模块 3 三档对比 | 标注分辨率/曝光/构建/模式 |
| 06 | `06-gi-debug-indirect.png` + `06b-gi-probes.png` | debug 11（GI indirect）与 debug 12（probe 标记） | `--debug-view 11/12 --frames N --capture-temp` | 模块 3 debug 视图段 | HEAD 的 probe 标记是小圆点；说明 12 仍执行 probe update |
| 07 | `07-aa-off-fxaa-taa.png` | 同机位高对比边缘裁剪：Off/FXAA/TAA | `--aa-self-test` 的 1440×900 捕获或编辑器实拍 | 模块 5 AA 段 | 与 192×144 的 ROI MAE 分开写，不混一句话 |
| 08 | `08-pcf-2x2-vs-4x4.png` | 4×4 PCF vs 2×2 PCF 阴影边缘裁剪 | 同场景切 Shadow method | 模块 5 阴影段 | 4096²、固定偏移不抖；说明选择是会话状态 |
| 09 | `09-frame-inspector.png` | Profiler/Frame Inspector 实际界面 | 编辑器实拍 | 模块 6 | 标出 Pass 计时/资源/Draw 列表 |
| 10 | `10-content-asset-ui.png` | 内容浏览器终态或 Asset Details/网格 Slot | 编辑器实拍 | 其他变化段 | 只一张，说明 UI 不展开 |
| GIF | `11-gi-method-switch.gif` | 视口里连续切 GI method，看画面变化 | 真实桌面连续录屏 | 模块 3 末尾 | 3–6 秒、10–12 fps、800–960 px；不变速、不拼帧 |

不合格就换：历史 `docs/images/*` 只能当构图参考，不能当本期运行证据；不能把静态结果拼成“实时操作”。

## 7. 文档漂移与发布前修整

写正文前二选一：先修公开文档再引用，或正文只引用口径正确的那几份。

| 类 | 位置 | 漂移 |
| --- | --- | --- |
| 阴影分辨率 | `README.md`（L92/L333/L343）、`docs/RenderPipeline.md`（L62/L198/L246） | 仍写 2048²、特性表缺 `ShadowMapPCF16`；实现已是 4096² + 4×4 默认 |
| 阴影方案列表 | `docs/EditorGuide.md:282` | 缺 4×4 PCF（新默认） |
| PCF 覆盖口径 | `Scene.hlsl:483-485` 注释、`ShadowMethods.md`、`Architecture.md` | 写“约 8×8 texel”，按源码推导约 5×5 |
| GI 算法枚举 | `GlobalIllumination.md` 末尾 | 仍写“枚举只有 Disabled 与 Path tracing”，与四种方法矛盾；文末还有重复段落 |
| 硬件光追旧说法 | `HardwareRayTracing.md`、`Architecture.md`、`RenderingDevelopment.md` | 仍写“无运动重投影/未实现完整 DX12 场景后端”，与 23bab37、6a243b2 冲突 |
| 示例参数 | `PathTracing_CornellBox/README` vs `.raproject` | README 仍是 4 spp/1024，工程实际 16 spp/65536/12 bounces |

## 7.1 文档漂移修复清单（已验证行号，2026-11-21）

这些是公开文档，修完会形成一组独立提交；不要和用户正在进行的 GI 改动混在一起。行号取自当前提交 `26aaf1f` 附近的文件，修完以实际行号为准。

| # | 文件:行 | 现状 | 应改为 |
| --- | --- | --- | --- |
| 1 | `README.md:92` | 「阴影有九种接法……共用一张 2048² × 2 切片深度数组」 | 十种接法（加 4×4 PCF）；4096² × 2 |
| 2 | `README.md:333` | Sandbox 说明「金属反射与 2048² 阴影」 | 4096² 阴影；GI/阴影参数按当前 `.raproject`（4/512/4 或实测值） |
| 3 | `README.md:343` | 渲染管线图「2048² × 2 Texture2DArray」 | 4096² × 2 |
| 4 | `docs/RenderPipeline.md:62` | ShadowMap「2048² 方向光深度数组」 | 4096²；并在特性表（约 L246）补 `ShadowMapPCF16` 行 |
| 5 | `docs/RenderPipeline.md:198` | 「设置 2048² 视口」 | 4096² |
| 6 | `docs/EditorGuide.md:282` | Shadow method 列表缺 4×4 PCF（新默认） | 补「4x4 PCF（默认）」并说明 2×2 仍保留给低开销预览 |
| 7 | `docs/ShadowMethods.md:11`、`:15` | 「16 次双线性比较覆盖约 8×8 texel」 | 统一为「16 次双线性比较，每个比较自带 2×2 texel 邻域，合并覆盖约 5×5 texel」；或只写「16 次比较」不写覆盖数 |
| 8 | `docs/Architecture.md:224` | 同样写「约 8×8 texel 覆盖」 | 与 ShadowMethods 同步口径 |
| 9 | `Shaders/Private/Scene.hlsl:483-485` 注释 | 「effective footprint is eight texels wide」 | 与文档同步（约 5 texel），避免注释与文档再次互相证明错误 |
| 10 | `docs/GlobalIllumination.md` 末尾（约 L194-200） | 仍写「枚举只有 Disabled 与 Path tracing」「逐物体运动向量仍待扩展」；文末还有重复的「单矩形发光面示例」段落 | 改成四种方法；删除“仍待扩展”旧说法（23bab37 已有逐物体）；合并重复段落 |
| 11 | `docs/HardwareRayTracing.md:3`、`:53`、`:89` | GI method 只列 Disabled/Path tracing；「尚未实现完整 DX12 场景后端切换」；「仍无空间 reuse」 | 四种方法；原生 D3D12 已接入（写清实验性边界）；`restirSpatialReuse` 已存在但只是邻域平均 |
| 12 | `docs/RenderingDevelopment.md`、`docs/Architecture.md` 相关段 | 仍写「无运动重投影」 | 实时 GI 已有相机/逐物体重投影；TAA 仍无逐物体 MV（分开说） |
| 13 | `Projects/PathTracing_CornellBox/README.md` | 写 4 spp／1024／8 bounces | 与 `.raproject` 一致：16 spp／65536／12 bounces（或反过来把工程改回 README，但不要两头不一致） |

修完后跑一次公开文档链接/关键词检查：`2048`、`8×8`、`九种`、`无运动重投影`、`只有 Disabled` 应不再出现在旧语境里。

## 8. 已确认决定与剩余待办

2026-11-21 用户确认：

1. **终点**：GI 修复提交后，先补一组公开文档漂移修复，再把最后一个引擎提交冻结为终点，并打 `DevLog03` 标签。
2. **版本**：对外写 `v0.4.0`；程序内 `0.2.0` 本次不动。
3. **日期**：计划发布日 `2026-11-23`，文章文件名用同一日期。
4. **模块**：方案 A（6 个技术节），诊断工具保留独立一节。

剩余待办：

1. 文章短主题（`重启 RestArtEngine DevLog 03｜<短主题>`）；建议「渲染管线：RHI、硬件光追与实时 GI」，可中英混排时统一一种。
2. 按 §7.1 修完文档漂移并把修复提交计入区间终点。
3. 终点确定后按 §5.2 重跑证据，再按 §6 采集媒体。
4. 发布后回填底稿（链接、实际日期、终点 commit、标签）并确认 GIF 完整播放与知乎/手机预览。

## 9. 风险

- 工作区 volatile：GI 修复+probe 可视化+instanced draw 正在改，审计期间 `tests/RhiInspectionTests.cpp` 也被并发改。重跑与截图必须等工作区干净且 HEAD=终点；期间不要在工作区做“临时还原旧代码”的对比（用一次性副本）。
- 全部证据 B：正文若现在写，只能写“代码里有、当时验证过”；“现在能”要等重跑。重跑前不要动 Sandbox 用户资产，用隔离工程副本。
- 叙事风险：117 个提交按时间讲会变 changelog，必须按模块合并；10-27 的 39 个资产/编辑器提交和 11-20 的 21 个 GI 修复提交都要压缩。
- 文档漂移会被熟悉 UE/DXR 的读者抓住；尤其 2048²→4096² 和 GI 枚举两处。
- 仓库外临时日志（11-19 的 DXR stdout/err）不能入库、不能截图进正文；要证据就重跑落盘。
- 10M 三角形、4096 阴影、ReSTIR 三组数字来自不同配置，不能拼成一句话。
