# SSGI P0 优化规划：DXR 反射 / DDGI fallback

状态：P0 已实现（native D3D12 与 hybrid DXR 反射 + 无 DXR 时 DDGI probe fallback）。

## 已落地实现（`42cbf37`）

- `HardwareRayTracing.hlsl` 新增 `ResolveReflection`，由 `traceOptions.x > 1.5` 的 reflection-only dispatch 调用，写入共享 `indirectLightingOutput`；
- `Frame::reflectionOnly` + `traceOptions.x=2`，C++ 在 reflection-only 模式跳过 path resolve；
- native D3D12 的 HardwareTransport 将 reflection 结果复制到 `nativeIndirectCopy`，SSGI composite 以 t21 采样；
- SSGI 与 DXR 解耦：硬件反射只在 `native12` + ScreenSpace + reflections + indirectSpecular 时启用，跳过 `HardwareResolve`；
- DXR 关闭时 SSGI pipeline 增加低分辨率 `ProbeUpdate`/`ProbeFilter`，`ScreenSpaceTrace`/`ScreenSpaceSpecular` 的 miss 使用 `ProbeIrradiance`；
- hybrid DXR 的 SSGI 通过 `CopySubresourceRegion` 把 `indirectLighting()` 拷入 RHI `hardwareReflection` 目标，再绑定到 SSGI composite t21（`9150b36`）。


## 目标

1. DXR 可用且 `hardwareRayTracingReflections` 开启时，SSGI 使用硬件 ray-traced reflection；
2. DXR 不可用时，SSGI/SSR 的 off-screen miss 使用低分辨率 DDGI probe atlas fallback，而不是只采样环境。

## 当前架构阻塞

- `SceneRenderer.cpp` 中 SSGI 的启用条件包含 `!hardwareTransport`，因此 DXR 可用时 SSGI pass 根本不运行；
- `HardwareRayTracing` 当前只有 `hardwareOutput` / `indirectLighting` 两个输出，其中 `indirectLighting` 是 diffuse+specular 混合的间接结果，没有 reflection-only UAV；
- DXR GI 的 `PathRadiance` 在 primary surface 上按 lobe 分类，但没有把 specular 单独导出到资源；
- DDGI 与 SSGI 通过 `GlobalIlluminationMethod` 互斥，SSGI 运行时没有 probe atlas 可用于 off-screen fallback。

这些不是 shader 内的小修补，需要改 pipeline/resource/descriptor contract，因此先记录设计，避免直接塞进当前 SSGI pass 造成资源契约错误。

## 实现步骤

### P0.1 DXR reflection-only 输出

- `HardwareRayTracing.hlsl` 增加 `RWTexture2D<float4> reflectionOutput` UAV；
- 在 `PathRadiance` / realtime resolve 中把 primary surface 的 specular lobe 单独累计，写入 reflectionOutput；
- C++ `HardwareRayTracing` 暴露 `nativeReflection()` / `reflection()` SRV 和尺寸；
- 增加 reflection output 的 history / 重置规则（epoch、view、材质变化）。

### P0.2 SSGI 与 DXR 解耦

- 把 `screenSpaceGi` 的 `!hardwareTransport` 门控改为“SSGI 可用，但 DXR 输出不覆盖 SceneColor”；
- 当 SSGI 使用 DXR reflection 时，移除/跳过 `HardwareResolve` 对 SceneColor 的覆盖；
- 在 `PipelineBuildInputs` 增加 `hardwareReflectionGi`，pipeline 增加 reflection 输入资源；
- SSGI specular composite 在 DXR 开启时采样 reflection 纹理，关闭 SSR pass；否则使用现有 SSR pass。

### P0.3 DDGI probe fallback（DXR 关闭）

- SSGI 场景允许一个低分辨率 probe update / 独立 probe atlas，或者把 probe update 作为 SSGI 的辅助 pass；
- SSGI trace / SSR miss 时按 depth/normal 采样 probe atlas，与 Environment fallback 按权重混合；
- 需限制 probe 更新频率（例如每 2–4 帧）避免 SSGI 成本翻倍；
- probe fallback 只补低频能量，不替代屏幕空间接触反射。

### P0.4 验证

- DXR on：SSGI specular 来自 reflection-only 纹理，关闭 SSR pass，validation 0；
- DXR off：SSGI miss 使用 probe fallback，validation 0；
- DXR on/off 切换、reflection 开关、SSGI 开关、resize；
- CTest 30/30，native/hybrid self-test。

## 当前已完成

- SSGI v2：linear direct source、visibility march、per-object motion、half-res、off-screen environment fallback、multi-bounce、SSR indirect specular。
- 相关提交：`34b5e67`、`e672b08`、`cdbd3ea`、`e554fe3`、`a3fe3d1`。
