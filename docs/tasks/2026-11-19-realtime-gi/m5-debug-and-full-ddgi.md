# M5：GI Debug 可视化与完整 DDGI

状态：完成。Debug 可视�?`9237cd3`；完�?DDGI 已在 DXR 后端实现（�?probe 光线追踪 + irradiance/depth atlas + hysteresis + Chebyshev visibility），strict D3D11 保留屏幕空间 fallback�?
## 已实现：GI debug view

编辑�?viewport debug combo 新增�?
- `debugView = 11` �?**GI indirect**�?  - SSGI：照常执�?trace/composite，composite 只输�?indirect�?  - DDGI：输�?`ProbeIrradiance × receiver albedo`�?  - Path tracing realtime：输�?`indirectLightingBuffer` 并应用当前曝光；
  - GI 关闭/背景：黑色�?- `debugView = 12` �?**GI probes**�?  - 正常场景叠加每个 DDGI probe�?  - probe 位置�?`PSProbeUpdate` 一致（`origin + (ix,iy,iz)+0.5`）；
  - 每个 probe �?atlas 辐照度着色（RGB × 2，深色表示低辐照度）�?  - 新增 `VSProbeDebug` / `PSProbeDebug`，一�?RHI draw 绘制所�?billboard sphere�?  - 新增 `RenderPassKind::GiDebugOverlay`，在 post/AA 之后�?SceneColor，读 SceneDepth �?probe atlas�?  - 1024×32 atlas viewport，probe 顶点缓冲每帧按当前网格生成�?
无编辑器时可�?
```text
RestArtEngine.exe --project <p> --backend d3d12 --frames 8 --debug-view 12 --capture-temp
```

已用 native D3D12 �?strict D3D11 �?6�? 帧验证，validation 0；截图：

- `gi-probe-debug.png`（probe 球体�?- `gi-indirect-debug-ddgi.png`（DDGI indirect，当前偏暗）

## 当前 DDGI 为什么不正确

用户截图里的白色/条状亮斑来自当前 `PSProbeUpdate` 的投影式更新�?
1. 每个 probe 只投影到屏幕，读取该像素附近 3×3 direct color�?2. 这不是从 probe 位置出发的入射辐照度，probe 会把某一像素的高�?亮面复制到整�?probe 单元�?3. 没有 probe 深度/可见性，三线性采样会把亮 probe 扩散到相邻区域；
4. 屏幕�?被遮�?probe 保留旧值，形成条纹/白斑�?5. atlas 内容�?probe 实际周围几何无关，因此“加不加 DDGI 区别很小/不对”都是这个近似的必然结果�?
结论�?*必须替换 probe 更新为�?probe 光线追踪**，而不是继续在屏幕空间投影上打补丁�?
## 完整 DDGI（已实现，DXR 后端�?
### Probe 存储

- irradiance atlas：RGBA16F 1024×32，RGB = irradiance，A = confidence�?- depth atlas：RGBA16F 1024×32，`x = mean hit distance`，`y = mean squared hit distance`，`z = hit ratio`�?- history atlas：私�?RGBA16F 1024×32，用�?hysteresis�?- 映射保持 `x = ix + iz*X, y = iy`，probe 世界位置 `origin + (ix,iy,iz)+0.5` × spacing�?
### DXR probe update

- `HardwareRayTracing` �?`CSMain` 增加 probe pass（`probeParameters.w > 0.5`）；
- 每个 atlas 像素 = 一�?probe，按 `probeRayCount`�?�?2，默�?16）发射球�?Fibonacci 方向�?- 命中：`TriangleMaterialAt` + `PathDirectLight` + `PathAreaDirect` 求入�?radiance，未命中：`Environment`�?- 累加 irradiance �?depth moments�?- history 有效时按 `probeHysteresis` 与上一帧混合；
- dispatch �?`CopyResource` 当前 irradiance atlas �?history，view/epoch 变化时重�?history�?
### 绑定与资�?
- DXR root signature 增加 `b9 ProbeConstants`、`u10` irradiance UAV、`u11` depth UAV、`t16 probeAtlasPrevious`�?- descriptor heap 扩到 18�?- native：模块输�?D3D12 atlas，renderer `importTexture` + copy �?RHI `probeAtlasA`/`probeDepthAtlasImage`�?- hybrid：shared atlas �?DX11 �?`CopyResource` �?RHI�?- strict D3D11：没�?DXR，继续运行屏幕空�?`ProbeUpdate` fallback�?
### 采样

- 8 probe 三线性；
- hardware 路径�?`probeParameters.w == 2` 选择 depth atlas：Chebyshev visibility + hit ratio 软权重（`0.35 + 0.65*visibility*ratio`），避免硬拒绝造成棋盘�?- receiver albedo 调制；raster fallback 仍用 atlas alpha confidence�?
### 配置

`probeRayCount` 进入 `GlobalIlluminationSettings`、JSON、Project Settings slider、有效性校验和测试；`probeAutoFit`/`probeSpacing`/`probeHysteresis` 继续生效�?
## 验证

- native D3D12 DXR DDGI�? �?exit 0，validation 0，DXR dispatches 10�?- hybrid D3D11+DXR DDGI�? �?exit 0，validation 0�?- strict D3D11 screen-space fallback�? �?exit 0，validation 0�?- CTest 30/30；native/hybrid self-test exit 0�?- native DDGI on/off meanAbsRGB �?4.03（GTX/RTX 测试场景，间接贡献较柔和；debug 11 可放大查看）�?- 截图 `ddgi-raytraced-native.png`、`ddgi-raytraced-hybrid.png`、`ddgi-raytraced-probes.png`、`ddgi-raytraced-indirect.png`�?
局限：probe 光线为固定球面方向且每帧重算，仍�?Monte Carlo 噪声；未�?probe relocation；DXR 路径要求硬件光追，strict D3D11 仍是屏幕空间 fallback�?
## 参考提�?
- `f52eb1f` 首版 DDGI�?- `fa5667f` probe 稳定性；
- `b97f305` auto-fit + atlas viewport 修复�?- `9237cd3` GI debug views�?- 本次完整 DDGI 提交（见 engine HEAD/记录）�?