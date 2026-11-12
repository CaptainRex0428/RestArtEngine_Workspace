# 2026-11-11 DX12 场景共享（显示色 FXAA）

状态：通过（实验开关）
引擎基线：`c34edb8` + 本轮工作区改动
协作库基线：`main`

## 目标

把 SceneRenderer 的真实场景纹理以共享句柄交给 DX12 后处理，建立跨设备顺序，并把结果回拷到显示目标。先做最小切片：显示色 + FXAA。

## 结果摘要

- v1：`--dx12-post` 显示色共享 + DX12 FXAA，与默认路径 MAE 2e-7/255。
- v2：新增 HDR 与 Bloom 共享，Tonemap 也在 DX12 执行；画面与默认路径保持一致，validation 0。
- v3：共享深度与 TAA 历史，TAA 也在 DX12 执行；同步换成共享 fence，TAA 与 DX11 RHI 路径 MAE 8e-5。
- v4：运动模糊与景深迁到 DX12（新增共享 HDR 输出），全链路只有 1 级量化差；新增 `--dof` 调试开关。
- 修复了 DX12 共享目标缺 RTV 描述符、共享纹理必须带 KEYEDMUTEX、CopyResource 前需解绑 RTV/SRV 三个问题。
- 回归：backend smoke、TAA、Validate-Render 全部 PASS。

## 未完成

- 异步提交需要 descriptor/constants 多版本；直接去掉 `waitForGpu` 会导致静默画面错误（见 v5）。
- 共享输入与历史采用每帧拷贝，多一次全屏开销；DX12 RHI 绘制仍同步，提交是串行的。
- 实验开关默认关闭；未接项目设置或默认路径。

## 证据

- `artifacts/dx12-post-final/`、`artifacts/dx12-share-regression/`、`artifacts/dx12-hdr/`、`artifacts/dx12-fence/`、`artifacts/dx12-taa/`、`artifacts/dx12-motion/`、`artifacts/dx12-dof/`、`artifacts/async-rhi/`、`artifacts/async-revert/`
- 详见 [v1.md](v1.md)、[v2.md](v2.md)、[v3.md](v3.md)、[v4.md](v4.md)、[v5-async-analysis.md](v5-async-analysis.md)。
