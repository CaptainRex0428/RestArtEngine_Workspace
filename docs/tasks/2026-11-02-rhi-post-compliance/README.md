# 2026-11-02 RHI 后处理设计合规审计

状态：通过（本轮切片）
引擎基线：`93f0c3c` + 本轮工作区改动
协作库基线：`main`（本轮 clone 后）

## 目标

用户要求把开发文档克隆到 `local/`、同步规范，并检查已做的后处理/RHI 设计是否符合规范后继续开发。

## 结果摘要

- 通过 `scripts/Sync-Workspace.ps1` 完成 Status/Install，skills 与 agents 全部 Synced。
- 对照 [RenderingDevelopment.md](../../../docs/RenderingDevelopment.md) 四条要求审计后处理/RHI 实现，发现并修复：
  1. `PostEffect::Taa` 的阶段映射错误：代码标为 `LinearHdr`，实际执行在 tonemap 之后（显示空间）；已改为 `Display` 并更新测试与文档。
  2. RHI 后处理 shader 内嵌在 `SceneRenderer.cpp`，不符合“源码入口可定位、职责清晰”；已拆到 `Shaders/Private/Rhi/{Fxaa,MotionBlur,Taa}.hlsl`。
  3. RHI post shader 未参与 `reloadShaders` 生命周期；现在重载成功后失效 RHI 管线，下一帧重新读取/编译，失败保留 D3D11 回退。
- 更新公开文档中过时的 TAA/RHI/测试计数描述。

## 未完成

- Tonemap/Bloom/DOF 仍为 D3D11；DX12 场景纹理共享未完成；因此“整条后处理链迁移”未达成。
- RHI post pipeline 暂无 D3DReflect 契约校验（原生 Scene.hlsl 有）；文件监听/异步热编译未实现。
- `SceneRenderer.cpp` 仍持有后处理执行逻辑，属于既有执行器结构，本轮未拆 Pass 类。

## 证据

- `artifacts/compliance-taa/`、`artifacts/compliance-backend/`、`artifacts/compliance-validate.log`
- 详见 [v1.md](v1.md)。
