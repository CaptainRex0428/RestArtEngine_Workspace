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
7. **绑定契约用反射钉死**：`RhiPipelineDesc` 声明 `sourceCount` 与 `constantBufferSize`，`createPipeline` 内 DX11 走 `D3DReflect`、DX12 走 `IDxcUtils::CreateReflection`，共享同一校验函数；错误在创建阶段返回并触发既有回退，而不是等 draw 才黑屏。
8. **真实 shader 参与 smoke**：除了构造负例，还要用 `Shaders/Private/Rhi/*.hlsl` 和调用方相同的声明在两条 API 上创建管线；声明与 shader 一起漂移时能被立刻发现。
9. **运行时共享先串行**：共享纹理的创建/打开、keyed mutex 与回读先在一帧内 CPU 串行验证正确性，再换共享 fence；不要一开始就做跨设备并发。
10. **共享 fence 用同一套 RHI 接口**：`createSharedFence`/`openSharedFence`/`signalFence`/`waitFence` 放在 `IRenderBackend`，DX11 侧 `ID3D11Device5::CreateFence(D3D11_FENCE_FLAG_SHARED)` 导出，DX12 侧 `OpenSharedHandle` 后在队列上 Signal/Wait；导出的 NT 句柄在打开后 `CloseHandle`。

## 验证

- `--backend-self-test`：RHI 自有纹理、原生 FP16、单/双源、两段链。
- `--taa-self-test`：TAA/FXAA/Motion 组合、历史、resize。
- `Validate-Render` + `--hardware-rt-self-test`：默认路径与硬件帧不回归。
- 对每次 RHI 路径开启打印/诊断或专项探针确认实际生效；不能把回退通过当成迁移通过。

## 边界

- DX12 已能打开场景 HDR/Bloom/深度/历史共享纹理并在 `--dx12-post` 下执行 Tonemap/TAA/FXAA；运动模糊与 DOF 仍在 DX11 RHI。
- RHI post pipeline 已有 `D3DReflect` / DXC 反射契约校验；文件监听/异步热编译未实现，只有显式 `reloadShaders`。
- Tonemap 的运行时天空问题已定位：**原生 FXAA 消费 RHI post**，不是 HDR 导入/句柄问题。运行时改为 RHI FXAA 写显示纹理后回拷交换链。
- 调试视图与显示变换语义不同；Tonemap RHI 首版以 `debugView == 0` 为边界，调试视图保留原生直通，避免 normals/unlit 被 ACES/gamma 改写。
- 交换链不能被 RHI 直接绑定；RHI 后处理的运行时出口必须显式回拷。
- Bloom 的半分辨率目标不能用来换算全分辨率 viewport：阈值/模糊的 UV 分母必须是全场景尺寸，否则 inset/半分辨率映射错误，调试视图会变黑。
- Bloom 在 `debugView != 0` 保留原生路径，避免 Unlit 直通被 Bloom 合成改写。
- 读取自身目标的 Pass（DOF）需要显式 `copyTexture` 快照；DX12 必须经过 COPY_SOURCE/COPY_DEST 屏障，不能直接同资源读写。
- DOF 的 RHI 版本以 `debugView == 0` 为边界，失败回退原生，避免模糊/显示语义在调试视图分叉。
- DX12 共享纹理：句柄创建/`OpenSharedHandle` 可行；DX11 侧必须显式 `AcquireSync(0)` → 写入 → `ReleaseSync(0)`。SceneRenderer 的 HDR/Bloom/显示色/深度/历史共享与共享 fence 已在 `--dx12-post` 下接通（TAA 与 DX11 路径 MAE 8e-5）。
- 采样器不是必填：FXAA 用整数 `Load`，不声明 `s0`；契约只能限制“最多一个 `s0` 且必须在 s0”，不能要求“有源就有采样器”，否则真实 shader 会在创建阶段被误拒。
- 反射校验只覆盖源码级绑定；运行时 descriptor/root signature 是否绑定正确仍需画面或回读验证。DX12 的反射来自 DXIL 容器，strip reflection 后需要另存反射数据。
- 新增或修改后处理时，`sourceCount` 与 `constantBufferSize` 必须和 HLSL、C++ 常量结构同时更新；只改一侧会在创建阶段失败并静默回退到 D3D11。
- D3D11 共享纹理必须同时设置 `SHARED_NTHANDLE | SHARED_KEYEDMUTEX`；只设 NTHANDLE 时 `CreateTexture2D` 返回 `E_INVALIDARG`。DX11 写入前后要 `AcquireSync(0)` / `ReleaseSync(0)`。
- DX12 打开共享纹理后若作为渲染目标，RHI 必须为它创建 RTV 描述符；否则 `OMSetRenderTargets` 报未初始化描述符，随后 `DrawInstanced` 报 PSO 与目标格式不匹配。
- `CopyResource` 前先解绑上一 Pass 的 RTV/SRV，否则 D3D11 校验会报资源仍绑定。
- 跨 API 共享的运行时验证用同一帧截图逐像素比较（MAE、最大差、changed>3），不能只看“没有报错”。
- 共享 HDR/Bloom 用 RGBA16F、SRV-only 的 NTHANDLE|KEYEDMUTEX 纹理；每张纹理各自持有 keyed mutex。一次帧内可以连续拷入多张输入，再统一等待一次 DX11 完成，然后执行 DX12 Pass。
- Tonemap 迁到 DX12 时，`sourceCount=2` 的 t1 在 Bloom 关闭时绑定 HDR 本身，和 DX11 RHI 路径保持一致；`RhiTonemapConstants` 的 112 B 布局与 Bloom 尺寸一起参与契约。
- 一帧里 Tonemap 与 FXAA 各是独立的“拷入→等待→DX12 绘制→拷回”，中间不能共用同一张共享输出而不回拷，否则后一个 Pass 会覆盖前一个结果。
- 共享 typeless 深度时，拷贝源和目标都保持 `R32_TYPELESS`，DX12 侧用显式 `R32_FLOAT` 建 SRV；否则 typeless 资源无法直接采样。
- TAA 共享必须同时带颜色、深度与上一帧历史，成功后更新写索引/历史有效位/上一帧投影；只共享颜色会退化为当前帧。
- 对比截图要按文件名精确比较，目录里混入旧 capture（不同工程设置）会让结论完全相反。

## 来源

- 任务：[2026-11-02 RHI 后处理设计合规审计](../tasks/2026-11-02-rhi-post-compliance/v1.md)、[v2](../tasks/2026-11-02-rhi-post-compliance/v2.md)、[v3](../tasks/2026-11-02-rhi-post-compliance/v3.md)、[v4](../tasks/2026-11-02-rhi-post-compliance/v4.md)、[v5](../tasks/2026-11-02-rhi-post-compliance/v5.md)、[2026-11-11 管线绑定契约反射校验](../tasks/2026-11-11-rhi-pipeline-reflection/v1.md)、[2026-11-11 DX12 场景共享 v1](../tasks/2026-11-11-dx12-scene-share/v1.md)、[v2](../tasks/2026-11-11-dx12-scene-share/v2.md)、[v3](../tasks/2026-11-11-dx12-scene-share/v3.md)
- 相关实现：`include/RestArtEngine/Renderer/RenderBackend.h`、`src/Renderer/RenderBackend.cpp`、`src/Renderer/SceneRenderer.cpp`、`Shaders/Private/Rhi/`。
