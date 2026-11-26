# Pass、Render Graph、RHI 与帧检查器答疑（2026-11-18）

状态：学习讨论／方案提案，不含实现授权；引擎代码未修改。基线14a6b0d。

## 问题与结论

1. “隐式Pass声明”不是正式机制；旧代码中阶段与依赖靠函数调用和绑定隐含表达。当前显式声明把名称/读写变为框架可校验的数据，和DX12显式API不是同一个“显式”。
2. Render Graph用依赖图编译执行计划；高级资源管理/并行是可选能力，不是判定图存在的全部条件。当前顺序声明列表是演进基础，尚无完整图编译/资源版本管理。
3. RHI是引擎的后端抽象，参数内存布局只是一部分。当前D3D11主渲染直连API，D3D12模块实际执行DXR RayQuery，经共享纹理/fence与DX11协作；不是不通，也不是完整DX12后端。
4. Frame Inspector升级提案：Pass前后快照 → 离线载荷包 → 指定Draw前后与绑定 → 受限D3D11回放 → 像素历史及DXR/跨API扩展。前几步可独立于RHI实施，完整回放需初始资源/状态/命令而不是只有场景配置。

## 文档与证据

- [原理学习](../learning/PassGraphRhiRelationship.md)
- [Frame Inspector方案](../design/FrameInspectorEvolution.md)
- 实际捕获入口：src/Renderer/SceneRenderer.cpp的FrameCapture阶段、RenderDiagnostics.inl的copyFrameCapture；共享设备/纹理/fence入口见学习笔记。
- 官方参考：Epic RDG、Microsoft DXR规范、RenderDoc原理文档，链接保留在对应笔记。
- 本轮只读源码/官方资料，没有构建或GPU复验；没有修改Sandbox或引擎源码。将概念澄清落盘，避免把“图高级优化”“RHI参数布局”“DXR桥”混成一个概念。

## 未决项与同步

Inspector里程碑是讨论方案，具体优先级/支持资源/文件格式/预算尚待实现前确认。本轮按协作规则提交并推送main，提交号以Git历史/交付回执为准；不创建引擎实现任务。
