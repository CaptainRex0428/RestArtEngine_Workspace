# 实时 GI 四项扩展

目标：实现并配置化四条实时 GI 路线——PathTracing 时域/空域降噪（相机 + 逐物体运动向量）、SSGI、DDGI、ReSTIR DI/GI。

设计见 [RealtimeGiOptions](../../design/RealtimeGiOptions.md)。当前状态：M1 完成；M2 SSGI 首版完成（Deferred，D3D11/native D3D12 已验证，提交 `1768b21`）；下一步 M3 DDGI。

进度记录：[m1](m1.md) · [m2](m2.md)。
