# 原生 D3D12 DXR 与资源状态边界

场景：把已存在的 D3D11/D3D12 DXR 共享 bridge 改造成原生 D3D12 后端可用的 transport，要求不创建 D3D11 device、不共用 D3D11 纹理，并支持硬件预览、渐进/实时 GI。

## 复用与隔离

- 复用 `HardwareRayTracing` 的 DXR 场景构建、材质上传、RTPSO/SBT/命令列表和 GI 采样；用 `native` 布尔隔离旧的 DX11 device、shared texture、shared fence、`context11->Wait` 分支。native 模式只 QueryInterface 光栅的 `ID3D12Device5`，队列直接用光栅 queue。
- native 输出是普通 UAV 图像；不要 `CreateSharedHandle`。输出提交后状态置 `COPY_SOURCE`，间接光置 `PIXEL_SHADER_RESOURCE`，由 RHI 导入消费。
- RHI 包装外部资源时只创建 SRV，不创建 RTV；UAV-only DXR 图像没有 render-target flag，误建 RTV 会失败或触发验证。

## 最容易踩的状态坑

- RHI 的 `sampledTextures_` 是 weak list，`prepareUi` 会把其中所有纹理 transition 到 `PIXEL_SHADER_RESOURCE | NON_PIXEL_SHADER_RESOURCE`。如果 DXR 间接光被以 `sampled=true` 导入，下一帧 DXR 的 `StateBefore=PIXEL_SHADER_RESOURCE` 就不匹配（0x80 vs 0xC0）。修复方式：只把 DXR 资源当 copy source（`sampled=false`），或复制到 RHI 自有纹理后再采样。
- 推荐后者：DXR 间接光每帧复制到 RHI `RGBA16F` 纹理，光照采样 RHI 纹理。两套状态机解耦，也避免 UI/预览路径偷改 DXR 状态。
- 硬件图像 resolve 直接 `copyTextureRegion` 到场景色/AA 源；copy source 状态跟随 DXR 留下的 `COPY_SOURCE`，复制后恢复原状态。
- 队列顺序：DXR 命令列表在光栅列表之前 `ExecuteCommandLists`，所以同一 queue 保证“DXR 写 → 光栅读”；不要假设 CPU 提交顺序等于光栅 Pass 顺序。每帧 DXR 完成 fence 仍需上一帧等待，避免 allocator/upload 复用。

## 编辑器视口偏移

- native DXR 硬件 resolve 必须复制到 `settings.viewportX/Y`，不能假设 `(0,0)`。编辑器 scene target 是整窗大小，Scene Viewport 只是子矩形；D3D11 旧路径一直用 `CopySubresourceRegion` 的目标偏移，native 移植时漏掉会产生右侧未覆盖竖带/错位。
- 回归方法：同一 target 分别渲染 `(0,0,200,140)` 与 `(64,48,200,140)`，比较 origin 与 offset 区域。AA 关闭要求逐像素一致；FXAA 因边界邻域允许少量误差（实测 2 像素），但阈值远小于错位时的上万像素。
- 给 RHI 增加带目标偏移的 `copyTextureRegionTo`，旧 `copyTextureRegion` 委托 `(0,0)` 保持兼容；不要用修改旧函数语义的方式修，避免 frame capture 等调用方受影响。

## 验证

- 用 D3D12 debug layer 的 validation errors 作为硬门槛；`--native-d3d12-self-test` 增加 HardwareTransport/Realtime GI 断言与 BMP。
- 同时跑混合 `--hardware-rt-self-test --backend d3d11Dxr`，确认旧共享 bridge 未被 native 分支破坏。
- 跑严格 D3D11、editor self-test、AA self-test，确认只改 native/feature policy 时其它后端无回归。
- 隔离临时工程做 Realtime/Progressive GI probe；不要把带用户资产的工程直接改坏。

## 边界

DXR 仍整幅替换硬件预览（不是 inline 混合）；没有 DispatchRays/SBT、运动重投影、透明/蒙皮、异步多帧；DOF/Outline/解析光追 native 未迁移。DXR 不可用时保留光栅并报告原因。

来源：[原生 DXR 任务 v1](../tasks/2026-11-19-native-dxr/v1.md)、[v2 视口偏移修复](../tasks/2026-11-19-native-dxr/v2.md)；提交 `c017ff8`、`64a7c97`。
