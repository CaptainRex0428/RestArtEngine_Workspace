# 原生 D3D12 主后端

状态：M3 首阶段实现与验收完成；完整功能对齐仍待后续任务。用户已授权直接实现。

目标：独立设备、交换链、RHI 场景与编辑器 UI，在禁止回退时不创建 D3D11 设备；保留严格 D3D11 和 D3D11＋DXR。首阶段覆盖真实网格、材质、相机、Forward/Deferred、阴影、预览、窗口缩放与读回；其余特性须明确能力边界。

基线：引擎 `14a6b0d` 加未提交 M1/M2；M2 测试 24/24、真实 D3D11/DXR 证据见 [RHI 任务](../2026-11-18-rhi-slice/README.md)。本地 Sandbox 七项资产保持不变。

最新：[v3 最终验收](v3.md)；UI 生命周期迭代见 [v2](v2.md)，首次集成失败保留在 [v1](v1.md)。设计：[NativeD3D12Backend](../../design/NativeD3D12Backend.md)。经验：[RhiMigration](../../experience/RhiMigration.md)。

验收：Debug 无告警、CTest 25/25，原生12实际像素／UI生命周期／热编译及六案例启动矩阵通过；严格11的13张非UI图与M2逐字节一致；混合硬件光追251次dispatch、完整Editor回归通过，图形调试错误均为0。最后原生12加载→编辑器4帧截图已视觉检查，DX12标识、图片logo、真实场景和Content正常。本地Sandbox七项资产哈希保持。

剩余：原生12软件射线、DXR/GI、DOF、Outline、Inspector冻结捕获及GPU查询未移植；真实RenderDoc抓帧、GBV、设备丢失、实际设备初始化失败的回退注入及副窗口GUI像素验收未完成。首阶段同步fence实现不承诺性能提升。引擎代码尚未提交，协作记录独立提交同步。

分工：主 agent 负责 SceneRenderer、公共接口、构建与集成验收；渲染子 agent 独占 D3D12Rhi；UI 子 agent 独占 ImGuiLayer 和诊断安全处理；启动子 agent 独占后端选择、LoadingScreen、MinimalApp。所有 GPU 测试由主 agent 串行执行。
