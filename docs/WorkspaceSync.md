# 公开引擎与私有协作库同步规范

## 结构和使用入口

工程停止通过坚果云同步。源码、公共技术文档与通用调用入口由引擎 Git 同步；skills、角色、进度与开发日志由嵌套在 `local/` 的独立私有 Git 同步。两个仓库各有提交历史和远端；引擎的 `.gitignore` 始终忽略整个 `local/`，不使用 submodule。

```text
RAEngine/                          继续在这里打开 IDE、终端与聊天
├─ .git/                           公开引擎仓库
├─ AGENTS.md                       公开轻量入口，读取私有 AgentEntry
├─ scripts/Sync-Workspace.ps1       公开薄封装，只调用私有同步工具
├─ .agents/skills/                 原调用位置，忽略的运行副本
├─ .codex/agents/                  原角色发现位置，忽略的运行副本
└─ local/
   ├─ .git/                        独立私有仓库
   ├─ docs/AgentEntry.md            完整私有入口与规则
   ├─ docs/DevelopmentStatus.md     共用进度，不按模型分叉
   ├─ docs/                        规范、经验、底稿，直接编辑
   ├─ workspace-manifest.json      逐文件同步白名单
   ├─ workspace/.agents/skills/    私有版本化副本
   ├─ workspace/.codex/agents/     私有版本化副本
   ├─ scripts/                    同步实现与测试
   ├─ .sync/                      本机三方比较状态，不提交
   └─ machine/Paths.md             本机路径，不提交
```

现有技能名、角色名、目录和相对引用不变。日常编辑运行目录下的 skill／agent，完成后 Collect 收集到私库；拉取私库后 Install 安装回运行目录。`local/docs/` 直接在私库内编辑，无需复制。不要直接从 `workspace/` 执行技能：那是存储副本，里面的相对链接按原运行位置设计。公开根 `AGENTS.md` 不参与 Collect/Install，私有同步永远不能覆盖它。

仅有公开 clone 时，源码构建和正常使用不依赖私库；`AGENTS.md` 只在私有入口存在时读取它。已有私库并完成 Install 后，继续在 RAEngine 根调用原来的 skills／agents；客户端发现列表需要刷新时重新打开会话，不声称复制文件能热刷新客户端。

## 首次绑定 GitHub 私库

远端为 `https://github.com/CaptainRex0428/RestArtEngine_Workspace.git`，主分支为 `main`，必须保持 **Private**。本机 `local/.git` 已独立初始化。以下为首次配置流程；已有 origin 不重复添加。认证通过 Git 凭据工具，不把 token 写入 URL 或文档：

```powershell
# 始终在 RAEngine 根运行；先确认两个仓库的根目录不同
git rev-parse --show-toplevel
git -C local rev-parse --show-toplevel
./scripts/Sync-Workspace.ps1 -Mode Status
./scripts/Sync-Workspace.ps1 -Mode Collect
git -C local status --short
git -C local add -- .gitignore .gitattributes README.md workspace-manifest.json docs scripts workspace
git -C local diff --cached --check
git -C local diff --cached --stat
# 检查实际暂存内容后提交；没有变化时跳过
git -C local commit -m "Set up private development workspace"
# 首次配置才 add；已配置先检查，不覆盖已有 origin
git -C local remote add origin https://github.com/CaptainRex0428/RestArtEngine_Workspace.git
git -C local push -u origin main
```

本地初始化或设置 origin 不表示已有云端备份；以推送成功及远端分支提交核对为准。不要在公开引擎根执行 `git add -f local`，也不要将私库设为 public。两个仓库的提交、推送分别检查授权和实际范围；一次引擎提交不自动提交私有资料，反之亦然。

## 日常同步与换机

**开始工作**：先 Status 检查运行副本；若有本机修改，先 Collect、审查并提交私库，再进行拉取。分别查看两个仓库的 `status` 后使用 `git pull --ff-only` 和 `git -C local pull --ff-only`；引擎自身有并发修改时按正常 Git 流程处理。随后 Install，确认 Status 全部 Synced，再在原目录开发。拉取遇到分叉或冲突时人工合并，不使用 reset/clean 丢弃修改。

**完成工作**：更新 `local/docs/DevelopmentStatus.md` 及领域规范，记录实际引擎 commit、未提交范围和验证证据；修改 skill／agent 后 Collect，再检查私库 diff。使用显式路径分别提交两个仓库。证据路径指向 `artifacts/` 不表示截图也已同步，跨机无法读取的证据保留“历史验证”身份。长期任务交接应写入 `local/docs/`；临时 `artifacts/agent-tasks/` 仍只在本机。

**新电脑**：先 clone 公开引擎，再将私库 clone 到它的 `local/`（目录必须不存在或为空；已有本地资料时先盘点，不能覆盖）：

```powershell
git clone https://github.com/CaptainRex0428/RestArtEngine.git RAEngine
Set-Location RAEngine
git clone https://github.com/CaptainRex0428/RestArtEngine_Workspace.git local
./local/scripts/Sync-Workspace.ps1 -Mode Install -WhatIf
./local/scripts/Sync-Workspace.ps1 -Mode Install
./local/scripts/Sync-Workspace.ps1 -Mode Status
```

以上直接调用私库脚本可兼容尚未包含公开薄封装的引擎版本，工作目录仍为 RAEngine 根；有薄封装时可继续使用 `./scripts/Sync-Workspace.ps1`。Install 不覆盖或生成公开AGENTS；暂缺入口的版本显式读取 `local/docs/AgentEntry.md`。引擎仍按原 README/Premake/CMake 配置。确认机器自己的写作输出路径后创建 `local/machine/Paths.md`；文件缺失只阻止依赖它的写作输出，不阻止引擎开发。用户级工具登录、模型配置、用户级 skills 和插件单独安装，不从本私库恢复。停止工程坚果云同步不改变既有外部文章目录，也不代表其同步状态已经验证。

## 同步工具的保证与边界

- 默认 `Status` 只读；`Collect` 从运行副本到私库，`Install` 从私库到运行副本。支持 `-WhatIf`，不自动 git add/commit/pull/push，不读取用户目录凭据。
- 清单只允许 `.agents/skills/` 内逐文件路径与 `.codex/agents/*.toml`；新增文件先审查后加入清单。缓存、配置、临时输出及根 `AGENTS.md` 不在映射范围。没有通配复制整个 `.codex/`。
- `.sync/state.json` 记录上次双方一致的哈希。只允许源方改变、目标方仍为基线时覆盖；首次两边不同、双边修改、反方向更新、已同步文件丢失均阻止写入。先检查完整批次，有冲突时不开始复制。
- 不自动删除。重命名／删除要审查清单、两个副本和 Git 差异后人工处理。解决内容冲突时先保留两份、比较合并，将两边统一到明确版本再同步；不要删 `.sync/` 或使用强制覆盖“解决”冲突。
- 路径遍历、越界映射与符号链接／junction 拒绝；普通云文件标签不等于链接。操作时再次校验内容，I/O 失败保留错误，不宣称跨文件原子事务。多个聊天共享工作区时，只有指定协调者执行 Collect/Install，编辑者先完成相关文件；不要边写文件边同步。
- 私库的 ignore 是第二道边界，不会清理已跟踪文件或历史。每次提交还需检查 `git -C local diff --cached`。历史记录可能包含旧机器证据路径，不能用作当前机器的安装配置；新增机器配置只放 `machine/`，凭据任何仓库都不写。

## Codex 与补充模型共同执行

DeepSeek（文章中称“补充模型”）与 Codex 使用同一套文件与流程，不维护另一份模型专用进度或复制技能。先读根 `AGENTS.md` → `local/docs/AgentEntry.md` → `DevelopmentStatus.md` / `AgentDevelopment.md` → 任务相关 skill 和公开领域说明。切模型不改变工作目录、技能路径或提交归属，也不自动更改 provider 配置。

任务开始检查两个仓库状态及同步 Status；收尾把代码行为写入公开技术说明，把开发过程与经验写入私有 docs，收集 skill／agent 修改。文章按 `ZhihuSeries.md` 与 `ZhihuSeriesLedger.md` 执行，输出路径从本机 `machine/Paths.md` 读取；正式文章与媒体继续在仓库外。没有私库或证据时明确缺失，不能把旧历史记录当作本轮验证。
