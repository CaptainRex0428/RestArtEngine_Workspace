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
- v5：异步提交先试后回退，定位到描述符/常量未版本化（静默错误）。
- v6：按 v5 的分析落地有界异步（独立 SRV 堆、常量 4 槽 ring、8 个在飞），MAE 回到 2e-7 / 8.4e-5。
- v7：接入工程设置 `rendering.dx12Post` 与 Project Settings 复选框，CLI 可单次覆盖。
- 修复了 DX12 共享目标缺 RTV 描述符、共享纹理必须带 KEYEDMUTEX、CopyResource 前需解绑 RTV/SRV 三个问题。
- 回归：backend smoke、TAA、Validate-Render 全部 PASS。

## 未完成

- 每帧共享纹理拷贝仍在，多一次全屏开销；异步只是去掉 CPU 停顿，本场景帧率无可测提升。
- 实验开关默认关闭；未接项目设置或默认路径。
- 直接共享场景原资源（避免拷贝）尚未实现。

## 证据

- `artifacts/dx12-post-final/`、`artifacts/dx12-share-regression/`、`artifacts/dx12-hdr/`、`artifacts/dx12-fence/`、`artifacts/dx12-taa/`、`artifacts/dx12-motion/`、`artifacts/dx12-dof/`、`artifacts/async-rhi/`、`artifacts/async-revert/`、`artifacts/async-v3/`
- 详见 [v1.md](v1.md)、[v2.md](v2.md)、[v3.md](v3.md)、[v4.md](v4.md)、[v5-async-analysis.md](v5-async-analysis.md)。
