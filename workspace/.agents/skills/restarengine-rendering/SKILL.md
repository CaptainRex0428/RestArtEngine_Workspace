---
name: restarengine-rendering
description: "Develop and review RestArtEngine rendering, hand-written shaders, passes, pipelines, and features; preserve shader hot compilation, live parameter feedback, and portable DX11/DX12/Vulkan/OpenGL boundaries. Use for this engine's rendering work and cross-platform rendering design."
---

# RestArtEngine Rendering

本技能用于 RestArtEngine 的核心渲染开发与审查。四条要求及验收定义以 [docs/RenderingDevelopment.md](../../../docs/RenderingDevelopment.md) 为准。Windows、Linux、macOS 均纳入首轮架构设计，图形后端范围包括 DX11、DX12、Vulkan、OpenGL；设计目标不代表已经实现。

## 先确认现状

分派任务先用 [restarengine-context](../restarengine-context/SKILL.md) 核对项目事实与进度索引；交付使用 [restarengine-delivery](../restarengine-delivery/SKILL.md) 的证据标准。主 agent 给出文件归属、依赖、目标画面和验收范围，统一契约见 [AgentDevelopment.md](../../../local/docs/AgentDevelopment.md)。已经核对且没有相关变化的文档无需重复读取。

读取仓库 `AGENTS.md`（若存在）、[docs/Architecture.md](../../../docs/Architecture.md) 和 [docs/RenderingDevelopment.md](../../../docs/RenderingDevelopment.md)，检查工作区状态，再读与任务有关的源码。现有结构以 `README.md` 与 `Architecture.md` 为准；渲染开发文档将要求、现状缺口和设计草案分开记录，不把草案当作现成接口。

按改动范围选择入口：

- GPU 管线与数据契约：`include/RestArtEngine/Renderer/SceneRenderer.h`、`src/Renderer/SceneRenderer.cpp`、`Shaders/Private/Scene.hlsl`。
- 材质与编辑预览：`Shaders/Materials/Standard.hlsli`、当前工程的材质 Shader、`src/Editor/SceneEditor.cpp`。
- 后端与构建：`include/RestArtEngine/Renderer/RenderBackend.h`、`src/Renderer/RenderBackend.cpp`、`CMakeLists.txt`、`RestArtEngine.lua`。
- 硬件光追：`src/Renderer/D3D12/HardwareRayTracing.*`、`Shaders/Private/HardwareRayTracing.hlsl`／`HardwareTrace.hlsli`；能力、共享资源和项目配置契约见 [HardwareRayTracing.md](../../../docs/HardwareRayTracing.md)。`--hardware-rt-self-test` 区分真实 dispatch／像素验证与不可用时的明确跳过，不能把跳过当作硬件执行通过。
- 可观察验证：`app/EditorSmoke.cpp`、`scripts/Validate-Render.ps1`。

## 开发流程

1. 追踪“源码或界面参数 → CPU 状态 → GPU 数据／Shader／Pass → 实际场景视口”。确定模块归属、资源生命周期、后端能力和可见验收，再修改代码。
2. 按所属模块放置可复用功能。手写 Shader、Pass、管线或 Feature 时，明确源码入口、参数契约、资源读写、执行顺序和开关。小改动沿用现有结构；需要扩展时逐步引入文档中的职责边界，不创建空框架，不向共享场景、资产或特性代码增加平台依赖。
3. 热编译使用候选构建、完整校验、成功后整体替换；编译、反射或 GPU 管线创建失败时保留上一版。普通数值变化应在下一次可呈现的场景帧生效，无需保存、重启或源码重编译。材质通过只读草稿覆盖实时预览，预览、Apply、Save、Discard 及切换时 Cancel 的语义遵守渲染开发文档；不将预览写入已提交资产。
4. 从用户意图、构建可用性、设备能力及特性依赖计算实际启用状态。差异放在后端或特性实现边界内；不支持的模式给出原因，按定义禁用或降级。禁用后不能遗留无效资源依赖；切后端不能丢失用户请求值。
5. 依据改动运行相关验证并检查真实视口结果。Shader 改动验证成功改画面、失败保留画面及受影响的 include；参数改动验证编辑过程中的反馈和预览／提交／保存语义；后端或特性开关验证资源重建、不支持项、失败恢复及逻辑设置保留。复用下方现有检查，仅针对有意义的新增缺口补充覆盖。
6. 交付说明改动、模块归属、运行证据和未验证范围。Windows/DX11 结果不能外推为其他后端或平台已通过。涉及尚未确定的 Shader 工具链、macOS 路线、最低能力等级时，更新设计选项并与用户讨论；继续完成不依赖该选择的已授权工作。

## 离屏工具预览

材质球、Asset Details、场景缩略图走同一套离屏预览路径（`SceneRenderer::renderPreviewFrame`、`renderMaterialPreview`、`renderScenePreview`）。改动或新增预览时：

- 必须设置 `SceneSettings::offscreenTarget = true` 才会画进场景目标；只把 `editorViewport` 设为 false 会把结果画到交换链，读回只剩清屏色（本项目实际踩过）。
- 预览借用场景目标的一个角落渲染，再把 region 复制到独立预览纹理，主帧渲染随后覆盖；不要假设预览会保留整张场景图。
- 预览是工具窗口能力，不改变正式场景/材质语义；保存流程可以生成 `.rthumb` 派生sidecar，需分别验证图像刷新和正式资产写入。多窗口预览须检查同帧纹理内容与生命周期。
- 验证优先用 staging 纹理回读像素（颜色是否随参数/相机变化、是否非全黑），而不是只看主窗口截图；材质编辑器是独立 OS 窗口，自测截图不包含它。
## 诊断采集

诊断数据契约见 [Diagnostics.md](../../../docs/Diagnostics.md)。应用帧身份不能按 `render()` 调用递增：材质/详情/缩略图也会调用渲染器，不能消费主场景捕获。异步 GPU 结果保留原 Frame ID，CPU 提交时间与 GPU 执行时间分别标识。捕获资源必须独立持有；ImGui 在本帧可能已借用旧 SRV，替换或 Clear 后需在 UI 提交的安全边界退役，不能立即销毁。验证同时比较原始资源和实际显示转换，不用 CPU 公式相等冒充 GPU 画面。

## 验证入口

可执行渲染改动按架构约定及影响范围选择检查；当前 CMake Debug 入口：

```powershell
cmake --preset windows-vs2022
cmake --build --preset windows-debug
$renderExe = Join-Path (Get-Location) 'build/cmake-vs2022/Debug/RestArtEngine.exe'
& $renderExe --editor-self-test --capture-dir artifacts/rendering-editor
.\scripts\Validate-Render.ps1 -Executable $renderExe -CaptureDirectory artifacts/rendering-validation
```

显式指定本次构建的可执行文件；验证脚本默认寻找 Premake 输出。只通过构建、修改 revision 或 CPU 数值，都不足以证明画面正确。仅修改文档或技能时检查格式、引用和约束一致性，不宣称进行了 GPU 验证。

## 渲染 agent

项目角色定义于 [.codex/agents/restarengine_rendering.toml](../../../.codex/agents/restarengine_rendering.toml)。主 agent 分派有明确文件归属、预期画面与验证范围的实现或审查任务。角色不指定模型或 provider。若当前客户端无法选择项目角色，普通子 agent 显式读取本技能后执行，并如实说明采用了该方式。
