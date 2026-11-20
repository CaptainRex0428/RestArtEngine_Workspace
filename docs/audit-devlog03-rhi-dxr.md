# DevLog03 审计：RHI 抽象、D3D11/D3D12 双后端与原生 DXR

> 本页只保留本地，不提交引擎库。审计日期：2026-11-20。审计员：只读审计（补充模型），任务 `task-2`。
> 审计对象：区间 `4193f55..26aaf1f` 内与 RHI／后端／DXR／frame pass 有关的提交与证据。
> 本页是写作底稿的一部分，不是正文；正文写法建议见第 7 节。

## 0. 口径与方法

- **区间**：`4193f55211a26dd189c4850d44e75e6590fd7302`（DevLog02 文章终点，2026-10-26）至 `26aaf1f`（2026-11-20，HEAD）。共 **117 个提交**、**1 个 merge**（`a46432b`）。
- **只读边界**：本轮未构建、未运行引擎、未改任何被跟踪文件、未 commit／reset。所有源码引用取自 `git show <commit>:<path>`，即**已提交状态**。
- **工作区是 volatile 的**：审计开始时 `git status` 有 11 个已跟踪修改 + 3 个未跟踪路径，主要是一轮**未提交的 GI 修复**（`include/RestArtEngine/Renderer/Rhi.h`、`src/Renderer/D3D1{1,2}/…Rhi.cpp`、`src/Renderer/RhiInspection.h`、`src/Renderer/SceneRenderer.cpp`、`Shaders/Private/Scene.hlsl`、`docs/GlobalIllumination.md`、Sandbox 资产）；审计过程中 `tests/RhiInspectionTests.cpp` 也被其它任务改动，说明工作区仍在并发演进。其中 `Rhi.h` 的未提交改动新增了 `drawIndexedInstanced` 与 `VertexAttribute::perInstance`。**这些内容一律不写进审计结论，也不作为已验证能力。**
- **证据分级**（沿用《ZhihuSeries》§3.4）：A＝本轮跑过并观测；B＝代码／文档／历史日志在，本轮未跑；C＝计划或仓库外不可复核。本页只有 B 与 C；A 需要按第 8 节在 DevLog03 终点重跑。
- **只看文件与文本／JSON／日志**，未逐张查看 BMP/PNG（图像类证据按 JSON 报告与文件存在性记录）。

## 1. 区间定位与逐提交表

### 1.1 区间事实

| 项 | 值 |
| --- | --- |
| 起点 | `4193f55`（2026-10-26 `test(gui): queue caption input…`） |
| 终点 | `26aaf1f`（2026-11-20 `fix(gi): repair SSGI and add software ray-traced DDGI fallback`） |
| 提交数 | 117（first-parent 主线 116 条 + 由 `a46432b` 合并进来的 1 条 `638ae2e`） |
| 标签 | `DevLog01`=`6236ce3`、`DevLog02`=`cc68a1b`、`v0.3.1`=`cc68a1b`（标签打在文章收尾文档提交上，不是版本号提交） |
| 引擎版本 | `CMakeLists.txt` 仍为 `project(RestArtEngine VERSION 0.2.0)`；`.raproject` 的 `engineVersion` 也是 `0.2.0`。**DevLog03 头部版本号需作者确认**，不能照抄 `v0.3.1` 标签 |
| 阶段断档 | 10-31（`14a6b0d`）之后到 11-18（`7e5ca88`）之间无引擎提交；11 月前半段主要是复验与学习记录 |

区间里其实叠了三层工作：①10-27～10-31 的资产/内容/诊断/DXR-GI 期（DevLog02 之后的补课）；②11-18～11-19 的后端专项（本次审计主体）；③11-19～11-20 的 AA/阴影/GI 期。本审计只覆盖第 ② 层与第 ①③ 层中与后端/DXR 相交的部分；资产/编辑器/GUI 与 GI 算法本体属于其它模块。

### 1.2 主线：RHI 与后端（真正新增能力）

| 提交 | 日期 | 变化（核实后） | 被谁替代／后续关系 |
| --- | --- | --- | --- |
| `7f8a585` | 2026-10-31 | 声明式 frame pass + 特性状态：新增 `RenderPipeline.h`（133 行，11 种 `RenderPassKind`／12 个 `PipelineResource`）、`RenderFeatures.h`、`Pipelines/ScenePipeline.cpp`（277 行）、`Passes/ShadowPass.*`、`RenderPipelineTests.cpp`（465 行）；`SceneRenderer.cpp` 459 行重写为「按声明顺序执行」。此时**执行器仍是原生 D3D11**，RHI 契约还不存在 | 其 Pass 列表被 `b142549`（AA pass）、11-20 GI 提交（SSGI/DDGI/debug）扩展；`RenderPipeline.h` 现为 157 行、17 种 pass、20 个资源位 |
| `6a243b2` | 2026-11-19 | **一次落地 M1+M2+M3+原生 Inspector**：63 文件 +9136/−675。新增 `Rhi.h`（139 行公共契约）、`D3D11/D3D11Rhi.{h,cpp}`、`D3D12/D3D12Rhi.{h,cpp}`（1224 行首版）、`BackendSelection.h`、`RhiSceneResources.inl`／`RhiSceneExecution.inl`／`RhiInspection.h`、`NativeD3D12Smoke.*`、`InspectorSmoke.*`、`InspectorUiSmoke.*`、`FrameCaptureArchive/Metadata`、`RuntimeDiagnostics`；`DiagnosticsPanel.cpp` +576；`MinimalApp.cpp` +150（`--backend`、`--native-d3d12-self-test`）；`scripts/Test-BackendStartup.ps1`；`ProjectSettings` 后端草稿；`ImGuiLayer` DX12 适配 | 是「RHI 只有占位」到「两个真实后端」的分水岭。后续 `b142549`（AA＋启动修复）、`c017ff8`（原生 DXR）、`64a7c97`（视口偏移）都在它上面加，没有推翻契约：**`Rhi.h` 从引入到 HEAD 一直是 139 行** |
| `c2ab76e` | 2026-11-19 | 后端文档：新增 `docs/RenderBackends.md`（109 行，三模式矩阵），改 `Architecture`／`Diagnostics`／`EditorGuide`／`HardwareRayTracing`／`RenderPipeline`／`RenderingDevelopment`／`README`。与 `6a243b2` 同一提交时间戳，属同批交付 | 后续 `b142549`／`c017ff8` 分别补 AA 项与原生 DXR 项；HEAD 的 `RenderBackends.md` 已含「原生光栅 + 原生 DXR」 |
| `a28f38c` | 2026-11-19 | 加载窗保持紧凑直到首帧：加载完成后不再把加载图拉大，而是保持 963×542 居中，GPU 预热后调整到完整编辑器尺寸再显示。4 文件 +61/−15 | **它是 11-19 启动崩溃的触发器**：新路径让窗口从 963×542 resize 到 2768×1191，暴露了 D3D12 `ResizeBuffers` 的借用图像问题（见 3.3） |
| `b142549` | 2026-11-19 | 可配置 FXAA/TAA（Off/FXAA/TAA，项目设置＋实时 UI，`AntiAliasing.h/.inl`、`AntiAliasing.hlsli`、AA 自测与 UI 自测、`AntiAliasingProjectTests`）**＋ 修复原生 D3D12 启动失败**：`D3D12Rhi` 新增 `releaseBorrowedUiTextures()`，`SceneRenderer::resize` 先释放 UI 借用再 `ResizeBuffers`；AA 持久成员只保留 TAA 历史。37 文件 +2086/−92 | 与 `eaf4193` 一起把 `RenderPipeline.h` 扩到含 AA pass；AA 规则（DXR 请求 TAA→回退 FXAA）成为 DXR 路径的显式边界 |
| `eaf4193` | 2026-11-19 | 4×4 PCF 软阴影＋4096² 阴影图（`ShadowMapPCF16` 进 `RenderFeatures`，默认改为 PCF16）；8 文件 +34/−8。文档 `8bbd1c9` | 阴影图分辨率变更留下文档漂移（见第 6 节） |
| `c017ff8` | 2026-11-19 | **原生 DXR 跑在纯 D3D12 上**：`HardwareRayTracing` 增加 native 模式（`initializeNative`／`nativeOutput`／`nativeIndirect`，用光栅的 `ID3D12Device5`＋queue），`D3D12Rhi::importTexture`，`SceneRenderer` 增 `HardwareTransport`／`HardwareResolve` native 分支，Realtime GI 间接光复制到 RHI 纹理；`ProjectSettingsRules` 允许 D3D12 请求硬件光追；UI 标签改为 `D3D12 (native DXR)`。17 文件 +399/−58 | 被 `64a7c97` 修正合成位置；11-20 GI 提交在同一 native 通道上追加 ReSTIR／降噪／DDGI |
| `64a7c97` | 2026-11-19 | 修原生 DXR 在编辑器视口偏移处的合成：新增 `D3D12RhiDevice::copyTextureRegionTo`（带目标偏移），原 `copyTextureRegion` 委托 `(0,0)`；`HardwareResolve` 改在 `(viewportX, viewportY)` 落图；自测增加 `(0,0)` vs `(64,48)` 视口回归。4 文件 +82/−7 | 未被替代；是当前 HEAD 的实现 |

### 1.3 前置与相邻提交（不是"新增能力"，但影响本模块写法）

| 提交 | 日期 | 与本模块的关系 |
| --- | --- | --- |
| `8f027db` | 2026-10-30 | 「整合相机/灯光/网格属性/Console」的整合提交（普通提交，**不是 merge**，67 文件 +9281/−565）。它把 `Lighting.h/.cpp`、`MeshAttributes.h`、`HardwareRayTracing` 的面光源/probe 字段、各类 smoke 测试一次性带进来；本审计涉及的后端测试（Camera/MeshAttributes/GlobalIllumination Smoke）都建立在这批之上。写正文时不要把它算成 11 月后端工作 |
| `c5db70c` | 2026-10-30 | 上述整合的公开文档（Camera/Lighting/Importing/Diagnostics 等） |
| `a46432b` | 2026-10-30 | **区间唯一 merge**，把 `638ae2e`（Cornell Box 路径追踪场景＋面光源）合入 master。分支侧只有这 1 个提交是本区间新内容，其余祖先都在区间之前。正文若提 Cornell Box，要写清它是「合并进来的样例」而不是「新写的后端」 |
| `fca018a` | 2026-10-31 | README 重写＋16 张 `docs/images/*` 与 `docs/RenderPipeline.md`（354 行）。**文章源码片段的说明文字主要来自这里**；其中影子图分辨率已过期（第 6 节） |
| `14a6b0d` | 2026-10-31 | 提升 Cornell GI 采样并修材质引用；是 11-18 后端专项的**代码基线**，M2/M3 证据的 `EngineHead` 都写它 |
| `7e5ca88` | 2026-11-18 | 引擎/工程加载进度（17 文件 +864/−116，`LoadProgress.h`、`--loading-report`、`Test-LoadingProgress.ps1`）。它让启动链变成可观测的分阶段流程，后端初始化被插进加载进度里 |
| `79bf6d0` | 2026-11-19 | 网格 Slot 材质与 Asset Details 环绕预览。**非后端提交**，只是与本模块同一天；正文不要并进后端小节 |

### 1.4 相邻 GI 模块（本区间最后 21 个提交，归 GI 审计）

`1bd8e58`（实时降噪/运动矢量设置）→ `23bab37` → `1a3dc57` → `1768b21`（SSGI）→ `f52eb1f`（DDGI probe atlas）→ `9dd0639`／`e7defe8`／`e1591f1`／`0d93c0a`（ReSTIR）→ `fa5667f`／`b97f305`／`9237cd3`／`f94b313`／`3733d68`／`4e9a8dc`／`2e6fb59`／`79511b8`／`5cafa4b`／`9dbdc7b`／`86dab47`／`26aaf1f`。

它们与后端的关系只有一句：**原生 DXR 通道成了 ReSTIR/DDGI 的执行载体**（`HardwareRayTracing.cpp` / `nativeProbeAtlas()` / `SceneRenderer` 的 `ProbeUpdate` pass），并且这些提交在 `D3D12Rhi`、`SceneRenderer`、`RenderPipeline` 上继续加码。**本页不评价 GI 算法与画质**；GI 模块的 A 级证据受工作区 volatile 影响，必须单独处理。

### 1.5 叙事线（正文可直接用）

```
只有 D3D11 + DXR 共享桥
  → 7f8a585 把「一帧」写成声明（还没有 RHI）
  → 6a243b2 RHI 契约 + D3D11 适配器 + 原生 D3D12 + 启动选择 + 原生 Inspector（一次落地 4 个 M）
  → b142549 AA 落地，同时修好原生 D3D12 启动（持久交换链引用）
  → c017ff8 DXR 搬到纯 D3D12（不再建 D3D11 device、不再共享纹理）
  → 64a7c97 DXR 图像按编辑器视口偏移合成（否则右侧一条竖带）
```

## 2. 最终架构（HEAD = 26aaf1f）

### 2.1 分层

```
app/MinimalApp.cpp            命令行、加载窗→编辑器窗口、启动报告与断言
  └─ renderer::SceneRenderer  ← 唯一拥有设备/交换链/Pass 执行的类
       ├─ RenderPipeline.h    声明：Pass 顺序 + 资源读写位（数据，不执行）
       ├─ RenderFeatures.h    策略：请求 / 能力 / 有效状态三层（数据，不执行）
       ├─ Pipelines/ScenePipeline.cpp   按本帧布尔条件组合 Pass 列表 + 校验
       └─ rhi::Device / rhi::CommandContext     （include/RestArtEngine/Renderer/Rhi.h，139 行）
            ├─ src/Renderer/D3D11/D3D11Rhi.cpp  （616 行）D3D11 适配器
            └─ src/Renderer/D3D12/D3D12Rhi.cpp  （1279 行）原生 D3D12
                 └─ D3D12/D3D12Rhi.h  派生接口：窗口/交换链/importTexture/描述符/计时/校验
```

三个维度在代码里是分开建模的（`RenderPipeline.h` 头部注释明确写了）：**管线组织**（Forward／Deferred）、**图形后端**（D3D11／D3D12；Vulkan/OpenGL 仅有枚举占位）、**可选特性**（阴影方案／DXR／GI／AA／DOF／描边）。换后端只换 `rhi::Device` 的实现和几处窗口/UI 互操作，不重写 Pass 列表。

### 2.2 `rhi::` 契约（Rhi.h，139 行，`6a243b2` 引入后未变）

| 层 | 内容 |
| --- | --- |
| 枚举／描述 | `BufferUsage`、`Format`（只有 `RGBA8Unorm`／`RGBA16Float`／`Depth32Float`）、`ShaderStage`（Vertex/Pixel，**没有 Compute**）、`CompareOperation`、`CullMode`、`LoadOp`／`StoreOp`；`BufferDesc`／`TextureDesc`／`GraphicsPipelineDesc` |
| 资源句柄 | `Buffer`／`Texture`／`Shader`／`GraphicsPipeline` 纯虚基类 + `shared_ptr` 句柄（RAII，有类型）|
| Pass 声明 | `ColorAttachment`／`DepthAttachment`（带 layer、Load/Clear/Store、clear 值）、`SampledTextureBinding`、`RenderPassDesc`（name/colors/depth/reads） |
| 命令 | `CommandContext`：`writeBuffer`、`bindConstantBuffers`、`beginRenderPass`／`endRenderPass`、`setViewport`、`bindGraphicsPipeline`、`bindVertexBuffers`、`bindIndexBuffer`、`drawIndexed`、`draw`（HEAD 无 instanced） |
| 设备 | `Device`：`createBuffer`／`createTexture`／`createShader`／`createGraphicsPipeline`／`commands()`／`statistics()` |
| 统计 | `Statistics`：buffers/textures/shaders/pipelines 创建数、upload、renderPass、draw、indexedDraw |

关键取舍（正文可讲）：**公共契约不含任何 D3D 类型，也不含 Compute/Descriptor/Barrier 概念**。DXR 因此没有"污染"契约，而是走了派生接口上的 native 互操作（`D3D12RhiDevice::device()/queue()/importTexture()/srvHeap()/copyTextureRegionTo()`）。代价是 `SceneRenderer` 里存在 `if (state.native12)` 分支——共享 Pass 在用到 DXR 时不是纯 `rhi::Device`，这一点必须在正文里如实写成边界。

### 2.3 后端怎么被选中（启动策略 / 项目设置 / 回退）

**枚举与规范键**（`BackendSelection.h`）：`MainRenderBackend { D3D11Dxr, Auto, D3D11, D3D12 }` → 键 `d3d11Dxr` / `auto` / `d3d11` / `d3d12`；`legacyHybrid`、`dx11`、`dx12` 为只读别名，保存时归一。旧工程缺 `backendPreference` 时仍按 `d3d11Dxr`（历史混合行为）。

**项目设置 UI 的确切文字**（`src/Editor/ProjectSettings.cpp`，`c017ff8` 后；组合框 `"D3D11 + D3D12 ray tracing\0Auto\0D3D11 (strict)\0D3D12 (native DXR)\0"`）：

| 下拉项 | 值 | 行为（HEAD 文档＋源码） |
| --- | --- | --- |
| `D3D11 + D3D12 ray tracing` | `d3d11Dxr` | 正式混合模式：D3D11 光栅 + 可选 D3D12/DXR 硬件光追；缺字段工程默认此项 |
| `Auto` | `auto` | 直接选已验收的严格 D3D11，不尝试原生 D3D12、不初始化 DXR bridge；属**初始选择**，所以关掉回退也能启动 |
| `D3D11 (strict)` | `d3d11` | 严格 D3D11，不创建 D3D12 device/DXR bridge |
| `D3D12 (native DXR)` | `d3d12` | 真正尝试独立 D3D12 设备与目标；成功后光栅和 DXR 共用 device/queue；**只有 device/窗口目标初始化失败且允许回退**才转严格 D3D11 |

其它 UI 事实：`Allow fallback to D3D11` 复选框只在选择 `d3d12` 时可编辑，否则显示禁用并提示 `Fallback applies only to the native D3D12 backend.`；面板显示 `Current main backend:` / `This launch requested:` / 选择原因 / D3D12 初始化错误文本；说明文字含 `Auto uses strict D3D11…`、`Native D3D12 executes DXR ray tracing/GI when the device supports DXR 1.1…`。保存后**下次启动生效**，不在当前会话热切设备；后端草稿、已保存值、本次真实启动请求三者共同驱动「保存并重启／已保存仍需重启／保存撤回以取消重启」提示（`ProjectSettingsRules.h`：`ProjectRestartNotice`），且不自动重启。

**回退语义**（`selectMainBackend` / `selectD3D11Fallback`，纯 CPU、无图形 API 依赖）：

```cpp
// include/RestArtEngine/Renderer/BackendSelection.h @26aaf1f L48-L76（删了注释）
switch (request.preference) {
case MainRenderBackend::D3D11Dxr: … allowD3D12Bridge = true; reason = "D3D11 raster with optional D3D12/DXR ray tracing."; break;
case MainRenderBackend::Auto:     … reason = "Auto selected D3D11; the experimental native D3D12 backend is opt-in."; break;
case MainRenderBackend::D3D11:    … reason = "Strict D3D11; D3D12 and the DXR bridge are not initialized."; break;
case MainRenderBackend::D3D12:    effective = D3D12; reason = "Experimental native D3D12 rendering; raster and DXR share the same device, no D3D11 bridge."; break;
}
// selectD3D11Fallback: startupAllowed = preference==D3D12 && allowFallbackToD3D11
```

回退只包**设备与窗口目标创建**；Shader 编译、资产、普通渲染错误继续报错，不允许「换个 API 把 bug 藏起来」。原生 D3D12 实际启动成功时会**断言没有创建 D3D11 device**（`MinimalApp.cpp` @26aaf1f L162-L174，断言在 L165-L166，失败直接抛错），这是"原生"一词可验证的最小定义。

**CLI**：`--backend auto|d3d11|d3d12|d3d11Dxr`（另接受 `dx11`/`dx12`/`legacyHybrid`，裸参数 `auto`/`dx11` 亦可），`--allow-backend-fallback` / `--no-backend-fallback`；覆盖只作用本次启动、不写回 manifest。启动固定打印四行：`Main backend requested: …; effective: …; fallback: …` / 原因 / `D3D12 initialization attempted: yes|no` / `D3D11 device created: yes|no`（+ 可选的 D3D12 初始化错误）。

**启动矩阵**：`scripts/Test-BackendStartup.ps1`（76 行）跑 6 个案例并逐条断言上面四行，再对 strict11 与 auto 的 BMP 做逐字节比较；6 案例为 `configured-strict11`、`auto`、`native12`、`native12-no-fallback`、`hybrid`（`--no-hardware-rt`）、`invalid`（`--backend d3d13` 必须 exit 1 且打印 `Invalid --backend`）。

### 2.4 Frame pass 与 feature state 表在哪

- **Pass 声明**：`include/RestArtEngine/Renderer/RenderPipeline.h`（157 行）。HEAD 有 17 种 `RenderPassKind`（`ShadowMap`、`HardwareTransport`、`GBuffer`、`DeferredLighting`、`ScreenSpaceGi`、`ScreenSpaceGiComposite`、`ProbeUpdate`、`ForwardBackground`、`ForwardGeometry`、`HardwareResolve`、`DepthOfField`、`AntiAliasing`、`AntiAliasingPresent`、`SelectionMask`、`SelectionComposite`、`GiDebugOverlay`、`FrameCapture`），20 个 `PipelineResource` 位；`buildScenePipeline(PipelineBuildInputs)` 按「本帧真的会跑」的布尔量组合列表，`validatePipeline` 校验「每次读都必须有更早的写者（或帧输入）」。
- **特性状态**：`include/RestArtEngine/Renderer/RenderFeatures.h`（116 行）＋`src/Renderer/RenderFeatures.cpp`（234 行）。`RenderFeature` 20 项（含 `HardwareRayTracing`／`HardwareReflections`／`HardwareShadows`／`PathTracingGI`／`ScreenSpaceGI`／`ProbeGridGI`／`RealtimeGI`）；`FeatureState` 6 态：`Off`／`Active`／`Degraded`／`UnavailableInBuild`（第 1 层：这个 build 没实现）／`UnsupportedByDevice`（第 2 层：设备/API 不能跑）／`BlockedByDependency`（第 3 层：本帧前置条件不满足）。**能力检查不改写用户请求**，只并列记录请求与有效态并报告阻塞层。
- **组合与执行**：`src/Renderer/Pipelines/ScenePipeline.cpp` 组合＋校验；`src/Renderer/SceneRenderer.cpp` 按声明顺序执行，并在 `Diagnostics` 面板显示同一份声明、`describePipeline()` 文本与 Profiler 计时行。
- **测试**：`tests/RenderPipelineTests.cpp`（465 行）覆盖组合顺序、资源边与三层特性判定（CPU，无 GPU）；`tests/BackendSelectionTests.cpp`（54 行）覆盖选择/回退/别名；`tests/ProjectSettingsTests.cpp`（674 行）覆盖依赖联动与 JSON 往返。

### 2.5 原生 DXR 的入口与关键对象

| 环节 | 位置（HEAD） | 事实 |
| --- | --- | --- |
| 设备/队列 | `HardwareRayTracing::initializeNative(ID3D12Device*, ID3D12CommandQueue*)` | `QueryInterface` 到 `ID3D12Device5`，**复用光栅 device/queue**，自建 allocator／`ID3D12GraphicsCommandList4`／普通 D3D12 fence／descriptor heap；不建 D3D11 device、不建共享纹理/fence |
| 能力门槛 | 同上（`src/Renderer/D3D12/HardwareRayTracing.cpp`） | DXR tier ≥ 1.1、Shader Model ≥ 6.5、RGBA8 支持 `UAV_TYPED_STORE`、RGBA32F 支持 UAV load+store 且是 TEXTURE2D、RGBA16F 支持 `UAV_TYPED_STORE` 且可做 RENDER_TARGET；`dxcompiler.dll`/`dxil.dll` 必须在 exe 旁。任何一项不满足→报原因、保留光栅 |
| 输出 | `nativeOutput()`（RGBA8 硬件预览/渐进完整图）、`nativeIndirect()`（RGBA16F 实时间接光）、`nativeProbeAtlas()`／`nativeProbeDepth()`（DDGI，11-20 提交加的） | 都是普通 D3D12 UAV 资源；输出提交后置 `COPY_SOURCE`，间接光置 `PIXEL_SHADER_RESOURCE` |
| 进入 RHI | `D3D12RhiDevice::importTexture(ID3D12Resource*, TextureDesc, currentState)` | 只包 SRV、不建 RTV；资源生命周期归 DXR 模块，RHI 包装 AddRef。**必须 `sampled=false`**（否则被 `prepareUi()` 的弱引用列表改状态，见 3.5） |
| 管线接入 | `RenderPipeline.h` 的 `HardwareTransport`（写 `HardwareImage`，实时模式另写 `IndirectLighting`）与 `HardwareResolve`（读 `HardwareImage` 写 `SceneColor`） | 声明来自「本帧 transport 尝试」；尝试失败时 pass 短路、保留光栅并单独报告原因 |
| 合成 | `SceneRenderer.cpp` @26aaf1f L2591-L2608 | native 分支：`importTexture` → `copyTextureRegionTo(rasterDestinationImage, viewportX, viewportY, …)`；混合分支仍用 `ID3D11DeviceContext::CopySubresourceRegion` + 共享纹理 |
| 实时间接光 | `SceneRenderer.cpp` @26aaf1f L2412-L2431 | 每帧把 DXR 间接光复制到 RHI 自己的 RGBA16F 纹理（`Native DXR indirect copy`），再作为 t9 绑到光照 Pass；两套状态机解耦 |
| 命令顺序 | 每帧 DXR 命令列表在光栅列表之前 `ExecuteCommandLists` | 同 queue 保证「DXR 写 → 光栅读」；CPU 提交顺序 ≠ 光栅 Pass 顺序，不能据此推断 |
| 退出/失败 | DXR 不可用或管线编译失败 | 保留光栅画面、保留工程请求、报告原因；不静默改写配置 |

## 3. 关键取舍与坑

### 3.1 为什么先做 D3D11 再补 D3D12

`local/docs/design/NativeD3D12Backend.md` 的 M1–M5 就是答案，且实际执行与计划一致：

1. **M1 选后端**（`BackendSelection.h` + App 启动链 + 严格门控）：先让「选哪个 API」成为可观察、可断言的事实，别让 `D3D12CreateDevice` 成功冒充「D3D12 可用」。
2. **M2 用 D3D11 证明一条真实调用链通过 RHI**：网格上传→常量→Shader/PSO→真实附件→Draw→视口。原文理由很直白：*「先用现有 D3D11 画面证明一条真实调用链通过 RHI，再由 D3D12 实现同一契约。不要只包装 SceneRenderer 或添加更多空后端类。」* 验收是迁移前后 13 张非 UI BMP 逐字节一致——把"正确性"钉在画面上，而不是钉在 API 调用上。
3. **M3 用同一契约实现显式 API**（D3D12）：同步、资源状态、描述符、逐 Draw 常量版本这些 D3D11 驱动替你做的事，全部自己负责。
4. **M5 才搬 DXR**：DXR 是 Feature，不是后端。先把光栅跑通，再让 DXR 复用光栅 device/queue。

这个顺序的代价也要写：M2 之后有一段时间"RHI 已真实执行，但能力矩阵仍以 D3D11 为准"，文档必须同时说"已接入"和"未迁移"，否则读者会把 RHI 当成完整后端。

### 3.2 启动失败、WARP 与回退链

实际回退链（源码可查）：

- D3D11 路径：硬件 D3D11 失败 → WARP 软件设备（`README.md`「环境要求」；`RhiTests` 与 `LoadingScreenTests` 直接用 `D3D_DRIVER_TYPE_WARP` 做真实绘制/读回）。
- D3D12 路径：先枚举非软件适配器逐个 `D3D12CreateDevice`，全失败再 `EnumWarpAdapter` 建 D3D12 WARP 设备（`D3D12Rhi.cpp` @26aaf1f L318-L336）。
- 两层都失败 → 只有「允许回退且请求就是 `d3d12`」才转严格 D3D11；否则直接抛启动错误。

矩阵里同时被验证的是"**严格模式不暗建 D3D12**"：`configured-strict11` 与 `auto` 必须打印 `D3D12 initialization attempted: no`、`DXR dispatches: 0`；不创建 11 的断言则用在 `native12`（`D3D11 device created: no`）。M1 当时的回退证据是**"原生实现缺失"这一类**（日志原话 `Native D3D12 scene rendering is not implemented; falling back to strict D3D11.`、`D3D12 initialization attempted: no`），**不能**拿来证明"真实设备初始化失败的回退注入"已通过——后者至今没做（见第 5 节）。

### 3.3 11-19 那次"引擎打不开"的真正根因（AA × 原生 D3D12）

这是本模块最值得写的一个坑，因果链完整：

1. `a28f38c` 改了启动流程：加载窗先保持 963×542，GPU 预热后把窗口调整到完整编辑器尺寸（实测 2768×1191）。
2. 原生 D3D12 在 resize 时报错：`Release borrowed swapchain images before resizing the window.`；诊断显示 backbuffer `use_count()==2`，即**交换链图像被跨帧多持有一个引用**。
3. 根因在 AA 实现：`src/Renderer/AntiAliasing.inl::executeAntiAliasing` 把 `pass.colors[0].texture`（FXAA 的目标，非编辑器渲染时就是**交换链**）存进持久成员 `aaResolvedImage`。`SceneRenderer::resize` 只重置了 `swapchainImage`，这个成员还握着交换链引用，于是 `ResizeBuffers` 永远看到借用。
4. 两个次生脆弱点：resize 前没释放 UI descriptor 借用；`pendingObjects_` 会累积数百个延迟释放对象。
5. 修法（`b142549`）：`aaResolvedImage` 只在 TAA 时保存历史输出（FXAA 不再缓存目标）；`D3D12Rhi` 新增 `releaseBorrowedUiTextures()`——结束 pass、清 pass/table/pipeline、`waitIdle`、清 `uiBorrowedTextures_`/`pendingObjects_`/`pendingAllocations_`；`SceneRenderer::resize` 在 `ResizeBuffers` 前先 reset `swapchainImage`、再释放 UI 借用。
6. 验证：正常启动 5 帧 exit 0、validation 0；`--aa-self-test` 在默认／`--backend d3d11`／`--backend d3d12 --no-backend-fallback` 全 PASS；`--aa-ui-self-test` PASS；`--native-d3d12-self-test` 通过（含"离屏目标超过交换链尺寸、resize 保留独立图像"）。

正文写法建议：不要写成"AA 做完了顺手修了个 bug"，而是"**一个 AA 的输出缓存，把整条原生 D3D12 启动路径卡死了**——因为桌面换尺寸这件事第一次发生在原生后端上"。这是"显式 API 把隐式依赖暴露出来"的实例。

### 3.4 视口偏移 bug（`64a7c97`）

现象：开启 native DXR + Path tracing 后，编辑器 Scene Viewport 错位——右侧一条未更新的浅色竖带，顶部 GI 计数还在涨（说明 DXR 在跑，只是贴错位置）。

根因：编辑器 Scene Viewport 不是整张 scene target，而是子矩形（`settings.viewportX/Y/Width/Height` 由 `ViewportInteraction` 按面板位置算出）。`c017ff8` 的 native 合成只把 DXR 输出复制到 `(0,0)`：

```cpp
// 修复前（c017ff8）：目标偏移被写死成 0,0
copyTextureRegion(rasterDestinationImage, image, 0, 0, viewportWidth, viewportHeight);
```

而 D3D11 老路径一直用的是 `CopySubresourceRegion(..., viewportX, viewportY, ...)`。于是 DXR 图像总在左上角，编辑器却按 `viewportX/Y` 采子矩形 → 错位，右侧留着旧内容。

修法：新增 `copyTextureRegionTo(destination, dstX, dstY, source, srcX, srcY, w, h, layer)`，旧 `copyTextureRegion` 委托 `(0,0)` 保持所有老调用方语义不变；native 合成改为在 `(viewportX, viewportY)` 落图。

回归测试（`NativeD3D12Smoke.cpp` @26aaf1f L521-L573）：同一 scene target 上分别按 `(0,0,200,140)` 与 `(64,48,200,140)` 两个视口渲染，再比较平移后的像素——AA 关闭要求 **0 mismatch**，FXAA 允许 ≤8 像素（邻域效应）。实测最终报告 `dxrViewport.mismatches = {disabled: 0, fxaa: 2}`。把修复临时还原，同一测试报 `18007 mismatched pixels` 失败——证明测试真的能抓住这个回归，而不是"改完顺便绿了"。

### 3.5 原生 DXR 最容易踩的资源状态坑（首版真实报错）

首次把 Realtime GI 接进原生 D3D12 时，debug layer 直接报错：

```
ID=527 ExecuteCommandLists: ResourceBarrier … Before state (0x80:
D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE) of resource 'Native DXR indirect lighting'
does not match with the state (0xC0: NON_PIXEL_SHADER_RESOURCE|PIXEL_SHADER_RESOURCE)
specified in preceding ResourceBarrier or as InitialState
```

原因：RHI 用 `sampledTextures_` 弱引用列表记录"被采样过的纹理"，`prepareUi()` 每帧把它们统统 transition 到 `PIXEL_SHADER_RESOURCE | NON_PIXEL_SHADER_RESOURCE`（0xC0）。DXR 间接光一旦以 `sampled=true` 导入，下一帧 DXR 自己按 `PIXEL_SHADER_RESOURCE`（0x80）作起点就与 0xC0 不匹配。

修法（也是现在的正式做法）：**DXR 资源只当 copy source 导入（`sampled=false`），并把间接光每帧复制到 RHI 自有 RGBA16F 纹理再采样**。`SceneRenderer.cpp` L2422-L2427 是这个模式的样板。经验一句话：**别让两套资源状态机共享同一张图**。

### 3.6 AA 与 DXR 的关系（规则，不是实现）

`docs/AntiAliasing.md` 把请求与实际分开：实时 DXR GI 与独立硬件全图 resolve **请求 TAA 时使用 FXAA**（DXR 光照历史依赖稳定投影，不能接光栅每帧抖动）；渐进路径追踪跳过额外 AA；数据视图不做 AA；离屏视口请求 TAA 也用 FXAA 且不消费主场景时间历史。AA pass 在 `RenderPipeline.h` 里位于场景色／硬件 resolve／DOF 之后、描边与捕获之前，编辑器 UI 不经过过滤。这就是"特性之间用声明和规则组合，而不是互相 `if`"的例子。

### 3.7 源码片段候选（5–20 行，路径＋commit）

1. **启动策略**：`include/RestArtEngine/Renderer/BackendSelection.h` @26aaf1f L48-L76（`selectMainBackend` 的四种 case 与 reason；D3D12 的 reason 文字在 `c017ff8` 改过一次）＋L82-L90（`selectD3D11Fallback`）。说明点：为什么"回退"是独立函数、只包设备失败。
2. **原生自证**：`app/MinimalApp.cpp` @`6a243b2` L156-L169（`reportMainBackend`：D3D12 生效却存在 D3D11 device 就抛错）。说明点：把"原生"变成可断言条件。
3. **声明层**：`include/RestArtEngine/Renderer/RenderPipeline.h` @`7f8a585` 的 `RenderPassDeclaration` 与 `PipelineBuildInputs`（头条注释："input 是已解析的能力结果，不是用户愿望"）。说明点：为什么执行器和文档能共用一份数据。
4. **策略层**：`include/RestArtEngine/Renderer/RenderFeatures.h` @`7f8a585` 头部三层注释＋`FeatureState` 6 态。说明点：请求永不被能力检查改写。
5. **坑（AA×resize）**：`src/Renderer/AntiAliasing.inl` @`b142549` 里 `aaResolvedImage` 的赋值条件（只在 TAA 保存）＋`D3D12Rhi::releaseBorrowedUiTextures()` @`b142549`（HEAD `D3D12Rhi.cpp` L1014-L1025）。说明点：交换链图像不能有跨帧持久句柄。
6. **坑（视口偏移）**：`src/Renderer/SceneRenderer.cpp` @`64a7c97` 的 native `HardwareResolve` 分支（HEAD L2591-L2608，`importTexture` + `copyTextureRegionTo(viewportX, viewportY, …)`），对照混合分支的 `CopySubresourceRegion(…, viewportX, viewportY, …)`。说明点：同一语义两套 API 的细节差异。
7. **DXR 门槛**：`src/Renderer/D3D12/HardwareRayTracing.cpp` @`c017ff8` 的 `initializeNative` 能力检查段（tier/SM/格式/UAV/编译器 DLL）。说明点：DXR 不是"有 API 就能开"。
8. **设置规则**：`include/RestArtEngine/Editor/ProjectSettingsRules.h` @`c017ff8` 的 `projectBackendAllowsHardware` ＋ `applyProjectRenderingEdit`（只在显式编辑时联动取消，加载工程不清理请求）。说明点：为什么"设备降级不改用户请求"。

## 4. 现有证据盘点（`artifacts/`，本轮未重跑）

### 4.1 仓库内可直接引用的历史证据

| 证据 | 能证明什么 | 等级 |
| --- | --- | --- |
| `artifacts/rhi-before/`、`rhi-after/`、`rhi-image-comparison-final.json` | M2 D3D11 RHI 迁移前后 **13 张非 UI BMP 逐字节一致**（`Identical: true` 全表）。这是"换实现不换画面"的硬证据 | B（历史运行） |
| `artifacts/rhi-matrix-final/` + `rhi-matrix-final.log` + 每个 case 的 `startup.log` | 5 案例启动矩阵：`configured-strict11` / `auto` / `fallback12` / `invalid` / `reject12`；三个成功模式各 14 帧；文本含四行启动报告；`D3D11 validation errors: 0`、`DXR dispatches: 0`；RHI 统计 `buffers=12; textures=16; pipelines=224; uploads=187; passes=48; draws=80; indexed=64`。注意日志是 **M1 时代**（`Native D3D12 … is not implemented`），不能当原生 12 证据 | B |
| `artifacts/rhi-ctest-final.log` | `100% tests passed … out of 24` | B |
| `artifacts/rhi-build-final.log` | CMake/Make Debug 全量构建成功（日志无 error；"无 warning"来自任务记录，日志本身不逐条声明） | B |
| `artifacts/rhi-hardware.log` | 混合硬件光追套件 12 项检查全 PASS（+1 行套件汇总），`dispatches=217, graphics errors=0` | B |
| `artifacts/rhi-source-identity-final.json` | 证据身份：`Head: 14a6b0d` + 可执行文件 SHA256 `F20C7948…` + 每个源文件 SHA256。**注意：HEAD 是 14a6b0d，源码是当时未提交快照** | B |
| `artifacts/rhi-user-assets-check.json` | 7 个用户 Sandbox 资产哈希未变 | B |
| `artifacts/native12-build-final.log` / `native12-ctest-final.log` | M3 构建成功；CTest `25/25`（含 `D3D12RhiTests`） | B |
| `artifacts/native12-start-v2.log` | 原生 12 禁回退 14 帧、`D3D11 device created: no`、`validation errors: 0`；此版本文案仍为 `Native DXR integration is not available yet`（c017ff8 之前） | B |
| `artifacts/native12-features-v2/native-d3d12-report.json` | 自测报告：`passed:true`、`validationErrors:0`、`forwardDeferredMeanError≈0.00896`、阴影切换像素数（pcf 1195／pcss 1227／csm2 1172／gtao 1195／contact 5270）、`notCovered:["DXR","depth of field","selection outline","Frame Inspector frozen resources"]` | B（**明确未含 DXR**） |
| `artifacts/native12-startup-matrix.log` + `run-dcbabfa…/` | 6/6 PASS；每 case 的 `startup.log` 含当时文案：native12 为 `Native D3D12 raster backend; native DXR integration is not available yet.`，hybrid 为 `DXR 1.1 ready; disabled by project settings.` | B |
| `artifacts/native12-api-image-comparison.json` | 原生 12 vs 严格 11 的 9 张可比较图：最多 2 像素单通道差 1（其余 0） | B |
| `artifacts/native12-d3d11-image-regression.json` | 严格 11 对 M2 基线 13 张图逐字节一致 | B |
| `artifacts/native12-hybrid-regression.log` | 混合硬件套件 12 项检查全 PASS（+1 行套件汇总），`dispatches=251, graphics errors=0` | B |
| `artifacts/native12-editor-regression.log` | `--editor-self-test --backend d3d11Dxr` exit 0 / errors 0（D3D11/混合验收，**不代表原生 12**） | B |
| `artifacts/native12-interactive-final.log` | 原生 12 实际加载→编辑器 4 帧、20 passes／36 draws／32 indexed、`D3D11 device=no`、errors 0 | B |
| `artifacts/native12-source-identity-{validation,final}.json` | `EngineHead: 14a6b0d` + exe SHA256（`9B42E164…` 主体、`83271329…` 文案修正版）+ 14/15 个源文件哈希。**同样是未提交快照身份** | B |
| `artifacts/native12-user-assets-final.json` | 用户 7 文件哈希未变 | B |
| `artifacts/native-dxr-aa/anti-aliasing.json` | DXR 阶段重跑的 AA 专项：`backend:"d3d12"`、`dxr:"executed"`、边缘 ROI RGB MAE 参考 4× 超采样（0..255）：`off 23.33 / FXAA 15.78 / TAA48 7.38`；`new_validation_errors:0` | B |
| `artifacts/backend-startup*`（build/ctest/matrix/hardware/hybrid/ui-v2/ui-v3） | M1 证据：CTest `23/23`；混合新入口 `--backend d3d11Dxr --path-tracing --no-ui --frames 3` 产生 3 次 DXR dispatch、errors 0；`backend-startup-ui-v3` 为后端下拉的真实 UI 截图／日志，其中 `project-settings-ui.txt` 是当时下拉的**文本转储**（`{ D3D11 (strict) }` + 旧说明 `Native D3D12 rendering is not available yet…`），可当"改之前"的对照 | B |
| `artifacts/project-settings-links/v3/` | 三模式隔离 GUI 验收：hybrid 235 DXR dispatch／严格 11 不建 12／原生 12 不建 11、errors 0；规则 612 checks。本审计只读了任务记录，**未逐个核对这些文件**，引用前需开目录复核 | C→B（待复读） |

### 4.2 仓库外本机临时日志（**不可入库、不可截图进正文**）

11-19 原生 DXR 当轮的真实 stdout / 自测报告散在系统临时目录（仓库外），本轮只读确认了内容，**没有**把它们移动或复制进 `artifacts/`：

- `native-dxr1.out`：`D3D12 DXR 1.1 active: 19214 triangles. Reflections off, shadows off.`、3 帧、`D3D11 device created: no`、`validation errors: 0`。
- `native-dxr-shot.out`：`D3D12 DXR 1.1 active: 24202 triangles. Reflections on, shadows on.`、8 帧、errors 0。
- `native-dxr-gi5.out`：Realtime GI 12 帧，`samples: 12/256`、`DXR dispatches: 28`、errors 0。
- `native-dxr-prog.out`：Progressive GI 12 帧，`8/64 → 64/64`、`DXR dispatches: 14`、errors 0。
- `native-dxr-gi3.err`：3.5 节的 0x80 vs 0xC0 真实 validation error（首次失败证据，修复前）。
- `native-viewport-old.err`：`Native DXR editor viewport image is shifted: 18007 mismatched pixels.`（修复前失败）；`native-viewport-final5.err` 为空（通过）。
- `native-viewport-final5/native-d3d12-report.json`：**最终回归报告**——`dxr.active:true`、`dxr.realtimeGiSamples:4`、`dxrViewport.mismatches {disabled:0, fxaa:2}`、`offset [64,48]`、`size [200,140]`、`rhi {passes:186, draws:215, indexedDraws:133, uploads:538}`、`validationErrors:0`、`passed:true`、`notCovered` 已去掉 DXR。
- `native-viewport-debug2.err`：调试打印 `[dxr-resolve] viewport=0,0 1440x900 / 0,0 200x140 / 64,48 200x140`，是定位过程的好素材。

**结论**：DXR 与视口偏移这两条最想写的成果，**仓库内没有可发布证据**；历史 A 级证据全部在仓库外。DevLog03 若要用图/命令，必须在终点重跑并落到 `artifacts/`（第 8 节）。

### 4.3 本轮真的核对过的命令与数字

- `git log` / `git log --first-parent` / `git log --merges` / `git show --stat` / `git ls-tree` / 逐文件 `git show HEAD:<path>`（全部只读）。
- 读了 `artifacts/` 里上述文本与 JSON；读了仓库外 11-19 的 `.out`／`.err`／`native-d3d12-report.json`。
- **没有**构建、没有运行引擎、没有跑 ctest、没有复读每一张 BMP。

## 5. 与 DX11/DX12 的边界（正文"边界段"素材）

- **Vulkan / OpenGL：完全没有实现**。`src/Renderer/` 下只有 `D3D11/`、`D3D12/`；`RenderBackend.h` 里只有 `RenderBackendType::{Auto,Null,OpenGL,DirectX11,DirectX12,Vulkan}` 枚举与 `placeholder=true` 的生命周期骨架，`docs/RenderBackends.md` 明确写「旧 `IRenderBackend` 生命周期骨架不参与上述实际 RHI 执行」。Linux/macOS 后端同样没有。
- **只有 D3D11／混合有的**：解析式/软件三角形光线求交（`RayTriangleScene` + analytic primitives）、景深（`DepthOfField.inl`）、选中描边（`SelectionOutline.cpp`）、GPU primitive 统计查询、旧 `--editor-self-test` 的原生 D3D11 读回路径、混合模式的 DX11 共享纹理消费。
- **只有原生 D3D12 有的**：DXR 与光栅共用同一 `ID3D12Device5`/queue（不再需要 D3D11 device、共享纹理、共享 fence）；D3D12 debug layer 的 `validationErrors` 计数与最近 128 条原生消息；主队列 timestamp query heap 的 GPU Pass 计时；原生描述符堆与 `importTexture` 互操作。
- **两后端都有的**：Forward/Deferred、网格/材质/相机/灯光、光栅阴影（含 `ShadowMapPCF16`）、GTAO/Contact（要求 Deferred）、工具预览/缩略图、截图/F9、Frame Inspector 资源捕获（原生侧用 copy 而非 D3D11 纹理）、CPU Trace、ImGui 编辑器（DX11 与 DX12 两套 vendored 后端）。
- **明确的未实现**：运行中热切后端、设备丢失恢复、完整 Render Graph（自动屏障/瞬态别名/多队列）、异步多帧并行、MSAA、DXR 的 transparent/alpha-test/蒙皮/运动重投影/多视图历史、DispatchRays+SBT（当前是内联 `RayQuery` compute）、RenderDoc 实测、GPU-based validation、真实设备初始化失败的故障注入。
- **性能口径**：原生 D3D12 首阶段用同步 fence 保证正确性，**不宣称更快**；没有任何同场景 CPU/GPU 对照数据。

## 6. 文档漂移与需要在正文前修掉的东西

1. **阴影图分辨率过期**：实现已是 4096²（`eaf4193`），但 `README.md` L92、L333、L343 与 `docs/RenderPipeline.md` L62、L198 仍写 2048²；`docs/ShadowMethods.md` 与 `docs/Architecture.md` L224 已更新。正文若引用 Pass 表会撞车，建议先修文档或明确以 `Architecture.md` 为准。
2. **版本号**：`CMakeLists.txt` 仍 `0.2.0`，`v0.3.1` 标签打在 `cc68a1b`（DevLog02 收尾文档）。DevLog03 头部写什么版本必须先确认，不能由标签推断。
3. **历史日志里的旧文案不算现状**：`native12-start-v2.log`、`native12-startup-matrix/*/startup.log` 写着 `native DXR integration is not available yet`，这是 `c017ff8` 之前的真实状态；`c2ab76e` 版 `RenderBackends.md` 也还没有原生 DXR。正文引旧日志时必须给日期/commit。
4. **`Auto` 的语义**：文档写「Auto 当前直接选择严格 D3D11」，这是**实验阶段策略**，不是"D3D12 不可用"。正文别写成"Auto 测不出 D3D12 所以没有"。

## 7. 建议正文写法（供 Lead 定模块）

建议把本审计拆成 **2 个技术模块**，不要合成 3 个以上（全文 4–7 千字，还要留给资产/编辑器/GI 模块）：

### 模块 A：`把一帧写成数据，然后把两种 API 塞进同一个契约`
- 现状（`7f8a585` 之前）：一帧是约 450 行顺序代码，Pass 依赖不可见、文档会漂移、加特性靠加 `if`。
- 改动：`RenderPipeline.h` 只声明顺序与读写位；`RenderFeatures.h` 把「请求／能力／有效」分三层；执行器按声明跑。证据：`RenderPipelineTests` 465 行 CPU 测试 + `Diagnostics` 面板的同一张表。
- 源码：`RenderPassDeclaration`／`FeatureState` 片段（3.7-3、3.7-4）。
- 边界：仍是固定顺序执行，没有 Render Graph 编译/别名/多队列；RHI 契约只有 Vertex/Pixel，没有 Compute。
- 证据图：`Diagnostics` 的 Render pipeline 表（`docs/images/diagnostics-pipeline.png` 是公开文档图，可直接用；若要 DevLog03 自己的图，在终点重截）。

### 模块 B：`原生 D3D12 与 DXR：先证明一条链，再换 API，再共享设备`
- 现状：只有 D3D11 + 一个"另一个 D3D12 device + 共享纹理"的 DXR bridge；`Auto` 选 12 不代表能画。
- 改动：M1 选择器 → M2 D3D11 真实 RHI（13 张图逐字节一致）→ M3 原生 D3D12（不建 D3D11 device）→ M5 原生 DXR（同 device/queue）。
- 坑：AA 的 FXAA 输出把交换链存进持久成员 → `ResizeBuffers` 被拒（3.3）；DXR 图像写死 `(0,0)` → 编辑器视口错位（3.4）；DXR 间接光以 `sampled=true` 导入 → 0x80/0xC0 状态冲突（3.5）。
- 源码：`reportMainBackend` 断言、`HardwareResolve` native 分支、`initializeNative` 能力检查（3.7-2/6/7）。
- 边界：DOF/Outline/解析光追/GPU primitive 未迁移；无热切、无设备丢失恢复；同步 fence 不承诺性能。
- 证据图：后端下拉（`Auto` / `D3D11 (strict)` / `D3D11 + D3D12 ray tracing` / `D3D12 (native DXR)`）、启动日志四行、同场景两后端对比、视口偏移前后对比。

### 建议配图/表格清单（均需在终点重采）

| # | 内容 | 来源 | 备注 |
| --- | --- | --- | --- |
| 1 | 后端下拉 + 「下次启动生效」+ 回退勾选禁用态 | `--hardware-rt-self-test`/`--native-d3d12-self-test` 的 UI 截图，或直接开编辑器 Project Settings | 现成候选 `artifacts/backend-startup-ui-v3/project-settings-backend.bmp` 是 M1 文案，需重截 |
| 2 | 启动日志四行（requested/effective/attempted/created） | 终端截图或日志文本块 | 直接用命令行，四行即证据 |
| 3 | 同一场景 D3D11 vs 原生 D3D12 | `resized_*`/`forward_*` 成对 BMP | 现成 `native12-start-v2/`；注意里面有 `unlit_*` 是数据视图 |
| 4 | 视口偏移 bug 前后（右侧竖带 vs 对齐） | 需在**临时还原旧 copy 行为**的构建上截"前"，再切回截"后" | 仓库外只有 `vp-origin.png`/`vp-offset.png`，必须重采；这是本模块最强对比图 |
| 5 | DXR 硬件预览 / Progressive 与光栅对比 | `--native-d3d12-self-test` 的 BMP 或 `--project … --path-tracing` 截图 | 不可用 `docs/images/hrt-compare.png` 冒充 DevLog03 结果（它是 10-29 的混合模式图） |
| 6 | 自测 JSON 片段（`validationErrors:0`、`dxrViewport`） | 直接贴 JSON 代码块 | 比"零错误"三个字有力 |
| 7 | 表格：三后端能力矩阵（第 5 节） | 正文表格 | 知乎表格易变形，建议减列或改列表 |
| 8 | 表格：启动矩阵 6 案例 | 正文表格 | 同上 |

## 8. 待验证清单（DevLog03 终点必须重跑，否则只能写 B）

前提：等 GI 修复提交、工作区干净、`HEAD` = DevLog03 终点 commit（不要用当前 volatile 工作区）。

1. **构建 + 测试**：CMake Debug/Release 构建；`ctest --test-dir build/cmake-vs2022 -C Debug --output-on-failure` → 记录实际总数（历史记录：M1 23、M2 24、M3 25、Inspector 29、AA 期 30；HEAD 又有新增测试，**不能沿用 30**）。
2. **启动矩阵**：`scripts/Test-BackendStartup.ps1 -Executable <本次构建的 exe> -CaptureDirectory artifacts/devlog03-backend-matrix` → 6/6 PASS + 严格 11/Auto 图像逐字节一致。**这是最便宜、收益最高的重跑**，还能顺手拿到新文案的日志。
3. **原生 12 自测（含 DXR）**：`--native-d3d12-self-test --project <隔离 Sandbox> --capture-dir artifacts/devlog03-native-dxr` → 要拿到 `native-d3d12-report.json`（`dxr.active`、`dxrViewport.mismatches`、`validationErrors`）与 `native-dxr-editor-no-aa-offset.bmp` / `...-fxaa-offset.bmp`。**目前仓库内没有这些文件，必须重跑。**
4. **视口偏移前后对比**：同上自测已内建 `(0,0)` vs `(64,48)` 比较，但要出"错位图"必须在一次性分支/临时工作副本上还原旧 `copyTextureRegion(...,0,0,...)` 截一张，再回退。不要在工作区直接改（会污染 volatile 树）。
5. **AA 三后端**：`--aa-self-test`（默认／`--backend d3d11`／`--backend d3d12 --no-backend-fallback`）+ `--aa-ui-self-test`。
6. **混合回归**：`--hardware-rt-self-test --backend d3d11Dxr --project <隔离工程> --capture-dir artifacts/devlog03-hybrid` → 复核 dispatch 数与 `graphics errors=0`。
7. **跨 API 图像**：`native12-api-image-comparison.json`、`native12-d3d11-image-regression.json` 重新生成；确认允许差异仍是最多 2 像素单通道 1 级。
8. **D3D11 回归**：`--editor-self-test --backend d3d11`。注意历史上它会被桌面焦点竞争打断（`Native Content did not gain focus before the drag`），这是环境问题，不要写成通过；失败时保留首次失败证据。
9. **DXR 依赖描述核对**：确认 `docs/RenderBackends.md` 与 `HardwareRayTracing.md` 的依赖描述仍与实际 `initializeNative` 检查一致（本轮已核对一致；改了检查就要同步改文档）。
10. **修文档漂移**（第 6 节 1、2）或在正文里明确声明以哪份为准。
11. **证据落盘身份**：重跑时同时保存 exe SHA256 + `git rev-parse HEAD` + 源文件哈希（沿用 `native12-source-identity` 的做法），这次要写成**终点 commit** 而不是 `14a6b0d + 未提交快照`。

## 9. 给 Lead 的一句话结论

RHI/后端这条线的叙事是完整的：**10-31 先把一帧写成声明，11-18 用 D3D11 证明真实执行（迁移前后 13 张图逐字节一致），11-18/19 让同一契约跑在原生 D3D12（禁回退时不建 D3D11），11-19 再把 DXR 搬进同一个 device/queue（不再共享纹理），最后用两个具体的坑把"显式 API"的代价讲清楚——AA 的交换链持久引用导致启动失败、DXR 合成写死 `(0,0)` 导致编辑器视口错位**。所有历史运行证据都绑定在 `14a6b0d` + 未提交快照上，且 DXR/视口偏移的证据只在仓库外临时目录；DevLog03 要 A 级必须按第 8 节在终点重跑，其中启动矩阵、原生 12 DXR 自测、AA 三后端这三项性价比最高。
