# M5：GI Debug 可视化与完整 DDGI

状态：完成。Debug 可视化 `9237cd3`；完整 DDGI 已在 DXR 后端实现（逐 probe 光线追踪 + irradiance/depth atlas + hysteresis + Chebyshev visibility），strict D3D11 保留屏幕空间 fallback；完整 DDGI 提交 `f94b313`。

## 已实现：GI debug view

编辑器 viewport debug combo 新增：

- `debugView = 11` — **GI indirect**：
  - SSGI：照常执行 trace/composite，composite 只输出 indirect；
  - DDGI：输出 `ProbeIrradiance × receiver albedo`；
  - Path tracing realtime：输出 `indirectLightingBuffer` 并应用当前曝光；
  - GI 关闭/背景：黑色。
- `debugView = 12` — **GI probes**：
  - 正常场景叠加每个 DDGI probe；
  - probe 位置与 `PSProbeUpdate` 一致（`origin + (ix,iy,iz)+0.5`）；
  - 每个 probe 用 atlas 辐照度着色，青色表示 atlas alpha 无效；
  - 新增 `VSProbeDebug` / `PSProbeDebug`，一次 RHI draw 绘制所有 billboard sphere；
  - 新增 `RenderPassKind::GiDebugOverlay`，在 post/AA 之后写 SceneColor，读 SceneDepth 与 probe atlas；
  - 1024×32 atlas viewport，probe 顶点缓冲每帧按当前网格生成。

无编辑器时可：

```text
RestArtEngine.exe --project <p> --backend d3d12 --frames 8 --debug-view 12 --capture-temp
```

已用 native D3D12 与 strict D3D11 各 6–8 帧验证，validation 0；截图：

- `gi-probe-debug.png`（probe 球体）
- `gi-indirect-debug-ddgi.png`（DDGI indirect，当前偏暗）

## 当前 DDGI 为什么不正确

用户截图里的白色/条状亮斑来自当前 `PSProbeUpdate` 的投影式更新：

1. 每个 probe 只投影到屏幕，读取该像素附近 3×3 direct color；
2. 这不是从 probe 位置出发的入射辐照度，probe 会把某一像素的高光/亮面复制到整个 probe 单元；
3. 没有 probe 深度/可见性，三线性采样会把亮 probe 扩散到相邻区域；
4. 屏幕外/被遮挡 probe 保留旧值，形成条纹/白斑；
5. atlas 内容与 probe 实际周围几何无关，因此“加不加 DDGI 区别很小/不对”都是这个近似的必然结果。

结论：**必须替换 probe 更新为逐 probe 光线追踪**，而不是继续在屏幕空间投影上打补丁。

## 完整 DDGI 实现方案（已完成）

目标：DXR 后端（native D3D12 / hybrid D3D11+DXR）逐 probe 追踪，strict D3D11 保留屏幕空间 fallback。

1. **Probe 存储**
   - 辐照度 atlas：RGBA16F，1024×32，RGB = irradiance，A = confidence；
   - 深度/可见性 atlas（第二阶段）：RGBA16F 或 R16G16，存 mean distance / mean squared distance，用于 Chebyshev visibility；
   - 2D atlas 映射保持 `x = ix + iz*X, y = iy`。

2. **DXR probe update**
   - 每个 probe dispatch 一组线程，发射 16–32 条余弦/球面方向光线；
   - 命中三角形后用现有 `TriangleMaterialAt` + 直接光/环境光近似得到入射 radiance；
   - 未命中采样环境/天空；
   - 累加平均写入 irradiance atlas；
   - 使用 hysteresis 与上一帧混合。

3. **Renderer 集成**
   - DDGI 参数（grid dims、origin、spacing、hysteresis）加入 `HardwareRayTracing::Frame` / probe constants；
   - `HardwareRayTracing` 增加 probe atlas 输出资源/native/shared 访问器；
   - native：`D3D12Rhi::importTexture` 包装并绑定；
   - hybrid：打开 shared texture，D3D11 side 绑定 SRV 或 copy 到现有 probeAtlasA；
   - raster Deferred 的 `ProbeIrradiance` 不变，只换成 ray-traced atlas；
   - strict D3D11 保留当前屏幕空间更新，状态区明确标记 “fallback”。

4. **采样**
   - 8 probe 三线性；
   - 第二阶段加 probe depth/visibility Chebyshev 权重；
   - receiver albedo 调制，避免把 probe radiance 直接当光照。

5. **验证**
   - native/hybrid DDGI 各 8–16 帧，validation 0；
   - Cornell Box / 用户 Sandbox 对比 GI off/on，确认颜色溢出无白斑/条纹；
   - probe debug view 中球体颜色应随周围几何变化，cyan 数量显著减少。

## 实现结果（f94b313）

- `HardwareRayTracing` 增加 probe pass：`b9 ProbeConstants`、`u10` irradiance atlas、`u11` depth atlas、`t16` history atlas；descriptor heap 扩到 18。
- 每个 atlas 像素一个 probe，按 `probeRayCount`（1–32，默认 16）发射球面 Fibonacci 光线；命中用 `TriangleMaterialAt` + `PathDirectLight` + `PathAreaDirect`，未命中用 `Environment`。
- 输出 irradiance RGBA16F + depth moments（mean distance / mean squared distance / hit ratio）；history 按 `probeHysteresis` 混合，view/epoch 变化时重置。
- Renderer：native `importTexture` + `copyTextureRegion`，hybrid shared texture `CopyResource`；Deferred 采样 8 probe，hardware 路径用 Chebyshev visibility 软权重（0.35 + 0.65×visibility×hitRatio），strict D3D11 保留屏幕空间 `ProbeUpdate` fallback。
- `probeRayCount` 已加入 JSON、UI slider、校验和 CTest。
- 验证：native DXR DDGI 8 帧 exit 0/validation 0/DXR dispatches 10；hybrid 8 帧 exit 0/validation 0；strict D3D11 6 帧 exit 0/validation 0；CTest 30/30；native/hybrid self-test exit 0；native on/off meanAbsRGB≈4.03。
- 截图：`ddgi-raytraced-native.png`、`ddgi-raytraced-hybrid.png`、`ddgi-raytraced-probes.png`、`ddgi-raytraced-indirect.png`。
- 余留限制：固定球面方向造成 Monte Carlo 噪声；未做 probe relocation；strict D3D11 仍是屏幕空间 fallback。

## 参考提交

- `f52eb1f` 首版 DDGI；
- `fa5667f` probe 稳定性；
- `b97f305` auto-fit + atlas viewport 修复；
- `9237cd3` GI debug views；
- `f94b313` 完整 DXR DDGI。
