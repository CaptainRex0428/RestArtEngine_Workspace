# RenderDoc 与自研 Frame Inspector 的区别（2026-11-18）

状态：解释与文档订正，不含新增捕获实现授权；引擎运行时代码未改动。
基线：引擎14a6b0d加未提交M1/M2/M3；此前[M3首阶段验收](../tasks/2026-11-18-native-d3d12/v3.md)。

## 问题与结论

用户询问“RenderDoc抓帧尚未实测”指官方工具还是自研实现。

- 这里指官方独立RenderDoc工具，支持D3D11/D3D12。需要实际启动/捕获本引擎、打开捕获并检查Draw、资源及管线，才能将该后端RenderDoc验收标为通过；此前没有该证据。
- 引擎自研的是Frame Inspector：记录引擎已知Pass/Draw事件和指定捕获点的冻结资源，非通用API拦截或完整重放。现有实现位于D3D11路径；原生12尚未迁移其资源捕获。
- Screenshot/F9另为普通窗口图像保存，不是上述帧命令捕获。
- 源码src/app/include、构建与scripts搜索未发现RenderDoc API接入（RENDERDOC_GetAPI等）；当前不应描述为已内嵌官方RenderDoc。官方工具支持该API不等于本引擎已实测兼容。
- “不承诺性能提升”与捕获工具是否自研无关：当前原生12首阶段使用同步fence，未完成同场景同设置的GPU性能前后对照，不能仅因API切到12就声称更快。

## 依据与文档

- [RenderDoc官方仓库](https://github.com/baldurk/renderdoc)：独立抓帧调试工具、支持D3D11/12。
- [Diagnostics](../../../docs/Diagnostics.md)、[后端矩阵](../../../docs/RenderBackends.md)、`src/Renderer/RenderDiagnosticsApi.inl`。
- [学习记录](../learning/PassGraphRhiRelationship.md)：保留外部抓帧、自研冻结资源与截图三种边界。

发现公开Diagnostics旧首版段落仍写“DX12未接入场景”，改为当前后端说明并明确本页Inspector实现仅11，避免将首版能力与M3混淆。仅文档订正，未重建或执行GPU/RenderDoc。复用已有RHI迁移和捕获边界经验，不新增重复经验文件。协作记录独立提交并同步。
