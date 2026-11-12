# v5（分析，未落地）— 异步 RHI 提交为什么不能只去掉 waitForGpu

状态：尝试后回退，保留分析；后续由 [v6](v6.md) 按本分析落地
基线：`f47f312`；本轮无引擎代码变更

## 动机

v4 之后整条 DX12 后处理链仍由 `executeCommands` 末尾的 `waitForGpu` 串行化。去掉这次 CPU 等待，让共享 fence 承担 GPU 顺序，理论上可以让 CPU 提前提交后续 Pass/帧。

## 尝试

- `executeCommands`：提交后只 `Signal` 内部 fence，不再等待；
- 在飞命令对象用 `inFlight_` 持有，超过 8 个再排空；
- `readTexture` 在 `Map` 前显式 `waitForGpu`。

## 结果

| 检查 | 结果 |
| --- | --- |
| `--backend-self-test` | PASS |
| Sandbox `--dx12-post` 截图 vs 基准 | MAE **90.8**，最大差 190（画面明显错误） |
| TAA 工程 | MAE 1.67，TAA 结果等于当前帧（历史丢失） |
| validation | 0（没有报错，属于静默错误） |

回退后重新验证：Sandbox MAE 2.02e-7、TAA MAE 8.4e-5，恢复正常。

## 根因

异步提交后，下一批命令会在上一批 GPU 执行完成前重写共享资源：

1. **SRV 描述符堆被复用**：`drawPostProcessInternal` 每次把 t0..t2 写进同一个 `srvHeap_`；上一批 draw 可能还没执行，描述符已经被下一次 draw 覆盖。
2. **常量缓冲被复用**：`updateBuffer` 直接 `Map` 写同一块 b0；GPU 还在读上一帧/上一 Pass 的常量时，CPU 已经写入新值。
3. RTV 描述符在纹理创建时写一次，问题较小；allocator/list 每次新建，不是主要矛盾。

validation 为 0 说明这不是 API 用法错误，而是**资源版本化缺失**。

## 正确做法（下一步）

- 每次提交使用独立的 SRV 描述符堆（或 4 个堆轮转，复用前等对应 fence）；
- 每个常量缓冲做 4 槽 ring，`updateBuffer` 轮转，槽位复用前检查其最后使用 fence；
- allocator/list 同样做 ring，提交时记录 fence 值；
- 输出/输入共享纹理已有 DX11↔DX12 fence 顺序，可保持；
- 完成这些后再测帧时间，否则只是把正确性换成了“看起来更快”。

## 开销测量（同步版本）

600 帧、`--no-ui`，三次运行：

| 路径 | 用时（三次） | 平均 |
| --- | --- | --- |
| 默认 DX11 | 35.96s / 32.65s / 30.28s | 32.96s |
| `--dx12-post` | 35.74s / 34.40s / 29.91s | 33.35s |

差值约 0.4s / 600 帧（≈0.65ms/帧，约 1.2%），落在运行间噪声范围内。当前不足以据此默认开启；共享拷贝与 fence 交接的成本可见，但不是数量级问题。

## 结论

- 异步提交不是“删掉 `waitForGpu`”，需要描述符与常量的多版本管理；本轮不落地，避免用静默画面错误换理论收益。
- 同步版本 + 共享 fence 保持现状；`--dx12-post` 仍为实验开关。
