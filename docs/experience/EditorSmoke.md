# 编辑器自测（--editor-self-test）经验

## 场景

在无前台窗口的自动化会话里跑 `--editor-self-test`，或给编辑器 UI 增加控件后维护这套端到端自测。

## 做法

1. **前台激活要显式争取**：测试进程若不是前台，Windows 会拒绝 `SetForegroundWindow`。用 `AttachThreadInput` 附加到当前前台线程，再 `ShowWindow` / `BringWindowToTop` / `SetForegroundWindow` / `SetFocus`，最后解除附加。先探测 `GetForegroundWindow` 的 pid，能快速判断是不是环境问题。
2. **夹具目录必须可重入**：固定写 `output/<Fixture>` 的测试，在写入前 `remove_all`。否则上一次失败运行的残留会让计数、扫描类断言以奇怪方式失败。
3. **滚动断言不要假设一次到位**：`SetScrollY(ScrollMax)` 后，新可见内容的布局可能继续增大 `ScrollMax`。重设并重新捕获，直到稳定；诊断时只读窗口字段，不要在 ImGui 上下文之外调用 `GetIO()` 等 API。
4. **ImGui disabled 作用域按“控件归属”管理，不按 UI 分组**：一个 UI 组可以包含多个 effect（例如 “Anti-aliasing” 同时有 FXAA 和 TAA）。每个 `enabled` 复选框应关闭上一个作用域、再按需开启自己的作用域；只按组切换关闭会留下未配对的 `BeginDisabled`。
5. **断言会挂住进程**：`IM_ASSERT` 在 Windows debug 构建里可能弹对话框等待输入，自动化会看起来“卡住”。把断言当失败处理，并在复现时先 `Stop-Process`。

## 验证

- `--editor-self-test` 退出码 0，日志中所有段为 PASS，`D3D11 validation errors: 0`。
- 失败时保留 `[focus]` / `[scroll]` / 窗口名诊断输出，下一次排查不用再猜。

## 边界

- `AttachThreadInput` 是测试侧兜底，不改变编辑器正常运行时的窗口激活行为。
- 自测依赖真实窗口与输入注入，适合在有交互桌面的 Windows 会话运行；纯 headless CI 需要额外的窗口站/桌面配置。
