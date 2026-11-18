# 主后端启动选择 M1

状态：M1 启动选择切片实现并通过本轮验证；最新版本 [v3](v3.md)。过程：[v1](v1.md) 启动／兼容、[v2](v2.md) 标签布局、[v3](v3.md) 正式混合模式。引擎源码未提交。

用户在确认独立 D3D12 主后端与可选 D3D11 回退后授权“先做着试试”。本轮执行 [方案](../../design/NativeD3D12Backend.md) 的第一阶段，不宣称原生 D3D12 或实际资源／命令 RHI 已实现。

文件分工：主协调负责 BackendSelection、App、UI、能力归因、构建与日志；配置 worker 负责 Project.h/.cpp 与 ProjectSettingsTests；渲染专项负责 SceneRenderer.h/.cpp，并对完整 diff 做只读审查。所有构建／GPU验证由主协调串行执行。既有 Sandbox 用户资产保持不变。

用户进一步确认：严格D3D11、D3D11+D3D12/DXR混合、原生D3D12是三种正式可选模式；混合模式规范key为d3d11Dxr。后端选择与RT/GI请求独立，保存后端设置下次启动生效。

结果：Debug、CTest23/23、五案例真实启动矩阵与13张光栅图一致性通过；混合硬件完整217dispatch/errors0、最终新入口3次DXR/errors0；最终严格11控件操作、保存重载与截图通过（DXR按预期跳过，dispatch0）。Sandbox七个文件哈希不变。公开说明：[RenderBackends.md](../../../../docs/RenderBackends.md)，经验：[BackendSelection.md](../../experience/BackendSelection.md)。

下一步：D3D11 实际 RHI／资源声明纵向切片。当前真实设备仍由SceneRenderer拥有，Core占位后端未接入；未实现原生12的设备／资源创建失败回退、运行中切后端或设备丢失恢复。首版验证覆盖“原生12实现缺失”的明确拒绝／回退，不外推其他失败类别。
