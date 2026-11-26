# 材质模板与 Shader 编写方案探讨

状态：**方案提案，未实现**。基线：引擎 `14a6b0d`。相关：[渲染架构学习](../learning/RenderingArchitecture.md)、[讨论记录](../conversations/2026-11-11-rhi-material-system.md)。

## 1. 目标与非目标

**目标**

- 材质作者用稳定的“模板 API”编写材质逻辑，而不是复制整份 HLSL；
- 运行时可调参数（颜色/粗糙度/金属度/纹理）进常量缓冲，不重编译；
- 静态选项（TwoSided/Grid/阴影/DXR 等）生成受控变体；
- 所有 Pass（Base/Shadow/DXR/GI）共享同一份材质求值函数，语义一致；
- 为未来节点图或 DSL 留出代码生成接口，且不绑定单一图形 API。

**非目标（当前阶段）**

- 不造完整编译器/类型系统/调试器；
- 不做运行时 JIT；
- 不在第一阶段做节点图编辑器；
- 不追求“所有后端完全同一字节码”，跨后端交给平台编译器。

## 2. 现状（已实现）

- Shader 为手写 HLSL：`Shaders/Private/Scene.hlsl` 内含 `MaterialAtUv(...)`，`Shaders/Materials/Standard.hlsli` 提供默认材质。
- 材质数据固定字段：`MaterialAsset { baseColor[3], roughness, metallic, grid, twoSided }`，存 `.rasset`。
- 参数通过 `SceneConstants`/`ObjectConstants` 的固定字段传递，没有材质级参数缓冲。
- 热编译：`applyShaderSource` 先候选编译 2 VS + 6 PS + 硬件管线，反射校验通过后整体替换；失败保留旧版本。
- 没有参数 Schema、模板 API、permutation、变体缓存、纹理参数。

## 3. 方案选项

| 方案 | 做法 | 成本 | 收益 | 风险 |
|---|---|---|---|---|
| A. 模板 HLSL + 代码生成（推荐） | 固定 `EvaluateMaterial` 模板；节点/DSL 生成函数体；DXC 编译 | 中 | 上手快、调试直观、可复用现有热编译 | 字符串生成易失控，需要约定与校验 |
| B. 自定义 Shader 语言 + 转译 | 自写词法/语法/类型检查/IR/代码生成 | 高 | 强类型、可控语义、可跨后端 | 工具链长期成本；错误诊断难；易过度设计 |
| C. 节点图直接生成 HLSL | 图节点映射为 HLSL 表达式片段 | 中高 | 美术友好、UE 式工作流 | 图求值顺序/预览/撤销复杂；需要 UI 投入 |
| D. 运行时 JIT/字节码 VM | 引擎内编译或解释 | 很高 | 热更新灵活 | 性能与调试代价大，不适合当前阶段 |

结论：先做 A，C 作为 A 的上层；B 只在出现“必须跨后端统一语义/需要强类型工具链”的明确需求时再评估；D 不建议。

## 4. 推荐路线（分阶段）

### M1：参数 Schema + 自动生成 `MaterialConstants`

- `.rasset` 增加 `template` 与 `parameters`：
  ```json
  {
    "template": "StandardOpaque",
    "parameters": {
      "BaseColor": [0.85, 0.28, 0.08],
      "Roughness": 0.25,
      "Metallic": 0.65
    },
    "staticSwitches": { "TwoSided": false, "Grid": false }
  }
  ```
- 由 Schema 生成 `MaterialConstants`（16 字节对齐）与 HLSL cbuffer（新增 b9，b5 空余可用）。
- 编辑器 Details 由 Schema 动态生成控件；旧字段做迁移映射。
- 验收：材质颜色/粗糙度/金属度可实时改；反射契约通过；旧 `.rasset` 可读。

### M2：模板 API（HLSL 函数库）

```hlsl
// MaterialTemplate.hlsli —— 材质作者/生成器实现的唯一入口
struct MaterialInputs {
    float3 baseColor;
    float roughness;
    float metallic;
    float3 emissive;
    float opacity;
    // 纹理句柄由绑定层提供
};

struct SurfaceContext {
    float3 worldPosition;
    float3 worldNormal;
    float2 uv0;
    float2 uv1;
};

Surface EvaluateMaterial(MaterialInputs m, SurfaceContext c);
```

- `Standard.hlsli` 变成 `EvaluateMaterial` 的一个实现；
- `Scene.hlsl` 的 BasePass、Shadow、DXR、GI 都调用它；
- 验收：切换模板不改变 Pass 代码；两套模板截图可区分；DXR 与光栅结果一致。

### M3：代码生成 / 节点图

- 节点 → HLSL 函数体字符串 → 拼进模板；
- 生成器输出带行号映射（`#line`），编译错误能回指节点；
- 预览用现有 GPU 材质球/离屏预览；
- 验收：一个最小节点集（常量/乘法/纹理采样/法线）可生成并编译。

### M4：变体与缓存

- 变体键：`template + staticSwitches + pass + platform` 的哈希；
- 编译结果缓存到 `Saved/ShaderCache/<hash>.bin`；失败保留旧变体并显示诊断；
- 控制静态维度（建议先只允许 TwoSided/Grid/Shadow/DXR/GI）；
- 验收：改静态开关触发重编译；相同键命中缓存；失败回退旧版本。

### M5：跨后端

- 代码生成统一输出 HLSL；DXC 编 DXIL 或 SPIR-V；Metal 经 SPIRV-Cross；
- RHI 提供 `createShaderModule(stage, bytecode, entry)` 与反射绑定；
- 验收：同材质在 DX11 与一个第二后端画面一致（容差内）。

## 5. 架构与数据流

```
MaterialAsset(.rasset) ──参数值/静态开关──┐
                                        ↓
Editor Details（Schema 驱动）      Material System（Schema/实例覆盖/脏标记）
                                        ↓
                              Codegen（模板/节点 → HLSL）
                                        ↓
                        Shader Compiler（DXC/FXC）→ 字节码 + 反射
                                        ↓
                    Variant Cache（键=模板+开关+Pass+平台）
                                        ↓
BasePass/Shadow/DXR/GI ── 选变体 + 绑 MaterialConstants/纹理 + setPSO → RHI
```

## 6. 数据结构草案

```cpp
struct MaterialParameterSchema {
    std::string name;
    enum class Type { Color, Scalar, Texture } type;
    std::array<float,4> defaultValue;
    std::string textureSlot;   // Type::Texture 时使用
};

struct MaterialTemplate {
    std::string name;                 // "StandardOpaque"
    std::vector<MaterialParameterSchema> parameters;
    std::vector<std::string> staticSwitches; // "TwoSided","Grid"
    std::string generatedFunction;    // EvaluateMaterial 的函数体
};

struct MaterialConstants {            // b9；16B 对齐，由 Schema 生成
    std::array<float,4> baseColor;    // rgb + unused
    std::array<float,4> roughnessMetallic; // r, m, unused, unused
    // 新增参数按 float4 追加
};

struct ShaderVariantKey {
    std::string templateName;
    std::uint32_t staticMask;         // TwoSided/Grid/...
    RenderPassKind pass;              // Base/Shadow/DXR/GI
    std::uint32_t platform;           // DX11/DX12/Vulkan...
};
```

## 7. RHI 需要提供的接口（提案）

```cpp
struct ShaderModule;   // 编译产物 + 反射（cbuffer 布局、纹理槽、输入布局）
struct PipelineState;  // PSO 描述产物

IDevice::createShader(stage, bytecode, entry) -> ShaderModule;
IDevice::createPipeline(PipelineStateDescription) -> PipelineState;
IDevice::createBindingLayout(reflection) -> BindingLayout;
ICommandList::setPipeline(ps); setBindings(layout, resources); draw(...);
IDevice::capabilities() -> { supportsRayTracing, supportsBindless, ... };
```

材质系统只依赖“ShaderModule + 绑定布局 + PSO”，不接触具体 API。DXR 作为可选扩展（`IRayTracingDevice`），不塞进基础接口。

## 8. 职责边界

| 层 | 负责 | 不负责 |
|---|---|---|
| 编辑器 | 参数值编辑、默认值、撤销、预览入口 | 直接绑 GPU |
| 材质系统 | Schema、序列化、实例覆盖、脏标记、纹理引用 | 选 Pass/变体 |
| 代码生成 | DSL/节点 → HLSL、静态开关、`#line` 映射 | 编译/绑定 |
| 编译器封装 | DXC/FXC 调用、反射、错误诊断 | 资源生命周期 |
| BasePass/渲染器 | 选变体、绑 `MaterialConstants`/纹理、设 PSO、draw/dispatch | 定义材质语义 |
| RHI | 设备/资源/命令/PSO/同步/能力 | 理解材质 |

## 9. 失败与回退

- 编译失败：保留旧变体，返回带行号/节点映射的诊断；
- 变体缺失：回退到 `StandardOpaque` 默认变体并提示；
- 参数越界：Schema 校验（范围/类型/纹理存在），保存失败不破坏旧资产；
- 缓存损坏：忽略并重编，不阻塞启动；
- 热编译期间：候选编译 + 原子替换，失败不动现有管线（沿用现有 `applyShaderSource` 契约）。

## 10. 测试与验收

- CPU：Schema 解析、默认值、迁移、变体键哈希、缓存命中/失效；
- 反射：cbuffer 名字/槽位/大小/偏移、纹理槽、输入布局；
- GPU 画面：两套模板可区分；BasePass 与 DXR 同材质一致（容差）；
- 交互：Details 改参数实时预览；改静态开关触发重编；失败保留旧画面；
- 回归：现有 22 个 CTest、编辑器自测（前台焦点可用时）。

## 11. 风险与开放问题

- **变体爆炸**：静态开关每加一个翻倍；需要上限与缓存策略。
- **跨后端语义**：HLSL 的矩阵/NDC/裁剪空间差异需 RHI 或代码生成统一。
- **纹理参数**：D3D11 直绑 vs D3D12 root signature/Vulkan descriptor set，需要绑定布局抽象。
- **调试**：生成代码难读；需要 `#line`、节点映射、Shader 调试符号策略。
- **性能**：`MaterialConstants` 每材质每帧更新频率、cbuffer 数量上限（D3D11 有 slot 限制）。
- **兼容**：旧 `.rasset` 没有 `template/parameters` 时如何迁移；默认模板如何选择。
- **是否值得做 DSL**：在 M1–M3 验证后再评估，不提前投入编译器工程。

## 12. 里程碑（建议）

| 里程碑 | 产出 | 验收 |
|---|---|---|
| M0 | 本文档与学习笔记 | 评审通过，不改代码 |
| M1 | 参数 Schema + `MaterialConstants` | 现有 Standard 材质走新路径，画面不变 |
| M2 | `EvaluateMaterial` 模板 API | Base/Shadow/DXR/GI 共用，截图一致 |
| M3 | 最小节点/代码生成 | 一个节点图可编译并预览 |
| M4 | 变体键 + 缓存 + 回退 | 改开关重编、命中缓存、失败保留 |
| M5 | 第二后端 | DX11 与第二后端画面一致（容差） |

## 13. 状态

以上均为提案，**未实现**。当前引擎仍是手写 HLSL + 固定 `MaterialAtUv`；RHI 仍是骨架。任何阶段开始前需确认验收范围与文件归属。
