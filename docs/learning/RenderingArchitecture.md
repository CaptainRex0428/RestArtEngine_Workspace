# 渲染架构学习笔记：RHI、Pass 图、G-Buffer 与常量打包

用途：理解 RestArtEngine 当前渲染架构与通用原理。基线：引擎 `14a6b0d`。相关讨论：[2026-11-11 会话](../conversations/2026-11-11-rhi-material-system.md)；后续方案：[材质模板系统](../design/MaterialTemplateSystem.md)。

标注约定：**已实现** = 源码存在并通过构建/测试；**未实现** = 方案或设计目标，不能当作现成能力。

## 1. 心智模型：五层

```
App / Editor          ← 用户意图、参数编辑、视口
      ↓
Renderer              ← 决定画什么、什么顺序（Pass 图）
      ↓
RHI（目标形态）        ← 设备/资源/PSO/命令/同步
      ↓
图形 API              ← D3D11 / D3D12 / Vulkan
      ↓
GPU
```

当前的真实情况（**已实现**）：

- `SceneRenderer` 直接调用 D3D11，不经过 RHI。
- `D3D12` 目录只承载 DXR 桥：DX11 光栅 + `DispatchRays`，共享纹理与 fence。
- RHI（`IRenderBackend`）只有生命周期空壳，五个后端均为占位。

## 2. 一帧的 Pass 流

声明在 [`RenderPipeline.h`](../../../include/RestArtEngine/Renderer/RenderPipeline.h)，拼装在 [`ScenePipeline.cpp`](../../../src/Renderer/Pipelines/ScenePipeline.cpp)，执行在 [`SceneRenderer::render`](../../../src/Renderer/SceneRenderer.cpp)。

| 顺序 | Pass | 触发条件 | 读取 | 写出 |
|---|---|---|---|---|
| 0 | 准备 | 每帧 | Settings/World/Assets | 光照/相机常量、目标纹理 |
| 1 | Shadow map | 光栅阴影且非 AnalyticRay/Disabled | — | ShadowMap |
| 2 | Hardware transport | DXR 可用且请求 | — | HardwareImage（+IndirectLighting） |
| 3a | GBuffer | Deferred | — | Albedo/Normal/Position/Depth |
| 3b | Deferred lighting | Deferred | G-Buffer + 阴影 + 光追 + 间接光 | SceneColor |
| 3c | Forward background | Forward | — | SceneColor |
| 3d | Forward geometry | Forward | 光照依赖 + SceneColor | SceneColor + Depth |
| 4 | Hardware resolve | DXR 成功且非 Realtime GI | HardwareImage | SceneColor |
| 5 | Depth of field | 镜头可景深且非薄透镜出图 | SceneColor + Depth | SceneColor |
| 6 | Selection mask | 编辑器有选中 | Depth | SelectionMask |
| 7 | Selection composite | 同上 | SceneColor + Depth + Mask | SceneColor |
| 8 | Frame capture | 诊断请求 | SceneColor/Depth/G-Buffer | 快照 |

要点：

- `validatePipeline` 检查名字唯一、`writes != None`、读的资源已被生产、前向/延迟分支互斥。
- 同一资源可以“先写后读”（如 Depth：GBuffer 写，Deferred/DOF/描边读）。
- Pass 图只描述数据流，不描述具体 API 调用；RHI 落地后由执行器插入 barrier。

## 3. 延迟渲染与 G-Buffer

### 问题

前向渲染每个物体、每盏灯都要算光照；遮挡部分也白算。

### 两步拆分

**GBuffer Pass**（[`Scene.hlsl`](../../../Shaders/Private/Scene.hlsl) 的 `PSGBuffer`）：

| 目标 | 内容 |
|---|---|
| Albedo | RGB 基础色，A 粗糙度 |
| Normal | RGB 世界法线，A 金属度 |
| Position | RGB 世界坐标，A 有效标记 |
| Depth | 深度（DSV 写，之后作为 SRV 读） |

这个 Pass **不做光照**。

**Deferred Pass**（`PSDeferred`）：全屏一次，逐像素：

```hlsl
float4 position = positionBuffer.Load(pixel);
if (position.w < 0.5) return Background(input.uv);   // 无几何
float4 albedo = albedoBuffer.Load(pixel);
float4 normal = normalBuffer.Load(pixel);
// 还原 Surface，加阴影/间接光，写 SceneColor
```

### 为什么便宜

- 光照次数从“物体数 × 光源数”变成“屏幕像素数 × 一次”。
- 32 盏灯对每个像素只遍历一次。
- 代价：多写 3 张 RGBA8（带宽），透明物体不友好；所以引擎同时保留 Forward 分支。

### 读写声明怎么读

```
GBuffer: writes Albedo|Normal|Position|Depth
Deferred: reads Albedo|Normal|Position|Depth, ShadowMap, IndirectLighting
          writes SceneColor
```

`writes` = 生产，`reads` = 消费；`|` = 以及。校验器保证“消费者”排在“生产者”之后。

## 4. 常量缓冲（CBuffer）

### 是什么

GPU 可见的小块只读参数（矩阵、颜色、灯光数组）。HLSL：

```hlsl
cbuffer SceneConstants : register(b0) {
    float4x4 viewProjection;
    float4 cameraPosition;
    ...
};
```

CPU 侧必须有字节一致的结构体：

```cpp
struct alignas(16) SceneConstants {
    XMFLOAT4X4 viewProjection;  // 64 B
    XMFLOAT4 cameraPosition;    // 16 B
    ...
};
static_assert(sizeof(SceneConstants) == 176);
```

上传：`UpdateSubresource(cbuffer, 0, nullptr, &data, 0, 0)`。

### 打包规则

- 16 字节对齐；矩阵 64 B；数组元素按 16 的倍数；
- 不要放 `bool`，用 `uint/float`；
- CPU/HLSL 字段顺序、类型、大小必须完全一致。

### 我们的分组（**已实现**）

| 槽 | 结构体 | 更新频率 | 大小 |
|---|---|---|---|
| b0 | SceneConstants | 每帧/视口 | 176 B |
| b1 | ObjectConstants | 每物体 | 160 B |
| b2 | RayConstants | 每帧（软件光追） | 5136 B |
| b3 | ShadowConstants | 每阴影 Pass | 160 B |
| b4 | OutlineConstants | 每描边 Pass | 32 B |
| b6 | GlobalIlluminationConstants | 每帧 | 16 B |
| b7 | LightingConstants | 每帧（32 灯） | 3104 B |
| b8 | DepthOfFieldConstants | 每 DOF Pass | 32 B |

### 反射契约

`SceneRenderer::validateShader` 用 D3D 反射检查：绑定名、类型、槽位、绑定数量、纹理维度、常量缓冲字节数、变量偏移。任何一边改布局会在管线创建时报错，避免静默错位。

## 5. PSO（管线状态对象）

PSO = 一次绘制所需的全部状态打包：

```
VS + PS + 输入布局 + 光栅状态 + 深度状态 + 混合状态 + RT 格式 + 采样数
```

- D3D11：零散设置（`RSSetState`、`OMSetDepthStencilState`、`VSSetShader`…），驱动隐式合并。
- D3D12/Vulkan：必须提前创建 PSO，切换便宜、可并行录制、创建时可校验。

我们代码里的雏形：`materialRasterizers[rasterIndex]` 按 `twoSided/mirrored` 预建光栅状态；`depthEnabled` 预先建深度状态。RHI 落地后，这些会合成 `PipelineStateDescription` 并缓存。

## 6. RHI 的职责与现状

RHI 该抽象的五类：设备/交换链、资源、管线状态、命令、同步/能力。

**当前是骨架**（[`RenderBackend.h`](../../../include/RestArtEngine/Renderer/RenderBackend.h)）：

```cpp
class IRenderBackend {
    type(); name(); capabilities();
    initialize(); shutdown(); isInitialized();
    beginFrame(); endFrame(); present();
};
```

- 没有资源创建、没有命令、没有 PSO、没有 resize/设备丢失。
- `Null/OpenGL/DX11/DX12/Vulkan` 五个子类都是同一份空壳，`hardwareAvailable=false`。
- `Engine` 会创建它，但 App 不用 `Engine`；`SceneRenderer` 直连 D3D11。
- `D3D12` 目录不是 RHI 后端，而是 DXR 桥：DX11 信号 fence → DX12 等待/dispatch → DX12 信号 → DX11 等待，CPU 同步等待（10 秒超时）。

结论：**RHI 目前对管线没有实际影响**；管线的抽象是 Pass 图与常量契约。RHI 的价值要等真正接入后才能兑现。

## 7. “并发”到底指什么

代码里没有 `std::thread`。可能的混淆来源：

| 说法 | 实际机制 |
|---|---|
| GPU 并发 | DX11 光栅与 DX12 DXR 通过共享 fence 协作，但每帧 CPU 会等待，未重叠成异步流水线 |
| 异步诊断 | GPU timestamp query 用 `GetData(...DONOTFLUSH)`，未就绪不等待 |
| 渐进 GI | 跨帧累积样本（每帧 ≤16，目标 ≤65536），不是多线程 |
| 并行任务 | 协作层的多个开发任务并行推进，不是引擎运行时并发 |

唯一的 CPU 同步原语在 `TraceProfiler`（mutex/atomic）与 `Project` 的原子序号。

## 8. 多光源打包（**已实现**）

- `maxSceneLights = 32`；`GpuLight` 96 B；`LightingConstants = 3104 B`。
- 类型编码在 `positionType.w`：Directional=0、Sky=1（聚合，不占名额）、Rect=2、Spot=3、Point=4。
- 溢出只累计 `info[3]`，不丢数据；第一盏方向光可成为光栅阴影光源（`info[2]`）。
- 矩形灯光栅路径用四点面积近似；路径追踪用面积/BRDF MIS。
- 没有 cluster/tile、GPU light culling 或并行光照。

## 9. 源码阅读路线

1. [`README.md`](../../../README.md)、[`Architecture.md`](../../../docs/Architecture.md)
2. [`RenderPipeline.h`](../../../include/RestArtEngine/Renderer/RenderPipeline.h) + [`ScenePipeline.cpp`](../../../src/Renderer/Pipelines/ScenePipeline.cpp)
3. [`SceneRenderer::render`](../../../src/Renderer/SceneRenderer.cpp)
4. [`Lighting.h`](../../../include/RestArtEngine/Renderer/Lighting.h) + [`Lighting.hlsli`](../../../Shaders/Private/Lighting.hlsli)
5. [`Scene.hlsl`](../../../Shaders/Private/Scene.hlsl)（`PSGBuffer`/`PSDeferred`）
6. [`PathTracing.hlsli`](../../../Shaders/Private/PathTracing.hlsli) + [`GlobalIllumination.h`](../../../include/RestArtEngine/Renderer/GlobalIllumination.h)
7. [`HardwareRayTracing.h`](../../../src/Renderer/D3D12/HardwareRayTracing.h)
8. [`Camera.h`](../../../include/RestArtEngine/Camera/Camera.h)
9. [`AssetFormat.md`](../../../docs/AssetFormat.md)
10. [`EditorGuide.md`](../../../docs/EditorGuide.md)

## 10. 练习

1. 在 `RenderPipelineTests` 加一个“缺生产者”的失败用例，观察校验错误。
2. 新增一个 16 B 的常量缓冲与 HLSL cbuffer，走通反射契约（名字/槽位/大小/偏移）。
3. 给 `materialRasterizers` 增加一种状态（如 wireframe），说明它会如何进入 PSO 描述。
4. 用 Diagnostics 对比 Forward/Deferred 的 Pass 时间线，记录差异。
5. 用 `--project Projects/PathTracing_CornellBox --frames 3 --capture-temp` 观察渐进 GI 的样本累积与历史重置。

## 11. 常见误区

| 误区 | 纠正 |
|---|---|
| RHI 已经接入 | 只有接口骨架；D3D11 直连 |
| RHI 只支持 D3D11 | 设计多后端；当前一个都没实现 |
| 延迟渲染没有深度写入 | GBuffer Pass 写 Depth，后续 Pass 读 |
| CBuffer 可以随便放 bool/float3 | 必须遵守 16 字节对齐，用 float4/uint |
| PSO 只在 D3D12 有 | D3D11 是隐式状态合并；概念上等价 |
| 渐进 GI 是多线程 | 是跨帧累积，历史在相机/灯光变化时重置 |

## 12. 证据边界

- 本笔记基于 `14a6b0d` 源码与 2026-11-10 的构建/CTest 记录（Debug 构建通过、CTest 22/22）。
- 未在本轮重新运行 GPU 画面验证；编辑器自测受桌面前台焦点限制，未取得通过。
- 文中“未实现”项（RHI 资源/命令、材质模板、变体、跨后端）均不是现有能力。
