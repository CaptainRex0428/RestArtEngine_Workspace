# 实时 GI 四项扩展

目标：实现并配置化四条实时 GI 路线——PathTracing 时域/空域降噪（相机 + 逐物体运动向量）、SSGI、DDGI、ReSTIR DI/GI。

设计见 [RealtimeGiOptions](../../design/RealtimeGiOptions.md)。当前状态：M1 完成；M2 SSGI 首版完成（`1768b21`）；M3 DDGI 首版完成（`f52eb1f`）；M4 ReSTIR 首版可运行/可配置（`9dd0639` + 间接时域 reservoir `e7defe8`），完整 spatial reuse/直接光 reservoir 历史仍待补。

进度记录：[m1](m1.md) · [m2](m2.md) · [m3](m3.md) · [m4](m4.md)。
