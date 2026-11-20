# 四项实时 GI 验收记录（round 10 + SSGI/DDGI 质量修复）

日期：2026-11-20
引擎提交：`f94b313`；M1 `ba44bad`/`23bab37`/`1a3dc57`，M2 `1768b21` + `fa5667f`，M3 `f52eb1f` + `fa5667f` + `b97f305` + `f94b313`，M4 `9dd0639`/`e7defe8`/`e1591f1`/`0d93c0a`。

## 配置/文档

- `GlobalIlluminationMethod`: Disabled／PathTracing／ScreenSpace／ProbeGrid。
- Path tracing 配置：mode、denoiser、motionVectors、denoiseIterations、sampling、restirCandidates、restirDirect、restirIndirect、restirSpatialReuse。
- SSGI：screenSpaceSteps/Radius/Thickness。
- DDGI：probeGridX/Y/Z、probeSpacing、probeHysteresis、probeAutoFit、probeRayCount。
- JSON 读写/校验与 Project Settings 控件均已覆盖；非法值拒绝且保留原 manifest。
- ProjectSettingsTests 1141+ checks、RenderPipelineTests 154+ checks、CTest 30/30。

## GPU 验收（本次 round 10 实跑）

| 模式 | 后端 | 帧数 | 结果 | 状态证据 |
| --- | --- | --- | --- | --- |
| Path tracing + M1 denoise/motion | native D3D12 / hybrid DXR | 由 self-test 覆盖 | exit 0 | native/hybrid self-test 通过 |
| SSGI（新 trace/composite） | native D3D12 | 8 | exit 0，validation 0 | `GI effective: screenSpace` |
| SSGI（新 trace/composite） | strict D3D11 | 8 | exit 0，validation 0 | `GI effective: screenSpace` |
| DDGI（格点对齐/置信度） | native D3D12 | 8 | exit 0，validation 0 | `GI effective: probeGrid` |
| DDGI（格点对齐/置信度） | strict D3D11 | 8 | exit 0，validation 0 | `GI effective: probeGrid` |
| DDGI 完整 DXR（16 rays/probe，irradiance+depth） | native D3D12 | 8 | exit 0，validation 0 | `Ray-traced DDGI`、DXR dispatches 10 |
| DDGI 完整 DXR（16 rays/probe，irradiance+depth） | hybrid D3D11+DXR | 8 | exit 0，validation 0 | `Ray-traced DDGI`、DXR dispatches 10 |
| DDGI screen-space fallback | strict D3D11 | 6 | exit 0，validation 0 | `Realtime DDGI`、DXR dispatches 0 |
| ReSTIR | native D3D12 | 8 | exit 0，validation 0 | `Sampling: ReSTIR (direct on, indirect on, candidates 4)` |
| ReSTIR | hybrid D3D11+DXR | 8 | exit 0，validation 0 | 同上 |

回归：`--native-d3d12-self-test` exit 0；`--hardware-rt-self-test --backend d3d11Dxr` exit 0；CTest 30/30。

截图证据位于本目录：`ssgi-fixed-trace-composite.png`、`ddgi-stabilized-probes.png`、`ddgi-raytraced-native.png`、`ddgi-raytraced-hybrid.png`、`ddgi-raytraced-probes.png`、`ddgi-raytraced-indirect.png`、`restir-native-d3d12.png`、`restir-temporal-reservoir.png`、`restir-direct-reservoir.png`；首版对照仍保留 `ssgi-native-d3d12.png`、`ssgi-strict-d3d11.png`、`ddgi-native-d3d12.png`、`ddgi-strict-d3d11.png`。

## 已知限制（实现首版边界）

- SSGI/DDGI 仅 Deferred + 编辑器/离屏场景目标；runtime swapchain 未启用；SSGI 在 display-space 合成。DDGI 的 DXR 路径为逐 probe 光线追踪，strict D3D11 仍是屏幕空间可见性 fallback。
- DDGI/RESTIR 均不是逐 probe/逐样本无偏实现；ReSTIR 直接光乘灯数校正、indirect 亮度选择有偏。
- 没有 Uniform vs ReSTIR 的闪烁/拖影量化指标，只有 validation/status/截图证据。
- 这些限制已在 `docs/GlobalIllumination.md`、`docs/HardwareRayTracing.md`、`docs/EditorGuide.md` 及任务 m2/m3/m4 中记录。

## 结论

四项路径均已实现为可配置、可切换、可 GPU 运行并通过 D3D validation 的首版；但不是四项的生产级最终质量验收。
