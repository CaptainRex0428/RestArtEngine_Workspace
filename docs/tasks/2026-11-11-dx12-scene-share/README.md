# 2026-11-11 DX12 场景共享（显示色 FXAA）

状态：通过（实验开关）
引擎基线：`c34edb8` + 本轮工作区改动
协作库基线：`main`

## 目标

把 SceneRenderer 的真实场景纹理以共享句柄交给 DX12 后处理，建立跨设备顺序，并把结果回拷到显示目标。先做最小切片：显示色 + FXAA。

## 结果摘要

- v1：`--dx12-post` 显示色共享 + DX12 FXAA，与默认路径 MAE 2e-7/255。
- v2：新增 HDR 与 Bloom 共享，Tonemap 也在 DX12 执行；画面与默认路径保持一致，validation 0。
- 修复了 DX12 共享目标缺 RTV 描述符、共享纹理必须带 KEYEDMUTEX、CopyResource 前需解绑 RTV/SRV 三个问题。
- 回归：backend smoke、TAA、Validate-Render 全部 PASS。

## 未完成

- 只共享显示色；HDR、深度、TAA 历史与 Bloom 仍未共享。
- 同步为 CPU 串行，需替换为共享 fence。
- 实验开关默认关闭；未接项目设置或默认路径。

## 证据

- `artifacts/dx12-post-final/`、`artifacts/dx12-share-regression/`
- 详见 [v1.md](v1.md)。
