# 2026-11-12 editor smoke 环境问题排查

状态：通过
基线：`f20e445` + 本轮工作区改动
协作库基线：`main`

## 目标

查清 `--editor-self-test` 在本机持续失败的原因：

> Native Content did not gain focus before the drag.

并让编辑器全流程自测重新可跑。

## 结果摘要

- 根因一：exe 由非前台进程启动，Windows 拒绝 `SetForegroundWindow`；用 `AttachThreadInput` 的激活助手修复（测试侧）。
- 根因二：测试夹具目录复用，旧 `.rasset` 让 registry 计数失败；补 `remove_all`。
- 根因三：ScrollMax 在首次布局后增长 13px，断言过严；改为重试到稳定。
- 根因四：Project Settings 的 disabled 作用域按“UI 组”管理，但 “Anti-aliasing” 组含 FXAA 与 TAA 两个 effect，两个都关闭时连续 Begin 只 End 一次 → ImGui `Missing EndDisabled()` 断言并挂起。修复为按 effect 管理作用域。
- 最终：`--editor-self-test` 退出 0，59 个 PASS 段，validation 0；全量重建 0 warning。

## 证据

- `artifacts/editor-focus/editor10.log`
- 详见 [v1.md](v1.md)。
