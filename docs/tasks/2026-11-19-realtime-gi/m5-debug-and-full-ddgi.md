# M5：GI Debug 可视化与完整 DDGI

状态：完成。Debug 可视化 `9237cd3`；完整 DDGI 已在 DXR 后端实现，无 DXR 时运行软件光线追踪 fallback；probe debug 使用引擎内置 Sphere 模型的 instanced 真实球体；`eef5db0` 起 probe atlas 改为 SH 入射 radiance，`587b921` 起 `probeShOrder` 可配置为 SH-L1（4 texels/probe）或 SH-L2（9 texels/probe），接收端按法线做 clamped-cosine 辐照度积分，软件路径使用 `ProbeLinearSource` 提供线性 direct radiance。相关提交 `f94b313`、`26aaf1f`、`2df9527`、`d311996`、`0addad7`、`333c936`、`eef5db0`、`587b921`。probe grid/spacing/auto-fit 变化会清空 raster probe atlas 和 debug instance cache，并 bump GI epoch 重置 DXR probe history。

## 已实现：GI debug view

编辑器 viewport debug combo 新增：

- `debugView = 11` — **GI indirect**：
  - SSGI：照常执行 trace/composite，composite 只输出 indirect；
  - DDGI：输出 `ProbeIrradiance × receiver albedo`；
  - Path tracing realtime：输出 `indirectLightingBuffer` 并应用当前曝光；
  - GI 关闭/背景：黑色。
- `debugView = 12` — **GI probes**：
  - 正常场景叠加每个 DDGI probe，并保留 DDGI 间接光贡献（`2e6fb59` 起）；
  - probe 位置与 `PSProbeUpdate` 一致（`origin + (ix,iy,iz)+0.5`）；
  - 每个 probe 用**引擎内置 Sphere 模型的真实球体**标记（debug LOD 采样为 425 顶点/2160 索引），instanced 绘制，按 probeSpacing 缩放；
  - 球体带 NORMAL 输入，用 sceneLights + 固定 key light 做方向性着色，再用 atlas 辐照度染色，可以看到 probe 的位置、受光面和明暗走向；
  - `VSProbeDebug` / `PSProbeDebug` 使用 indexed instanced draw；RHI 增加 per-instance vertex attribute 与 `drawIndexedInstanced`；
  - 新增 `RenderPassKind::GiDebugOverlay`，在 post/AA 之后写 SceneColor，读 SceneDepth 与 probe atlas；
  - 1024×32 atlas viewport；sphere mesh 静态缓存，probe instance buffer 按 grid/origin 缓存。
  - probe grid/spacing/auto-fit 改变时 `probeLayoutChanged` 清空 `probeAtlasValid`、debug sphere instance cache 并递增 `giHistoryEpoch`，避免旧 atlas 映射块状残留。

无编辑器时可：

```text
RestArtEngine.exe --project <p> --backend d3d12 --frames 8 --debug-view 12 --capture-temp
```

已用 native D3D12 与 strict D3D11 各 6–8 帧验证，validation 0；截图：

- `ddgi-probe-spheres.png`（引擎内置 Sphere 模型的 instanced 真实球体，方向性着色）
- `gi-indirect-debug-ddgi.png`（DDGI indirect）

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
   - probe debug view 中真实球体的明暗方向与辐照度颜色应随周围几何/光源变化。

## 实现结果（f94b313）

- `HardwareRayTracing` 增加 probe pass：`b9 ProbeConstants`、`u10` irradiance atlas、`u11` depth atlas、`t16` history atlas；descriptor heap 扩到 18。
- 每个 atlas 像素一个 probe，按 `probeRayCount`（1–32，默认 16）发射球面 Fibonacci 光线；命中用 `TriangleMaterialAt` + `PathDirectLight` + `PathAreaDirect`，未命中用 `Environment`。
- 输出 SH 入射 radiance（9216×32 RGBA16F，按 `probeShOrder` 每 probe 4/9 texels，c0 alpha 为 confidence）+ depth moments（mean distance / mean squared distance / hit ratio）；history 按 `probeHysteresis` 混合，view/epoch/order 变化时重置。
- 两个后端共用 `DDGI composite`：先由 `DDGI probe filter` 对 SH 系数做 3×3×3 probe 邻域 Gaussian 平滑，再由接收端采样 8 个相邻 probe，对当前 `probeShOrder`（L1 4 系数 / L2 9 系数）做三线性插值，按法线计算 clamped-cosine 辐照度 `E(N)`，diffuse=`albedo/π·E`；hardware 用 Chebyshev visibility。软件 fallback：`ProbeLinearSource` 从 G-buffer 重算线性 direct radiance（含 shadow/environment），`DDGI probe update` 每 probe 64 条带 per-probe 旋转球面方向、最多 24 步屏幕空间 march，按同一 SH order 投影并写 4/9 texels；两个后端共用 `DDGI composite` 在线性空间合成后一次 `DisplayColor`，`BoundProbeIndirect` 只作饱和色安全上限；composite 写入 `rasterDestinationImage`，AA 开启时也进入 AA resolve。状态显示 `Software ray-traced DDGI (SH-L1/L2)` / `Ray-traced DDGI (SH-L1/L2)`（`77046e6` probe filter）。
- `probeRayCount` 已加入 JSON、UI slider、校验和 CTest。
- SSGI 修复：trace 改用当前帧 direct-lit colour 副本；composite 绑定 albedo；`GI indirect` 保留 direct 输出供 trace；厚度增加 `0.5 * radius` 下限，避免小 thickness 拒绝全部样本；去掉错误的法线相似度拒绝。SSGI 参数或 GI epoch 变化时丢弃 temporal history，composite 当前帧权重 25%，`GI indirect` debug 不做 temporal 混合（`2fff0f3`）。
- SSGI v2（`34b5e67`、`e672b08`、`cdbd3ea`）：trace 改从共享 `ProbeLinearSource` 采样**线性 direct radiance**；每像素 4 条 cosine-weighted 方向，半分辨率目标，前向 screen-space depth march，front-face/thickness 校验，screen edge/无命中用环境 fallback；composite 在线性空间合成一次 `DisplayColor`；新增 per-object previous-world-position G-buffer（`motionBuffer` t16）用于历史重投影，并叠加一帧 previous indirect 作为第二次反弹。限制仍在：屏幕空间可见性、只有额外一次反弹、没有间接镜面。
- 验证：native DXR DDGI 8 帧 exit 0/validation 0；hybrid 8 帧 exit 0；软件 DDGI fallback 在 native D3D12 raster 与 strict D3D11 各 6–8 帧 exit 0/validation 0；SSGI v2（linear source、visibility march、half-res、motion G-buffer、multi-bounce）在 native D3D12 与 strict D3D11 各 6–8 帧 exit 0/validation 0；CTest 30/30；native self-test exit 0。
- 截图：`ddgi-sh-l1-software-lit.png`、`ddgi-sh-l1-software-indirect.png`、`ddgi-sh-l1-hardware-lit.png`、`ddgi-sh-l2-software-lit.png`、`ddgi-probe-spheres.png`、`ddgi-software-cornell-lit.png`、`ddgi-software-cornell-indirect.png`、`ddgi-software-cornell-probes.png`、`ssgi-cornell-indirect.png`。
- 余留限制：SH 是带限近似，L1 只保留一阶方向项，L2 增加方向细节但不等于完整 radiance；固定方向造成 Monte Carlo 噪声；未做 probe relocation；软件 fallback 仍依赖屏幕可见表面且没有硬件 depth/visibility atlas。

## 参考提交

- `f52eb1f` 首版 DDGI；
- `fa5667f` probe 稳定性；
- `b97f305` auto-fit + atlas viewport 修复；
- `9237cd3` GI debug views；
- `f94b313` 完整 DXR DDGI。
