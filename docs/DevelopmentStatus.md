## Rider 原生 C++ 工具链（2026-11-24）

开源项目的 Premake 入口已接入 VS 2022 C++ 工具链检测。当前工作区从 Rider 构建、跨盘干净检出使用生成配置从命令行构建，两个 Debug x64 解决方案均为 0 错误。验收口径和现有告警见[构建任务](tasks/2026-11-24-rider-msbuild/README.md)。

## SSGI／DDGI 计算、显示与性能档位（2026-11-23／24）

2026-11-25 已进一步降低软件 SSGI／DDGI 在首帧和转动镜头时的天花颗粒，并修复斜视角下 SSR 金属球倒影内部暗环。[逐像素画质与 GPU 成本](tasks/2026-11-23-gi-review/v10.md)

2026-11-25 软件探针支持步段交点复核与当帧空间滤波；SSGI 软件路径已用同帧几何重建改善冷启动与改灯响应。[Cornell 首帧、GPU 开销和适用边界](tasks/2026-11-23-gi-review/v9.md)

2026-11-25 已在 Deferred DDGI 接入独立 SSR／DXR 金属反射，探针漫反射和镜面可以分别开启。Cornell 两颗金属球的倒影随左墙材质换色，三种 Windows 后端配置通过像素验收。见[组合、性能和边界](tasks/2026-11-23-gi-review/v8.md)及[之前的调度诊断](conversations/2026-11-24-realtime-gi-flicker.md#ddgi-模式下的金属倒影)。

- [ ] **提高金属材质的镜面反射精度（SSR／DXR）**。后续以 Cornell 金属球的同机位截图为基线，对照收敛的路径追踪画面，检查倒影轮廓和不同粗糙度下的清晰度，并记录 GPU 耗时。[现有对照图与测量记录](tasks/2026-11-23-gi-review/v8.md)

### 实时 GI 实现待办（2026-11-24）

三条路线均已确认要实现。当前由用户先检查现有 DXR DDGI，后续分别验收以下工作。

- [ ] **软件世界空间 GI**。为无 DXR 设备提供可查询屏外几何和供光表面的场景表示。距离场与体素是待选实现。验收时让红墙移出画面，观察天花板互染，再移动遮挡物检查照明响应。
- [ ] **Lumen 式混合追踪 GI**。结合屏幕近场追踪、软件或硬件世界空间追踪与表面光照缓存。验收命中在屏内、屏外之间切换时的亮度连续性，并检查间接光是否重复累加。
- [ ] **低采样实时路径追踪 GI**。基于已有实时路径追踪、时空降噪和 ReSTIR 采样复用，完善低采样质量与性能分级。用渐进收敛图对照互染和反射，测量静止频闪、运动残影、改灯后的响应和各档 GPU 耗时。

Cornell 录屏中的 SSGI 脏噪及 DDGI 波纹已做时域修复。SSGI 分层采样并分表面重投影，探针每帧采样并逐渐扩大稳定期的历史窗口。SSGI 的 DXR 镜面同时改为稳定方向与按接收面重建。录屏机位在 5.78 倍漫反射强度下，8×8 天花板色块时间极差 P95 分别从 12.43 降到 0.77（SSGI + DXR 反射）、9.27 降到 0.81（DXR DDGI，迟滞 0.86）。三后端专项均通过；低迟滞仍有波动，场景变化的探针局部失效待设计。SSGI 漫反射现已修复天花板固定弧带，见[空间质量回归](tasks/2026-11-23-gi-review/v7.md)。见[时域及反射验收](tasks/2026-11-23-gi-review/v5.md)和[原始复现](conversations/2026-11-24-realtime-gi-flicker.md)。

DXR DDGI 的平面白斑与格纹已按固定中档复验。逐轴探针拟合、可见性加权二次 B 样条和非负 L1 重建已接入。图像差分、薄隙漏光边界与硬件实际计时见[格纹专项验收](tasks/2026-11-23-gi-review/v4.md)。

SSGI、屏幕空间和 DXR 探针的贡献、质量档位与实际状态已接入正常编辑器。Cornell 地板供光墙换色、三种后端读回、调试 EV、硬件 dispatch 时间戳、真实界面保存往返的记录见[本次验收](tasks/2026-11-23-gi-review/README.md)。工程内已有材质、场景改动独立保留。

## DevLog03 准备完成（2026-11-20，补充模型）

用户要求准备 DevLog03：等 GI 问题修好后写正文；区间提交多，重点讲 GI、RHI、抗锯齿、硬件光追等渲染层，UI 与简单开发只简单提。本轮只做准备，未构建、未运行引擎、未改被跟踪文件。

- 范围：起点 `4193f55`（DevLog02 正文终点）；候选终点当前 HEAD `26aaf1f`，正式终点等 GI 修复提交后确定。区间 117 提交、300 文件。
- 四份只读专项审计：[GI](audit-devlog03-gi.md)（34 主线 + 7 相邻 + 12 条被替换中间方案）、[RHI/DXR](audit-devlog03-rhi-dxr.md)、[AA/阴影/工具](audit-devlog03-quality-tools.md)、[UI/资产](audit-devlog03-ui-assets.md)。
- 汇总与写作计划：[DevelopmentChanges-DevLog03.md](DevelopmentChanges-DevLog03.md)：117 提交全覆盖核对（108 进专项、16 个归类不展开）、6 节模块方案、B→A 重跑清单、媒体拍摄清单、文档漂移、待确认问题。
- 底稿已加第 3 期阶段卡（planned）；证据现状全部 B，正文写“现在能”前必须在终点重跑。工作区 GI 修复与 probe 可视化仍在并发修改（`Scene.hlsl`、`SceneRenderer.cpp`、`Rhi.h`、D3D11/12Rhi、`RhiInspection.h`、`tests/RhiInspectionTests.cpp`），未提交改动不算已验证。
- 2026-11-21 用户确认：终点 = GI 修复提交后再补一组公开文档漂移修复，随后冻结并打 `DevLog03` 标签；对外版本 `v0.4.0`；计划发布日 `2026-11-23`；正文采用方案 A（6 个技术节）。文档漂移修复清单见 [准备文档](DevelopmentChanges-DevLog03.md) §7.1。

## 实时 GI 四项扩展立项（2026-11-19，补充模型）

用户要求实现四条实时 GI 路线并做成可配置：现有 Realtime PathTracing 的时域/空域降噪（相机 + 逐物体运动向量）、SSGI、DDGI、ReSTIR DI/GI。

- 设计已落盘：[RealtimeGiOptions](design/RealtimeGiOptions.md)；当前只有 `PathTracing`（Progressive/Realtime）一种 GI 算法，Realtime 已有 5×5 空间滤波、无运动重投影/降噪。
- 统一配置模型：`GlobalIlluminationMethod` 增加 ScreenSpace/ProbeGrid；降噪、运动向量选择（CameraOnly/PerObject/Automatic）、采样层（Path/ReSTIR）及 SSGI/DDGI/ReSTIR 参数放入 `GlobalIlluminationSettings`，旧工程缺字段用默认值。
- 实施顺序：M1 运动向量 + PT 降噪 → M2 SSGI → M3 DDGI → M4 ReSTIR；每阶段独立构建、GPU 截图、自测、CTest、提交后再进入下一阶段。
- M1 配置层已完成：降噪/运动向量枚举、denoiseIterations、项目 JSON 读写校验、Project Settings 控件与测试；提交 `1bd8e58`。
- 相机重投影 temporal+spatial 降噪已接入：b8/t12/t13/u5/u6、读写历史图、上一帧 ViewProjection 重投影、法线/深度拒绝与邻域 clamp；`GlobalIlluminationStatus` 报告 effective denoiser/motion vectors；提交 `ba44bad`。native self-test、hybrid hardware-rt self-test、三种 denoiser 模式 validation 0、CTest 30/30。
- 逐物体运动向量已接入（提交 `23bab37`）：RayTriangle 带上一帧世界位置，u7 输出主表面上一帧位置，temporal resolve 用相机+物体重投影；重建历史键排除 Actor 变换但保留拓扑/材质/光照失效；native self-test 移动 Actor 通过，hybrid stride 回归修复。
- 多尺度降噪迭代（提交 `1a3dc57`）：`denoiseIterations` 驱动 1–4 轮 5×5 tap，粗尺度权重衰减。
- **M1 完成**：native/hybrid 自测、Denoiser 三模式 validation 0、CTest 30/30。
- **M2 SSGI 首版完成**（提交 `1768b21`）：`GlobalIlluminationMethod::ScreenSpace`，Deferred 屏幕追踪 + 上一帧颜色 history，b6/t13、history 资源、D3D11/native D3D12 共享，Project JSON/UI/状态/测试；strict D3D11 与 native D3D12 probe validation 0，截图见任务 m2。限制：Forward/runtime swapchain 未启用、无时域重投影。
- **M3 DDGI 首版完成**：`GlobalIlluminationMethod::ProbeGrid`，相机目标 probe 网格 → 1024×32 RGBA16F atlas ping-pong，`PSProbeUpdate` 从 G-buffer 更新、Deferred 三线性采样 8 probe；b9/t14/t15、ProbeUpdate pass、Project JSON/UI/状态/测试；native 与 strict D3D11 validation 0，截图见任务 m3。限制：屏幕空间可见性近似、近镜面不参与、Forward/runtime swapchain 未启用。
- **M4 ReSTIR 首版完成**：Path tracing 实时采样层，direct/indirect reservoir 均有上一帧历史 + 世界位置/ViewProjection 重投影，`restirSpatialReuse` 增加上一帧 3×3 邻域平均；`sampling/restirCandidates/restirDirect/restirIndirect/restirSpatialReuse` 配置、UI、JSON、测试；native DXR 与 hybrid DXR validation 0。限制：直接光估计/indirect 亮度选择非严格无偏，空间 reuse 为估计平均而非正式 reservoir 合并；质量量化未做。
- **四项首版均完成并 GPU 验证**（M1/M2/M3/M4）；验收记录见 `docs/tasks/2026-11-19-realtime-gi/acceptance.md`。限制：SSGI 仅 Deferred/编辑器目标；DDGI 的 DXR 路径为逐 probe 光线追踪，strict D3D11 仍是屏幕空间 fallback；ReSTIR 为近似质量。
- `fa5667f` 质量修复：SSGI 改为独立 trace/composite，采样 direct-color history 避免自反馈，加入时域重投影/邻域 clamp/3×3 空域滤波/albedo 调制/emitter 拒绝；DDGI 网格原点对齐世界格点、probe 更新 3×3 footprint、alpha 置信度。SSGI/DDGI 在 native D3D12 与 strict D3D11 各 8 帧 validation 0；native/hybrid 回归与 CTest 30/30 通过。
- `b97f305` DDGI 修复：ProbeUpdate pass 使用 1024×32 atlas 专用 viewport（此前沿用 scene viewport，atlas 大部分未写入，表现像完全无效）；增加 `probeAutoFit` 默认开启，用场景包围盒推导 grid center/spacing，旧项目的大 spacing 自动收敛。状态区报告 effective spacing；DDGI on/off 截图 meanAbsRGB≈9.35。
- `9237cd3` GI debug：viewport debug 模式 11（GI indirect）与 12（DDGI probe 球体，atlas 辐照度着色）；新增 `GiDebugOverlay` pass、probe debug VS/PS、`--debug-view` CLI；native D3D12 与 strict D3D11 验证 0。
- `f94b313` 完整 DXR DDGI：`HardwareRayTracing` 新增 probe pass（b9 ProbeConstants、u10 irradiance、u11 depth、t16 history），逐 probe 追踪可配置 `probeRayCount` 条光线，输出 irradiance + mean/mean-squared depth atlas，hysteresis 与 view/epoch 重置，Renderer 采样用 Chebyshev visibility + hit ratio 软权重；native/hybrid 各 8 帧 validation 0，strict D3D11 保留屏幕空间 fallback；CTest 30/30。证据见 `local/docs/tasks/2026-11-19-realtime-gi/m5-debug-and-full-ddgi.md`。
- `26aaf1f` SSGI / 软件 DDGI 修复：SSGI trace 改采样当前 direct-lit colour，composite 补绑 albedo，`GI indirect` 保留 direct 给 trace，厚度加 `0.5×radius` 下限并去掉错误法线拒绝；DDGI 无 DXR 时改为软件光线追踪 fallback（每 probe 8 方向、最多 8 步屏幕空间 march），native D3D12 raster 与 strict D3D11 均显示 `Software ray-traced DDGI`。CTest 30/30，native/hybrid self-test 通过，SSGI/DDGI 验证 0。
- 项目修正（`86dab47`）：保留 `Projects/PathTracing_CornellBox`（渐进路径追踪示例），删除 `Projects/RayTracing_Simple`；README/EditorGuide/GlobalIllumination/Lighting 恢复 Cornell Box 引用并移除 RayTracing_Simple。当前 Project Manager 示例为 `Sandbox` 与 `PathTracing_CornellBox`。`tools/GenerateCornellBox.cpp` 保留为可选生成工具。
- `2df9527` probe debug 真实球体：RHI 增加 per-instance vertex attribute 与 `drawIndexedInstanced`，D3D11/D3D12 均支持；`GI probes` 用引擎内置 Sphere 模型（debug LOD）instanced 绘制真实球体，sceneLights + 固定 key light 方向性着色、probe atlas 辐照度染色，sphere/instance 按 grid/origin 缓存。CTest 30/30，native/hybrid self-test 通过。
- `d311996` probe grid 更新修复：grid dims／spacing／auto-fit 变化会清空 raster probe atlas validity、debug sphere instance cache 并 bump `giHistoryEpoch`，避免旧 atlas 映射到新网格产生大块红白残留；DXR probe history 同步重置。
- `0addad7` 软件 DDGI 反馈修复：Deferred 先输出 direct-only，probe update 从 direct copy 追踪（24 步），独立 `DDGI composite` 再把 probe 间接光加回 SceneColor；`GI indirect` debug 也由 composite 输出。消除 probe 采样自身历史造成的红白块/过曝。CTest 30/30，native/hybrid self-test 通过。
- `333c936` DDGI composite 目标修复：AA 开启时 raster 颜色在 `aaSourceImage`，composite 改写入 `rasterDestinationImage`，避免被 AA resolve 覆盖；Lit 下软件 DDGI 不再“看不见”。pipeline tests 覆盖 ProbeComposite 资源与硬件 DDGI 不执行 composite。
- `b097159` 软件 DDGI 平滑：probe 方向 8→64 并加入 per-probe 旋转，probe atlas 与上一帧邻域混合，接收端 3×3×3 软滤波；消除大漫反射面上的点状/岛状亮斑，保留低频颜色 bleed。native D3D12/D3D11、DXR 回归 validation 0；CTest 30/30，native/hybrid self-test 通过。
- `39c52ec`／`2297926` DDGI 饱和色能量补偿：软件 composite 去掉 `×2` 增益，新增 `BoundProbeIndirect` 按直接光亮度限制间接亮度，并同时用于硬件 DDGI；纯红/纯绿场景不再被 probe 间接光推成自发光盒子。这是显示空间近似的补偿，DDGI 本身仍是低频率、有偏的 probe 近似。
- `eef5db0` DDGI SH-L1 严格入射辐照度：probe atlas 改为 4096×32、每 probe 4 texels 的 SH-L1 入射 radiance；DXR 用线性 radiance 投影，软件路径新增 `ProbeLinearSource` 提供线性 direct radiance；接收端对 8 个 probe 做 SH-L1 插值并按法线计算 `E(N)` 与 `albedo/π·E`，两个后端共用线性空间 composite 后一次 `DisplayColor`。本轮验证：native D3D12/D3D11 software DDGI、DXR DDGI、probe/indirect debug validation 0；CTest 30/30；native/hybrid self-test 通过。
- `587b921` DDGI SH 阶数可配置：新增 `probeShOrder`（1/2）、UI、JSON 校验和 ProbeConstants layout；atlas 扩到 9216×32，L1 写 4 texels、L2 写 9；DXR 与软件 fallback 都按所选阶数投影，接收端支持 L1/L2 clamped-cosine 辐照度；切换时自动失效 atlas/history 并调整写 viewport。L1/L2 × native/D3D11/DXR/hybrid validation 0，ProjectSettingsTests/CTest 30/30。
- `77046e6` DDGI probe filter：两个后端在 composite 前增加 3×3×3 Gaussian SH 系数邻域滤波，消除大墙面残留的低频块状/岛状明暗斑；L1/L2、D3D11/D3D12/DXR validation 0，CTest 30/30。
- SSGI v2（`34b5e67`、`e672b08`、`cdbd3ea`、`e554fe3`、`42cbf37`、`9150b36`）：线性 HDR direct source、cosine 4-ray 半分辨率 trace、前向 depth march + front-face/thickness 可见性、off-screen 环境 fallback、per-object previous-world motion G-buffer（t16）、线性空间 composite、一帧 previous-indirect 二次反弹，以及 `indirectSpecular` 半分辨率 SSR（roughness 抖动、Fresnel/roughness 衰减、Environment miss fallback）。P0：native DXR reflection-only dispatch 供 SSGI 使用，hybrid DXR 通过 CopySubresourceRegion 拷入 RHI 反射目标；DXR 关闭时低分辨率 software DDGI probe update/filter 作为 off-screen fallback。native D3D12 + strict D3D11 + hybrid validation 0，CTest 30/30。

## 原生 DXR 编辑器视口错位修复（2026-11-19，补充模型）

用户截图显示 native DXR + Progressive GI 时 Scene Viewport 右侧有浅色错位竖带。根因：编辑器视口是 scene target 的子矩形，native HardwareResolve 却把 DXR 图像复制到 `(0,0)`；D3D11 旧路径使用 `viewportX/Y` 目标偏移。

- 修复：RHI 新增 `copyTextureRegionTo(dst, dstX, dstY, src, srcX, srcY, w, h, layer)`，旧 copy 委托 `(0,0)`；native HardwareResolve 改为在 `(viewportX, viewportY)` 解析。
- 回归：native self-test 比较同一视口在 `(0,0)` 与 `(64,48)` 的图像，AA 关闭 mismatches=0，FXAA=2（阈值 8）；临时还原旧行为会得到 18007 mismatches。
- 验证：native self-test exit 0；CTest 30/30；Sandbox native DXR 运行时 validation 0。
- 提交 `64a7c97` 已推送；任务 [v2](tasks/2026-11-19-native-dxr/v2.md)，经验 [NativeDxr](experience/NativeDxr.md)。

## 原生 D3D12 DXR 完成（2026-11-19，补充模型）

用户选择为纯 D3D12 补齐完整原生 DXR（阴影/反射/GI）。已让 DXR 与光栅共用同一个 D3D12 device/queue，不再依赖 D3D11 或旧共享 bridge。

- 实现：`HardwareRayTracing` 增加 native 模式（Device5/queue、普通 UAV 输出、独立 fence/allocator）；RHI 新增 `importTexture`；native 管线声明 HardwareTransport/HardwareResolve，硬件图像复制回场景色，Realtime GI 间接光复制到 RHI 纹理后由光照采样；`ProjectSettingsRules` 允许 D3D12 请求硬件光追/GI，UI 标签改为 `D3D12 (native DXR)`。
- 验证：native self-test 报告 DXR active（硬件预览 + Realtime GI 4/8 samples）；Sandbox native DXR 5 帧 validation 0；Realtime GI 12 帧、Progressive GI 64 samples validation 0；混合 hardware-rt self-test、editor self-test、AA self-test 通过；CTest **30/30**；严格 D3D11 validation 0。
- 提交 `c017ff8` 已推送；任务 [v1](tasks/2026-11-19-native-dxr/v1.md)，经验 [NativeDxr](experience/NativeDxr.md)。
- 边界：仍是“DXR 整幅硬件预览替换光栅”语义；DOF/Outline/解析光追、运动重投影、DispatchRays/SBT、异步多帧未迁移 native；DXR 不可用时保留光栅并报告原因。

## 网格 Asset Details：Slot 材质声明与居中环绕预览（2026-11-19，补充模型）

用户希望打开网格时能声明材质 Slot，并且预览可旋转但始终以物体为中心。

- Slot：Asset Details 逐行显示 Slot 名称与默认材质，可切换 `Actor fallback` 或工程／引擎材质；`Save slot materials` 写回网格 `.rasset` 并保留缩略图。旧式无 Slot 网格首次编辑时补一个 `Default` Slot；Engine Content 只读禁用编辑。
- 预览：`renderScenePreview` 增加 yaw/pitch/zoom，相机目标固定为网格包围盒中心；详情预览支持拖拽环绕、滚轮缩放、双击复位；窗口默认 700×720，多 Slot 可滚动。
- 安全：保存后 registry／AssetLibrary 重建，重新 `findMesh` 并避免旧 `entry/mesh` 指针；大网格保存会重写整个容器并阻塞 UI，界面有提示。
- 验证：Debug 构建 0 warning；`--editor-self-test --backend d3d11` **exit 0**（Slot 文本、yaw 像素差、模拟拖拽像素差、既有布局断言）；`MeshPersistenceTests` 新增 Slot 默认材质容器往返；CTest **30/30**；截图见 `artifacts/mesh-final2/`。
- 提交 `79bf6d0` 已推送；任务 [v1](tasks/2026-11-19-mesh-details-slots/v1.md)，经验 [AssetDetails](experience/AssetDetails.md)。
- 边界：不支持在详情窗口增删 Slot／重划分三角形区间，不支持拖材质到 Slot 行；保存非增量，398 MB 级网格可能明显停顿。

## 阴影抗锯齿：4×4 PCF 与 4096 阴影图（2026-11-19，补充模型）

用户反馈阴影边缘硬阶梯。根因是 2048² 阴影图覆盖 30 世界单位（每 texel≈1.46cm）且默认仅 2×2 PCF；FXAA/TAA 无法恢复阴影图缺失的覆盖率。

- 实现：阴影图 2048→**4096**；新增 `ShadowMapPCF16`（4×4 固定偏移、16 次双线性比较、约 8×8 texel 覆盖）并设为默认；旧 2×2/硬/3×3/PCSS/CSM/GTAO/Contact/Analytic/Disabled 保留；Scene 下拉、RenderFeatures、EditorSmoke 捕获同步。
- 验证：Debug 构建 0 warning；CTest **30/30**；`--native-d3d12-self-test` 通过；编辑器自测的阴影捕获与 PCF16 断言通过（随后仍是既有 Native Content focus 竞争）；2×2/4×4 对照图已加入公开文档。
- 提交 `eaf4193`（实现）、`8bbd1c9`（文档）已推送；任务 [v1](tasks/2026-11-19-shadow-aa/v1.md)，经验 [ShadowFiltering](experience/ShadowFiltering.md)。
- 边界：4096²×2 深度约 128 MiB；未做质量档位、级联动态分辨率、PCSS 时域降噪和局部灯独立阴影图。

## 抗锯齿完成与启动修复（2026-11-19，补充模型）

续接 Codex 中断的 AA 工作并修复引擎无法打开：FXAA resolve 曾把交换链目标写入跨帧成员 `aaResolvedImage`，原生 D3D12 在加载窗→编辑器窗 resize 时拒绝 `ResizeBuffers`。改为仅 TAA 历史持久，并在 resize 前释放 UI descriptor 借用与延迟对象。

- 功能：Off／FXAA／TAA 项目设置与实时 UI；实时 DXR GI 与独立硬件 resolve 请求 TAA 时回退 FXAA；离屏工具预览 FXAA；数据视图关闭；Progressive PT 跳过额外 AA。
- 验证：Debug 构建；正常启动 5 帧 exit 0／validation 0；`--aa-self-test` 默认、`--backend d3d11`、`--backend d3d12 --no-backend-fallback` 全 PASS；`--aa-ui-self-test` PASS；CTest **30/30**；`--native-d3d12-self-test` 通过（含 resize）；`--editor-self-test --backend d3d11` 仍受 Native Content focus 竞争影响，非 AA 回归。
- 提交 `b142549` 已推送 `origin/master`；任务 [v4](tasks/2026-11-19-antialiasing/v4.md)，经验 [AntiAliasing](experience/AntiAliasing.md)。
- 说明：上一状态条目“AA 未完成、完整应用不可编译”已被本轮取代，仅限于 AA 与启动路径；Project Settings 全量任务未在本次复验。

## Project Settings 依赖与重启反馈（2026-11-19）

显式硬件off清依赖反射/阴影/GI，Path Tracing启硬件并清独立反射，Realtime GI再清独立光追阴影；质量/贡献参数保留。非hybrid后端编辑清不支持请求，fallback仅native12可编辑；设备降级/旧工程加载不改请求。草稿、已保存配置和真实launch request共同驱动未保存待重启、已保存待重启、未保存撤回提示；即时光照不误报重启。新增`--project-settings-self-test`，无自动退出/重启。

当前工作树ProjectSettingsTests612 checks通过；隔离a28f38c加本任务修改的hybrid/strict11/native12真实GUI全部通过，图形错误0，分别确认235DXR/严格11不建12/原生12不建11。双主题、560×390及硬件off截图已检查，七项用户资产哈希不变。当前完整工作树包含用户已暂停的AA未完成实现，故不宣称完整应用集成可编译或运行；配置测试已在该树通过。引擎本轮未提交，公开说明已更新。详见[任务v3](tasks/2026-11-19-project-settings-links/v3.md)、[经验](experience/BackendSelection.md)。

## 引擎与工程加载反馈（2026-11-18）

后续尺寸修复已验证并推送 a28f38c：99% 场景准备阶段继续沿用首个无边框加载窗口的实际 963×542 尺寸和居中位置，不再将加载图拉伸到编辑器。GPU 预热后隐藏调整窗口，按完整目标尺寸建立 Dock 并呈现首帧，再显示常规编辑器。独立 Debug、三后端启动及缺 Shader 失败通过，所有加载提交尺寸／边框一致，120 帧退出 0 / 图形错误 0，加载页与正常编辑器实际图像已检查。仅提交本任务 4 文件，用户资产保持，bin 运行进程未关闭。见[任务 v3](tasks/2026-11-18-loading-progress/v3.md)。

提交完成：7e5ca88，仅本任务 17 文件，已按后续用户授权使用 CaptainRex0428 的既有个人 SSH 身份推送 origin/master。以 14a6b0d 的 D3D11 / 可选 DXR 基线独立构建，正常启动、缺 Shader 失败及 4/4 CTest 通过，图形错误 0；后端迁移与 Inspector 继续留在工作区。真实 9 Shader / 24 材质状态，脚本兼容新旧后端入口；共享暂存区和工作文件保持。见[独立提交 v2](tasks/2026-11-18-loading-progress/v2.md)。下方“未提交／三模式”是 v1 混合工作区的历史范围，以此提交记录为准。

加载流程接入可选 LoadProgress：9 Shader、224 PSO、可选 DXR、Engine / Project 材质与网格、场景、Content 索引／缩略图及编辑器首帧。资源显示真实当前项／总数和 UTF-8 文件名，加载页两行排版并保留百分比列；进度不再提前 100% 或切窗后退回 65%。Project Manager 仅创建 device/UI，避免重复编译场景管线。新增 --loading-report JSONL 与 Test-LoadingProgress.ps1。

独立 Debug 无编译警告，相关 CTest 4/4。严格 11 / 原生 12 / 混合实际启动通过，约 140 工作事件、80 个进度值，最大跳幅约 4.4% / 4.4% / 10.4%；缺 Shader 在 5.45% 失败不报 Ready。真实加载页与 Project Manager 图片已检查，取消及最小化恢复通过，47 个源资产／Shader 哈希保持。引擎未提交，未覆盖用户 EXE；其他 Inspector 改动保留，证据仅对应冻结快照。见[任务](tasks/2026-11-18-loading-progress/README.md)、[经验](experience/LoadingProgress.md)、[讨论](conversations/2026-11-18-loading-progress.md)。

## 原生 Frame Inspector / Profiler / Runtime（2026-11-18）

2026-11-19用户授权提交后，引擎实现为`6a243b2`，技术文档为`c2ab76e`；随后授权沿用CaptainRex0428个人SSH统一两仓库并直接推送，引擎origin/master已同步至`c2ab76e`，远端HEAD已核对。包含相互依赖的后端M1/M2/M3与Inspector实现。并行加载窗口v3的应用/脚本/说明差异及七项用户资产保留；本任务应用入口采用与原验收SHA一致的快照单独暂存，没有覆盖工作文件。下文“未提交”是原交付时状态，最新边界见[任务v5提交补记](tasks/2026-11-18-native-inspector/v5.md#2026-11-19-授权提交补记)。

用户明确授权自研原生渲染检查和程序debug/profile工具。两API已实现详细RHI Draw/PSO/Viewport/绑定/逐Draw常量版本及两份冻结Shader源码、选定Pass Before/After与CSM层/最终输出、原始像素/独立显示转换、含资源的`.raframe`离线包和事务失败保旧。12真实GPU Pass时间戳已接入；CPU多线程时间线/Scope聚合、统一帧线程日志、图形消息及进程memory/cache分类可用。native调用和预算缺口明确partial，不推断默认绑定。

最终Debug全量构建无告警、Premake接入检查通过，CTest29/29（6.21秒）；最终两API Inspector专项通过，覆盖本地/offline全部25个实际GPU显示通道、同捕获FrameID Ready计时和冻结/预算/损坏事务。两API最终UI专项双主题/760与300宽/实际控件/输入隔离通过且截图已审查。混合硬件光追251次真实dispatch/图形错误0，严格11的13张非UI图与原基准逐字节一致、Validate-Render通过。双向跨API离线打开及原生12七组功能回归保留v2通过证据，不冒充最终版本重跑。最终163文件源码身份/exe与七项用户资产哈希均已核对；具体证据见[任务v5](tasks/2026-11-18-native-inspector/v5.md)。

完整hybrid Editor本轮已通过全部Diagnostics原始/显示/冻结/Trace/GUI及Content/保存等，末段跨窗拖放在真实前台断言失败；查询确认系统前台是LockApp（锁屏），一次自有窗口激活也失败。**本轮不记完整Editor PASS**，解锁后补验，不改系统锁或削弱断言。v1–v4失败与修复均保留。完整命令回放/任意Draw图像/Pixel History/Shader单步、CPU源码断点/采样/全分配追踪仍未实现；外部RenderDoc未实测。

任务与经验见[索引](tasks/2026-11-18-native-inspector/README.md)、[NativeDiagnostics](experience/NativeDiagnostics.md)，公开[Diagnostics](../../docs/Diagnostics.md)／[后端矩阵](../../docs/RenderBackends.md)已同步。任务期间其他加载进度提交将引擎HEAD推进到7e5ca88；Inspector与原M1/M2/M3未提交，Sandbox七项用户资产继续保护。下方M3“Inspector/GPU时间未迁移”仅为历史状态，以本节为准。

## 原生 D3D12 主后端 M3 首阶段（2026-11-18）

用户授权直接实现。独立D3D12设备／交换链／实际RHI场景／ImGui／加载窗口已接通，禁回退时不创建D3D11。真实网格材质、Forward/Deferred、光栅阴影、GTAO/Contact、相机、独立预览、resize、截图与Shader成功热编译／失败保留通过；共享声明绑定真实资源，12后端执行状态转换。严格11和11+DXR模式保留，Auto仍选严格11。

Debug无告警、CTest25/25（实际11/12 GPU），原生12专项及六案例启动矩阵通过；13张严格11非UI图对M2逐字节一致，9张可比较跨API图最多2像素有单通道1级差异。混合HRT251实际dispatch、完整Editor回归通过，图形错误0。最终文案修正版本实际加载→编辑器4帧、D3D11 device=no、debug errors0，截图已检查；主体全套验收与最终文案版本身份分别保存在任务日志。用户Sandbox七项资产哈希不变，Premake/CMake均接入。

原生12的软件射线、DXR/GI、DOF、Outline、Inspector冻结资源及GPU查询未移植；真实RenderDoc抓帧、GBV和副窗口GUI像素未验收。同步fence首版不承诺性能提升，设备丢失／热切／完整Graph仍未实现。引擎M1/M2/M3代码未提交，协作记录独立同步。详见[任务v1–v3](tasks/2026-11-18-native-d3d12/README.md)、[经验](experience/RhiMigration.md)、[公开能力矩阵](../../docs/RenderBackends.md)。下一步优先补原生12诊断与实际RenderDoc抓帧，再按功能需求移植；下方M1/M2的“原生12未实现”为历史状态，以本节为准。

## D3D11 实际 RHI 切片 M2（2026-11-18，历史阶段）

术语与交付范围澄清见[记录](conversations/2026-11-18-rhi-slice-boundary.md)：剩余native指直接D3D11调用，与尚未实现的原生D3D12主后端分开；RenderDoc实际抓帧尚未验收。

用户授权实际RHI改写。已接通Rhi.h typed RAII资源／命令 → D3D11适配器 → 网格、常量、目标、Shader／图形管线、阴影和Forward/Deferred实际Draw。附件Load/Clear/Store与真实采样句柄驱动执行；候选热编译先创建受支持PSO再发布。旧IRenderBackend仍独立占位，native UI／Outline／DOF／capture／软件光追结构化数据／DXR桥和呈现尚未整体迁移；原生12、完整Graph、自动屏障未实现。

Debug无告警、CTest24/24（含WARP实际像素回读）、五案例启动矩阵、13张旧新非UI图逐字节一致、Validate-Render通过。48 RHI Pass／80 Draw（64 indexed）证明真实场景提交；严格11无D3D12初始化／DXR0。混合完整HRT217dispatch/errors0；最终构建相机9组含DOF／四视图／预览与真实DXR通过。材质状态9组、mesh属性7组/27DXR和GC回收/GUI通过。完整Editor首轮因夹具缺项目.rasset未完成；改用HEAD Sandbox隔离副本后全套通过，exit0/errors0，含Diagnostics冻结回读／实际几何计数、跨窗口拖放／重停靠、保存、四视图与独立预览。实际RenderDoc capture尚未验证。用户Sandbox七文件hash保持。引擎代码未提交；详见[任务v1–v3](tasks/2026-11-18-rhi-slice/README.md)、[经验](experience/RhiMigration.md)、[公开执行范围](../../docs/RenderBackends.md#实际-rhi-执行范围)。下一步是余下RHI资源／绑定与呈现边界，再推进M3原生12；不把native bridge叫作原生12后端。
## 后端启动 M1 与三模式选择（2026-11-18）

用户授权实施并明确三个正式模式：严格D3D11、D3D11+D3D12/DXR混合、原生D3D12。M1已接通真实App配置／CLI覆盖、设备初始化门控、请求／实际状态、保存后下次启动及旧字段兼容；混合规范key为d3d11Dxr。原生12未实现，依回退开关严格转11或报错，不把选择器当作实际RHI。

Debug／CTest23/23、五案例真实启动矩阵与13张光栅GPU图逐字节一致；混合硬件全套217dispatch/errors0，最终规范key入口3次DXR/errors0；严格11最终真实控件／保存／截图通过、DXR按预期跳过且初始化未尝试／dispatch0。后端长标签裁切已在截图检查中修复。用户Sandbox七文件SHA256保持。引擎代码未提交，协作日志单独同步。详见[任务v1–v3](tasks/2026-11-18-backend-startup/README.md)、[经验](experience/BackendSelection.md)、[公开配置说明](../../docs/RenderBackends.md)。后续D3D11实际RHI与资源声明切片已开始，见本页上方M2；原生12／设备丢失／热切未实现，完整Editor历史失败状态已由本页上方M2正确夹具的最新通过结果取代。

## 当前方向：独立 D3D12 主后端与 D3D11 回退（2026-11-18，M1已启动）

用户明确要求独立 D3D12 主渲染后端，并能选择回退到 D3D11；近期排序为真实后端选择／生命周期→D3D11 实际 RHI 与资源声明→原生 D3D12 场景及编辑器→功能覆盖／原生 DXR。后端选择与光追分开，严格 D3D11 不初始化 12；Auto 不选择尚未验收的实验后端。初始讨论见[记录](conversations/2026-11-18-native-d3d12-backend.md)与[分阶段方案](design/NativeD3D12Backend.md)，后续M1实现以本页上方最新任务为准。

## 历史建议：渲染与诊断近期优先级（2026-11-18，已被上述需求取代）

用户希望先聚焦渲染和RenderDoc式调试。建议顺序为Pass前后捕获/比较→线性HDR与显示转换边界→基于实测优化单个热点，保留外部RenderDoc作为专业调试补充；完整RHI/RenderGraph/多后端/节点材质/NPR/完整回放不做近期前置。尚未启动实现。见[讨论](conversations/2026-11-18-rendering-diagnostics-focus.md)与[近期方案](design/RenderingDiagnosticsFocus.md)。

## Pass／Render Graph／RHI 与帧检查器答疑（2026-11-18）

澄清逻辑Pass、显式资源声明与Render Graph演进边界，纠正RHI只是CPU参数打包及DX11/DXR“不通”的理解；记录当前同卡DX11主渲染+DX12 RayQuery+共享图像/fence关系。Frame Inspector形成Pass快照→离线包→指定Draw检查→受限回放→像素历史提案，未实施代码。见[讨论](conversations/2026-11-18-pass-graph-rhi-inspector.md)、[学习](learning/PassGraphRhiRelationship.md)、[方案](design/FrameInspectorEvolution.md)。

## DevLog02之后的功能与管线审计（2026-11-18）

已核对DevLog02=cc68a1b至当前14a6b0d全部83提交（含merge）及当前源码，整理资产/保存/相机/四视图/两种景深/五灯/GI/Pass声明/诊断的原因、收益与限制，明确已有功能与本期新增、提案与实现。引擎最后源码提交仍为10-31；11月主要复验及学习记录。发现Cornell采样README、重复灯光说明、Tone Mapping/阴影提示等文档不一致，逐项登记；本轮没有改引擎、重建或GPU复验，Sandbox资产保留。完整结论和83提交清单见[讨论审计](conversations/2026-11-18-engine-audit-after-devlog02.md)，作为下一步开发讨论依据，不视为新实现授权。

## editor smoke 环境问题排查（2026-11-12，补充模型）

`--editor-self-test` 的 “Native Content did not gain focus” 根因是非前台进程的 `SetForegroundWindow` 被拒；测试侧用 `AttachThreadInput` 激活助手修复。随后暴露并修复：夹具目录复用（旧 `.rasset`）、ScrollMax 布局后增长、以及 Project Settings 按 UI 组管理 disabled 作用域导致 FXAA+TAA 同时关闭时出现 `Missing EndDisabled()` 的真实 UI bug。

- 结果：`--editor-self-test` 退出 0、59 个 PASS 段、validation 0；全量重建 0 warning。
- 任务 [v1](tasks/2026-11-12-editor-smoke-focus/v1.md)；经验 [EditorSmoke](experience/EditorSmoke.md)。

## DX12 共享后处理接入工程设置（2026-11-12，补充模型）

`rendering.dx12Post` 写入工程 manifest，Project Settings 增加复选框；`--dx12-post` / `--no-dx12-post` 作为单次覆盖。默认关闭，不可用时仍回退 DX11。

- 工程字段 true 时无需 CLI 即启用；`--no-dx12-post` 可关闭；默认工程保持 DX11；validation 0。
- `--hardware-rt-self-test`、`--backend-self-test`、`Validate-Render.ps1` PASS；全量重建 0 warning。`--editor-self-test` 在本机卡在 native Content 前台焦点断言（环境问题，非本改动）。
- 任务 [v7](tasks/2026-11-11-dx12-scene-share/v7.md)。

## 异步 RHI 提交落地（2026-11-12，补充模型）

DX12 后处理提交改为有界异步：每次 draw 独立 SRV 描述符堆、常量缓冲 4 槽 ring、提交对象最多 8 个在飞；读回/销毁前排空。共享 fence 继续负责跨设备顺序。

- 验证：Sandbox MAE 2.02e-7、TAA MAE 8.4e-5、运动模糊/景深均正常；validation 0；backend/TAA/Validate PASS。
- 600 帧实测：默认 38.10s，`--dx12-post` 38.10s（与同步版差异在噪声内，场景不是 CPU 瓶颈）。
- 过程：先按 v5 分析试过“只删等待”，画面静默错误（MAE 90.8）；补齐多版本后通过。
- 任务 [v6](tasks/2026-11-11-dx12-scene-share/v6.md)；分析 [v5](tasks/2026-11-11-dx12-scene-share/v5-async-analysis.md)。

## 异步 RHI 提交尝试（2026-11-12，未落地）

去掉 DX12 `executeCommands` 的 `waitForGpu` 后画面错误（Sandbox MAE 90.8），validation 仍为 0。根因是共享 SRV 描述符堆与常量缓冲未做多版本；已回退，分析见 [v5](tasks/2026-11-11-dx12-scene-share/v5-async-analysis.md)。

- 600 帧实测：默认 32.96s，`--dx12-post` 33.35s（≈0.65ms/帧，噪声内）。
- 结论：异步需先做 descriptor/constants ring，再谈默认开启；`--dx12-post` 保持实验开关。

## DX12 完整后处理链：运动模糊与景深（2026-11-12，补充模型）

新增共享 HDR 输出（RGBA16F RT），运动模糊（176 B）与景深（48 B）迁到 DX12；新增 `--dof` 调试开关。后处理链 Tonemap/TAA/运动模糊/景深/FXAA 均可由 DX12 消费共享场景纹理。

- 运动模糊：MAE 1.0e-7、最大差 1；景深：MAE 3.0e-7、最大差 1；validation 0。
- 学习笔记：[DX12 共享场景纹理后处理](tasks/2026-11-11-dx12-scene-share/DX12共享后处理.md)。
- 任务 [v4](tasks/2026-11-11-dx12-scene-share/v4.md)。

## DX12 共享深度/TAA 历史与共享 fence（2026-11-12，补充模型）

`--dx12-post` 现在共享场景深度（R32_TYPELESS，每帧拷贝）与 TAA 历史（RGBA8），DX12 执行 TAA（3 源、b0 208 B）并回拷写目标/显示目标；同步改为共享 fence（DX11 `ID3D11Fence` → DX12 `OpenSharedHandle` + 队列 Signal/Wait），query 仅作回退。

- TAA 工程内 DX12 TAA 与 DX11 RHI TAA：MAE 8.4e-5、最大差 15、changed>3 0%；validation 0。
- 新增 `IRenderBackend` fence 接口与 backend smoke 用例；`--taa-self-test`、`Validate-Render.ps1` PASS；全量重建 0 warning。
- 限制：运动模糊/DOF 仍在 DX11；共享输入每帧多一次拷贝；DX12 RHI 绘制仍同步，提交仍串行。
- 任务 [v3](tasks/2026-11-11-dx12-scene-share/v3.md)。

## DX12 共享 HDR/Bloom，Tonemap 迁到 DX12（2026-11-11，补充模型）

`--dx12-post` 扩展：新增共享 RGBA16F HDR 与 Bloom，DX12 执行 Tonemap（2 源、b0 112 B）后回拷 `SceneColorPost` 或显示目标；FXAA 继续在 DX12。

- 同帧与默认路径比较：MAE 2e-7/255、最大差 1、changed>3 0%；validation 0，退出 0。
- 回归：`--backend-self-test`、`--taa-self-test`、`Validate-Render.ps1` PASS。
- 限制：深度/TAA 历史未共享；CPU 串行；实验开关默认关闭。
- 任务 [v2](tasks/2026-11-11-dx12-scene-share/v2.md)。

## DX12 场景共享：显示色 FXAA（2026-11-11，补充模型）

`--dx12-post` 让 FXAA 在独立 DX12 设备上消费 DX11 共享的显示色 RGBA8 纹理，并回拷显示目标。共享纹理为 NTHANDLE|KEYEDMUTEX；DX11 每帧 copy→等待→DX12 draw→copy 回，失败回退 DX11 RHI。

- 同帧与默认路径截图像素比较：MAE 2e-7/255、最大差 1；validation 0，退出 0。
- 修复：共享目标缺 RTV 描述符、共享纹理缺 KEYEDMUTEX、CopyResource 前未解绑 RTV/SRV。
- 回归：`--backend-self-test`、`--taa-self-test`、`Validate-Render.ps1` PASS。
- 限制：仅显示色；HDR/深度/历史未共享；CPU 串行同步；实验开关默认关闭。
- 任务 [v1](tasks/2026-11-11-dx12-scene-share/v1.md)；经验并入 [RhiPostProcessing](experience/RhiPostProcessing.md)。

## RHI 管线绑定契约反射校验（2026-11-11，补充模型）

`RhiPipelineDesc` 增加 `sourceCount` 与 `constantBufferSize`；`createPipeline` 用 `D3DReflect`（DX11）和 DXC `CreateReflection`（DX12）校验 `t0..tN / s0 / b0`、VS 输入与 PS 输出。`SceneRenderer` 七条后处理管线补齐真实声明，错误在创建阶段返回并走既有回退。

- 负例（声明 0 源读 t0、b0 尺寸不符）与真实 `Shaders/Private/Rhi/*.hlsl` 在两条 API 上创建全部七条管线均通过。
- 验证：Debug 无 warning；`--backend-self-test`、`--taa-self-test`、`Validate-Render.ps1` PASS（RHI 路径未静默回退）。
- 限制：源码级校验，不验证运行时 descriptor；DX12 依赖 DXIL reflection；`BackendTests` 本轮未运行。
- 任务 [v1](tasks/2026-11-11-rhi-pipeline-reflection/v1.md)；经验并入 [RhiPostProcessing](experience/RhiPostProcessing.md)。

## DX12 共享纹理导入脚手架（2026-11-02，补充模型）

新增 `createTextureFromSharedHandle`：DX12 可打开 DX11 共享纹理，DX11/Base/Null 明确拒绝；BackendTests 55。

- 尝试 DX11 `SHARED_NTHANDLE | KEYEDMUTEX` → DX12 打开并回读，句柄创建/打开成功，keyed mutex 显式 Acquire/Release 后 DX12 回读颜色一致；进一步用共享 FP16 HDR 场景纹理执行 DX12 后处理 Pass 并回读正确，GPU smoke 通过。
- 结论：共享资源是 DX12 场景后处理的前置，但同步契约与 SceneRenderer 接入尚未完成；不能宣称 DX12 场景后处理已可执行。
- 提交：`7f49f94`、`6d11427`、`1bb5110`（未推送）；任务 [v5](tasks/2026-11-02-rhi-post-compliance/v5.md)。剩余：SceneRenderer 的场景纹理共享接入、跨设备同步、调试视图 RHI 化。

## RHI DOF 与纹理拷贝（2026-11-02，补充模型）

DOF 迁到 RHI：新增 `copyTexture`（DX11 CopyResource、DX12 copy 屏障），先把 `SceneColor` 复制到 FP16 临时目标，再用 t0 色/t1 深度写回场景；失败回退原生 DOF。

- 新增 `Shaders/Private/Rhi/DepthOfField.hlsl`、`RhiDofConstants`；场景 RHI 纹理带 RTV 以承接 DOF 目标。
- `--taa-self-test` 增加 DOF 开关图像差异检查，确认 `RHI DOF active`；`--backend-self-test` 在 DX11/DX12 验证 copy；BackendTests 54。
- 验证：`Validate-Render` PASS（errors 0）、TAA/backend smokes、硬件 RT 235 dispatches PASS。
- 提交：`2e0334b`（未推送）；任务 [v4](tasks/2026-11-02-rhi-post-compliance/v4.md)。
- 剩余：DX12 场景纹理共享未实现；调试视图 Tonemap/Bloom 仍原生；“整条链迁移”尚未完成。

## RHI Bloom 三 Pass（2026-11-02，补充模型）

Bloom 阈值/Bright 与 H/V 模糊迁到 RHI：FP16 双目标 ping-pong、64 B 常量（阈值/强度/texel/方向/viewport/全分辨率尺寸）。

- `debugView=0` 走 RHI Bloom；Unlit/法线等调试视图保留原生 Bloom，避免直通语义被 Bloom 合成改写；失败回退原生三 Pass。
- 首次实现误用半分辨率尺寸做 viewport 分母，Unlit 变黑；改为全分辨率 `sceneSize` 并 gating 后 Validate 通过。
- 验证：`Validate-Render` PASS（errors 0）、`--taa-self-test`、`--backend-self-test`、硬件 RT 235 dispatches PASS。
- 提交：`bd99a39`（未推送）；任务 [v3](tasks/2026-11-02-rhi-post-compliance/v3.md)。剩余：DOF 仍 D3D11；DX12 场景纹理共享未实现；整条链未完成。

## RHI Tonemap 与运行时交换链（2026-11-02，补充模型）

解决“RHI Tonemap 在运行时只输出天空”的阻塞：根因是原生 FXAA 消费 RHI 写入的 post，而非 HDR 导入；运行时改为 RHI FXAA 写 `SceneColorDisplay` 后回拷交换链。

- Tonemap 普通视图（`debugView=0`）迁到 RHI：`Shaders/Private/Rhi/Tonemap.hlsl`，HDR 场景 + Bloom 双源，b0 承载曝光/Bloom/调试视图/viewport/调色/暗角；数据调试视图保留原生直通 tonemap。
- 运行时 FXAA 也走 RHI 并回拷交换链；解决天空输出。
- 验证：`Validate-Render` PASS（errors 0，normals 检查恢复）、`--taa-self-test` PASS、`--backend-self-test` PASS、BackendTests 53、硬件 RT 235 dispatches PASS。
- 提交：`d324683`（运行时 FXAA 回拷）、`12cbfd6`（RHI Tonemap）；均未推送。
- 任务 [v2](tasks/2026-11-02-rhi-post-compliance/v2.md)。未完成：Bloom/DOF 仍 D3D11；DX12 场景纹理共享未实现；整条链迁移未达成。
- 工作区另有此前存在的 `.idea/.idea.RestArtEngine/.idea/.name` 删除，未纳入提交。

## RHI 后处理设计合规审计（2026-11-02，补充模型）

按用户要求把 `RestArtEngine_Workspace` 克隆到 `local/`，设置 SSH remote，执行 Status/Install（全部 Synced），读取 AgentEntry、TaskWorkflow、RenderingDevelopment、rendering skill 后审计后处理/RHI 设计。

- 修正契约错误：`PostEffect::Taa` 从 `LinearHdr` 改为 `Display`；TAA 实际在 tonemap 后、读 `SceneColorPost`，阶段枚举必须反映执行位置。
- 拆出 `Shaders/Private/Rhi/{Fxaa,MotionBlur,Taa}.hlsl`，`SceneRenderer` 不再内嵌 RHI post shader；`reloadShaders` 成功后失效并重编 RHI 管线，失败保留 D3D11 回退。
- 更新公开文档的过时 TAA/RHI/测试计数描述；新增原生 FP16 导入 smoke 结论。
- 验证：PostProcessTests 375、RenderPipelineTests 148、ProjectSettingsTests 783、BackendTests 53；`--taa-self-test`、`--backend-self-test`、`Validate-Render`、`--hardware-rt-self-test`（235 dispatches）全 PASS，D3D11 errors 0。
- 提交：引擎 `25cf91d`（未推送）。任务记录 [v1](tasks/2026-11-02-rhi-post-compliance/v1.md)，经验 [RhiPostProcessing](experience/RhiPostProcessing.md)。
- 未完成：Tonemap/Bloom/DOF 仍为 D3D11；DX12 场景纹理共享未实现；RHI post pipeline 尚无 D3DReflect 契约校验；整条后处理链迁移未达成。Tonemap 试验的 sky-only 现象已缩小到场景目标/句柄生命周期，独立 FP16 导入正常。
- 工作区另有此前存在的 `.idea/.idea.RestArtEngine/.idea/.name` 删除，未纳入本轮提交。

## 讨论记录规范（2026-11-11，补充模型）

用户要求此后每次讨论都记录为学习／经验，并能跨机同步。已固化到协作库：

- [AgentEntry「讨论与学习记录（必须）」](AgentEntry.md#讨论与学习记录必须) + [TaskWorkflow 第 5 步](TaskWorkflow.md#5-讨论与学习记录) + [讨论模板](conversations/_TEMPLATE.md)；
- 记录路由：`learning/`、`conversations/`、`experience/`、`design/`，索引更新到 [DevelopmentExperience.md](DevelopmentExperience.md)；
- 技能 `restarengine-context/core/delivery` 增加讨论收尾要求，运行副本 `Sync-Workspace` 20/20 Synced；
- 规范提交 `5c80e57`；讨论记录：[conversations/2026-11-11-discussion-recording-policy.md](conversations/2026-11-11-discussion-recording-policy.md)。引擎未改代码，HEAD 仍为 `14a6b0d`。
## 学习与方案文档（2026-11-11，补充模型）

把 RHI → PSO／G-Buffer／CBuffer → Shader 语言与材质模板的讨论整理为三份文档，未改引擎代码。

- 会话记录：[conversations/2026-11-11-rhi-material-system.md](conversations/2026-11-11-rhi-material-system.md)（问题、结论、误解澄清、未决项）。
- 学习笔记：[learning/RenderingArchitecture.md](learning/RenderingArchitecture.md)（Pass 流、延迟渲染、常量打包、PSO/RHI、多光源、阅读路线与练习）。
- 方案提案：[design/MaterialTemplateSystem.md](design/MaterialTemplateSystem.md)（模板 API、分阶段路线、RHI 接口、风险与里程碑）。
- 边界：RHI 仍是骨架、材质模板未实现；引擎 HEAD 仍为 `14a6b0d`。
## 进度快照（2026-11-10，补充模型）

距 2026-11-03 同步后，远端无新提交；本轮做了状态核对与复验，未改引擎源码。

- 引擎：`master` 与 `origin/master` 同为 `14a6b0d`（最后提交 10-31，包含 render pass/feature 声明、README 重写、示例材质与 Cornell GI 修正）。工作区仍只有既有 Sandbox 用户资产：4 个已跟踪修改、3 个未跟踪（Ground／Yellow／R8），未提交也未删除。
- 复验：CMake Debug 构建通过；CTest **22/22**。`--editor-self-test` 的原生 Content focus 断言仍受桌面前台限制，未取得通过；窗口/焦点相关源码自 10-31 未变。
- 协作库：`main`／`origin/main` 同为 `c27a84f`；技能为 6 个项目 skill 加 `ue-material-agent` 参考 skill、3 个 agent，`Sync-Workspace` 显示 **20/20 Synced**，清单 20 个文件。
- 未决：完整编辑器自测需要可交互前台桌面；Sandbox 资产是否迁移或提交由用户决定；DevLog03 尚未开始，本阶段素材未整理。
## 引擎远端同步（2026-11-03，补充模型）

- 快进 `a46432b..14a6b0d`（4 个提交，54 文件，+2347/−356）：`7f8a585` 声明 RenderPipeline/RenderFeatures、抽取 ShadowPass、Diagnostics 特性矩阵；`f9796d3` 修复 RayTracing_Simple 材质 JSON；`fca018a` 重写 README 并补充 16 张文档图与 `docs/RenderPipeline.md`；`14a6b0d` 提升 Cornell GI 采样并修正材质引用。
- 验证：CMake Debug 全量构建通过、未出现 warning；CTest **22/22**（新增 RenderPipelineTests）；Sandbox 4 个已跟踪修改与 3 个未跟踪资产原样保留。
- `--editor-self-test` 在 `Native Content did not gain focus before the drag` 失败；本轮提交未改动窗口/焦点路径（MinimalApp、ImGui、EditorDockManager、SceneEditor 的 diff 为空），属桌面前台焦点竞争，未写成通过。
- 记录：[任务 v1](tasks/2026-11-03-engine-sync/v1.md)。