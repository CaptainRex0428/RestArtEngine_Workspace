# 实时 GI 四项扩展

目标：实现并配置化四条实时 GI 路线——PathTracing 时域/空域降噪（相机 + 逐物体运动向量）、SSGI、DDGI、ReSTIR DI/GI。

设计见 [RealtimeGiOptions](../../design/RealtimeGiOptions.md)。当前状态：M1 完成；M2 SSGI、M3 DDGI、M4 ReSTIR 首版完成并 GPU 验证（`1768b21`、`f52eb1f`、`0d93c0a`）；`fa5667f` 修复 SSGI 自反馈散点并改进 DDGI probe 稳定性；`b97f305` 修复 DDGI atlas viewport 并加入场景自动拟合；`9237cd3` 新增 GI indirect / GI probes debug 视图。完整 DDGI（DXR 逐 probe 光线追踪 + depth/visibility）待实现，见 [m5](m5-debug-and-full-ddgi.md)。四项验收见 [acceptance](acceptance.md)。

进度记录：[m1](m1.md) · [m2](m2.md) · [m3](m3.md) · [m4](m4.md) · [acceptance](acceptance.md)。
