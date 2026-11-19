# 实时 GI 四项扩展设计

日期：2026-11-19
状态：设计/分阶段实施，未完成

## 目标

在现有 `PathTracing`（Progressive/Realtime）基础上增加四项可配置能力：

1. 现有 Realtime PathTracing 的时域/空域降噪，带相机重投影和逐物体运动向量；
2. SSGI（屏幕空间 GI），用于光栅后端和无 DXR 设备；
3. DDGI（动态漫反射探针 GI）；
4. ReSTIR 直接光/间接光采样复用。

四者不是对等的“GI 算法”：

- 1 是现有实时 GI 的**采样降噪层**；
- 4 是**采样复用层**，可作用在 PathTracing/Direct 上，不应伪装成独立传输算法；
- 2/3 是独立的 GI 传输近似，可作为 `GlobalIlluminationMethod`。

统一原则：请求/生效/原因分层；不可用时不改写工程请求；所有新能力默认关闭或保持现有行为，避免改变当前画面基线。

## 配置模型

建议把 `GlobalIlluminationMethod` 扩展为：

```
Disabled
PathTracing      // 现有，保留 Progressive/Realtime
ScreenSpace      // SSGI
ProbeGrid        // DDGI
```

ReSTIR 不加入该枚举，而是在 `GlobalIlluminationSettings` 增加采样层配置：

```cpp
enum class GlobalIlluminationDenoiser { Off, Spatial, TemporalSpatial };
enum class GlobalIlluminationMotionVectors { CameraOnly, PerObject, Automatic };
enum class GlobalIlluminationSampling { Path, ReSTIR };

struct GlobalIlluminationSettings {
    GlobalIlluminationMethod method;
    GlobalIlluminationMode mode;
    // existing diffuse/specular/intensity/samples/bounces
    GlobalIlluminationDenoiser denoiser = TemporalSpatial;
    GlobalIlluminationMotionVectors motionVectors = Automatic;
    GlobalIlluminationSampling sampling = Path;
    bool restirDirect = true, restirIndirect = true;
    std::uint32_t restirMaxReservoirs = 8;
    // SSGI
    std::uint32_t ssgiSteps = 12;
    float ssgiRadius = 2.0f;
    float ssgiIntensity = 1.0f;
    // DDGI
    std::uint32_t ddgiProbeCounts[3] = {8,4,8};
    std::uint32_t ddgiRaysPerProbe = 16;
    std::uint32_t ddgiUpdateBudget = 1;
    float ddgiIntensity = 1.0f;
};
```

`Automatic` 运动向量：有对象历史/物体 ID 时使用 PerObject，否则回退 CameraOnly，并在 `GlobalIlluminationStatus.reason` 说明。

工程 JSON 与 UI 按现有 `globalIllumination` 对象扩展；旧工程缺字段使用默认值。新增字段只影响 Realtime/GI 有效路径，默认保持当前行为。

## 里程碑

### M1 — 运动向量 + 实时 PT 时域降噪

资源与数据：

- 增加 motion-vector 渲染目标（RGBA16F/两个分量即可），在 Forward/Deferred 几何或单独 prepass 生成：
  - 相机运动：`currentClip - previousViewProjection * worldPos`；
  - 逐物体：`ObjectConstants` 增加 `previousModel`，`SceneConstants` 增加 `previousViewProjection`；
  - 当前/上一帧 clip 位置在 vertex shader 输出，PS 写 motion vector；无历史对象回退相机运动。
- Actor 变换历史按 `ActorId` 缓存；几何/材质变化、相机切换、视图尺寸变化使历史失效。
- Deferred G-buffer 增加对象 ID 或直接利用 motion-vector target；Forward 使用同一 motion pass。

降噪：

- 新 compute pass 读取当前 GI（indirect/完整 HDR）、深度/法线/albedo、motion、上一帧 GI 历史；
- 相机重投影 + per-object 重投影（自动选择）；
- 深度/法线/roughness 拒绝、邻域 clamp、方差估计、可选 à-trous 2–3 轮；
- 配置 `Off/Spatial/TemporalSpatial`；现有 5×5 空间滤波保留为 `Spatial`。
- TAA 复用同一 motion-vector 通路（可配置），但不要强依赖；先启用 GI 降噪。

验收：`--native-d3d12-self-test` 新增运动相机/移动 Actor 的 GI 稳定性截图、历史重置、validation 0；D3D11 后端无 DXR 时保持旧路径。

### M2 — SSGI

- 新 compute/屏幕空间 pass：基于场景深度/法线在世界空间或屏幕空间步进，输出彩色间接光；
- 时域累积使用 M1 的 motion-vector 通路；边缘/厚度拒绝；
- Forward 与 Deferred 都消费；质量档位（步数/半径/强度）；
- 严格 D3D11 与 native D3D12 光栅均可用；DXR 不可用时的 fallback。

验收：D3D11 严格后端截图、native 光栅截图、时域稳定性、无越界/背面泄漏基准场景。

### M3 — DDGI 动态探针

- 探针体积/网格（默认 8×4×8，可配置）覆盖场景包围盒；八面体 irradiance+depth atlas；
- 更新：DXR RayQuery（native/hybrid）或 cubemap 渲染 fallback；每帧更新部分探针，fade/relocation；
- 光照 Pass 三线性采样 irradiance，乘 albedo；与 SSGI 可叠加（近场 SSGI + 远场 DDGI）；
- 资源/显存预算与调试视图；工程 UI 配置。

验收：动态移动光源/物体下的间接漫反射截图，probe 泄漏基准，native/hybrid、光栅 fallback。

### M4 — ReSTIR 直接/间接采样复用

- DI：初始候选 + 时域/空域 reservoir 复用、可见性/偏差校验；
- GI：对间接样本做 reservoir 复用，接在 PathTracing Realtime 之上；
- 配置 `sampling = Path / ReSTIR` 与 direct/indirect 开关；
- 与 M1 降噪兼容：先 ReSTIR 再降噪，避免双重过滤。

验收：多光源场景、相机/物体运动、闪烁/拖影检查、validation 0；不支持时保留 PathTracing 并报告原因。

## 后端与降级

| 能力 | native D3D12 | 混合 D3D11+DXR | 严格 D3D11 |
|---|---|---|---|
| PathTracing + 降噪 | 可用 | 可用 | 不可用 |
| PerObject 运动向量 | 可用 | 可用（motion pass） | 可用（光栅） |
| SSGI | 可用 | 可用 | 可用 |
| DDGI | DXR 更新 | DXR 更新 | cubemap/无更新 fallback |
| ReSTIR | DXR | DXR | 不可用 |

所有不可用项保留请求并在 `GlobalIlluminationStatus`/`RenderFeatures` 说明第一层阻塞原因。

## 实施顺序

M1 → M2 → M3 → M4。M1 的运动向量是 M2 时域累积和 M4 复用的前置；M2 可作为无 DXR fallback 先独立验收；M3/M4 复用 M1/M2 的资源与历史框架。

每阶段独立构建、GPU 截图、CTest、edit self-test/native self-test，提交并更新任务记录后才进入下一阶段。
