# RHI 后处理迁移经验

## 场景

把 FXAA、运动模糊、TAA、Tonemap 等后处理 Pass 从 `SceneRenderer` 的 D3D11 提交迁到 `IRenderBackend`，或在 RHI 上扩展多源绑定。

## 原因

- DX11 与 DX12 的资源状态、描述符和命令提交模型不同；直接把 D3D11 即时上下文逻辑复制到 RHI 会隐藏同步与生命周期问题。
- 后处理 shader 若内嵌在 C++，会失去源码入口、重载与审查能力；仅“能编译”不等于符合渲染开发规范。
- 阶段枚举（Lighting/LinearHdr/Display）是跨模块契约，必须与实际执行位置一致；否则 UI、计划与文档会分叉。

## 做法

1. **先证明最小资源契约**：用独立 smoke 验证原生纹理导入 → RHI 采样 → 回读；再接入场景。FP16 导入、typeless 深度需显式 SRV 格式、目标需 RTV 标志，分别覆盖。
2. **按 source 数量扩展 API**：`drawPostProcess`/`2`/`3` 分别绑定 t0、t1、t2；DX12 同步扩 descriptor table 与 SRV heap，不能只改 shader。
3. **Shader 文件化**：每个 RHI post pass 一个 HLSL 文件，运行时读取；常量结构用 `static_assert` 固定布局。
4. **重载成对实现**：`reloadShaders` 成功后释放 RHI post 管线并重置 attempt，下一帧重编译；失败保留原生回退。
5. **阶段从执行位置推导**：TAA 在 tonemap 后、显示空间，必须归入 `Display`，不能因为固定顺序靠前就归入 `LinearHdr`。
6. **回退是契约的一部分**：每次 RHI 尝试都必须保留 D3D11 路径；验证时确认 RHI 路径确实开启，而不是“回退后测试仍通过”。

## 验证

- `--backend-self-test`：RHI 自有纹理、原生 FP16、单/双源、两段链。
- `--taa-self-test`：TAA/FXAA/Motion 组合、历史、resize。
- `Validate-Render` + `--hardware-rt-self-test`：默认路径与硬件帧不回归。
- 对每次 RHI 路径开启打印/诊断或专项探针确认实际生效；不能把回退通过当成迁移通过。

## 边界

- DX12 当前只支持 RHI 自有纹理；场景 HDR/深度/历史的共享纹理路径未实现。
- RHI post pipeline 尚无 D3DReflect 契约校验；文件监听/异步热编译未实现，只有显式 `reloadShaders`。
- Tonemap 的运行时天空问题已定位：**原生 FXAA 消费 RHI post**，不是 HDR 导入/句柄问题。运行时改为 RHI FXAA 写显示纹理后回拷交换链。
- 调试视图与显示变换语义不同；Tonemap RHI 首版以 `debugView == 0` 为边界，调试视图保留原生直通，避免 normals/unlit 被 ACES/gamma 改写。
- 交换链不能被 RHI 直接绑定；RHI 后处理的运行时出口必须显式回拷。

## 来源

- 任务：[2026-11-02 RHI 后处理设计合规审计](../tasks/2026-11-02-rhi-post-compliance/v1.md)、[v2](../tasks/2026-11-02-rhi-post-compliance/v2.md)
- 相关实现：`include/RestArtEngine/Renderer/RenderBackend.h`、`src/Renderer/RenderBackend.cpp`、`src/Renderer/SceneRenderer.cpp`、`Shaders/Private/Rhi/`。
