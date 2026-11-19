# 实时 GI 四项扩展

目标：实现并配置化四条实时 GI 路线——PathTracing 时域/空域降噪（相机 + 逐物体运动向量）、SSGI、DDGI、ReSTIR DI/GI。

设计见 [RealtimeGiOptions](../../design/RealtimeGiOptions.md)。当前状态：M1 完成（相机+逐物体重投影、temporal+spatial 降噪、多尺度迭代，已通过 native/hybrid 自测）；下一步 M2 SSGI。

进度记录：[m1](m1.md)。
