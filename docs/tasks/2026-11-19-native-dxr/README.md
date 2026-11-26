# 原生 D3D12 DXR

目标：让 `D3D12 (native DXR)` 后端在不创建 D3D11 device、不经过旧 DXR bridge 的前提下执行硬件光追、实时／渐进 GI，并保持光栅回退与诊断契约。

状态：完成。实现提交 `c017ff8`、视口偏移修复 `64a7c97` 已推送 `origin/master`。最新记录：[v2](v2.md)。

基线：`79bf6d0`。用户 Sandbox 资产改动保留，不提交。
