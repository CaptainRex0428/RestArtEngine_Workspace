# RestArtEngine Workspace

RestArtEngine 的**私有开发协作仓库**，保存项目 skills、agent 定义、开发规范、进度、经验与 DevLog 底稿。仓库地址为 [CaptainRex0428/RestArtEngine_Workspace](https://github.com/CaptainRex0428/RestArtEngine_Workspace)，主分支为 `main`，必须保持 **Private**。

本仓库放在引擎目录的 `local/` 中，是独立 Git 仓库。引擎源码由 [RestArtEngine](https://github.com/CaptainRex0428/RestArtEngine) 管理；两边分别提交、拉取、推送。本仓库不是 submodule，不参与引擎构建或发行。工程不再依赖坚果云同步。

**始终在 RAEngine 根目录打开 IDE、终端和聊天。** Skills 仍从 `.agents/skills/` 调用，agents 仍由 `.codex/agents/` 发现，现有名称和调用方式不变。`workspace/` 只是 Git 存储副本，不是运行入口。

## 目录与内容归属

```text
RAEngine/                           引擎仓库与日常工作目录
├─ AGENTS.md                        公开轻量入口，读取私有 AgentEntry
├─ scripts/Sync-Workspace.ps1        公开同步薄封装
├─ .agents/skills/                  原技能运行目录，引擎 Git 忽略
├─ .codex/agents/                   原角色运行目录，引擎 Git 忽略
└─ local/                          本私有仓库
   ├─ .git/
   ├─ README.md
   ├─ docs/                        直接编辑的规范、进度与底稿
   ├─ workspace-manifest.json       逐文件同步清单
   ├─ workspace/.agents/skills/    技能版本化副本
   ├─ workspace/.codex/agents/     角色版本化副本
   ├─ scripts/                    同步实现与隔离测试
   ├─ .sync/                      本机比较基线与锁，不提交
   └─ machine/Paths.md             当前机器路径，不提交
```

| 内容 | 存放与同步方式 |
| --- | --- |
| 引擎源码、构建配置、公共技术说明 | 引擎仓库；不复制到本仓库 |
| 通用调用入口 | 引擎根 `AGENTS.md` 与公开同步薄封装可进入引擎库 |
| 完整协作规范、开发进度、经验、写作底稿 | 本仓库 `docs/`，直接编辑并提交 |
| 项目 skills、agent 定义与技能辅助脚本 | 原运行目录编辑，通过 Collect 收集到 `workspace/` |
| 凭据、provider 配置、用户级工具配置、聊天数据库 | 不进入两个仓库，不由同步脚本读取或安装 |
| 本机路径、同步状态、缓存、构建输出、原始测试日志 | 本机忽略目录；不能把忽略当成备份 |
| 正式文章、截图、GIF、视频与 PSD | 既有外部资料目录，单独管理，不随本仓库同步 |

## 新电脑安装

需要 Git、可用的 GitHub 私库访问权限，以及 PowerShell 7 或 Windows PowerShell 5.1。认证通过 Git 凭据工具完成，不将 token 写入仓库、URL 或脚本。

以下命令在新目录执行。若目标 `local/` 已有资料，先检查并合并，不能直接覆盖或清空。

```powershell
git clone https://github.com/CaptainRex0428/RestArtEngine.git RAEngine
Set-Location RAEngine
git clone https://github.com/CaptainRex0428/RestArtEngine_Workspace.git local

# 所有后续命令仍在 RAEngine 根执行
./local/scripts/Sync-Workspace.ps1 -Mode Install -WhatIf
./local/scripts/Sync-Workspace.ps1 -Mode Install
./local/scripts/Sync-Workspace.ps1 -Mode Status
```

直接调用 `local/scripts/` 可兼容尚未带公开同步薄封装的引擎版本；已有薄封装时也可使用 `./scripts/Sync-Workspace.ps1`，行为相同。Install 不生成或覆盖公开 `AGENTS.md`。若引擎版本暂缺该入口，在聊天中显式读取 `local/docs/AgentEntry.md`；后续采用含公开入口的引擎版本即可自动接入。

安装后确认原 `.agents/skills/` 与 `.codex/agents/` 文件存在。客户端未刷新发现列表时重新打开会话。引擎编译仍按引擎 README 执行，完全不依赖此私库。

本机文章输出路径单独写入忽略的 `local/machine/Paths.md`。缺少该文件时先确认本机路径；不要复制历史记录中的绝对路径。写作前仍须确认目标目录有 `head.png` 和 `head.psd`。

## 日常操作

| 命令模式 | 用途 |
| --- | --- |
| `Status`（默认） | 只读比较运行副本、私库副本及上次同步基线 |
| `Collect` | 将运行目录的 skills／agents 改动收集到私库 |
| `Install` | 将私库中的版本安装到原运行目录 |
| `-WhatIf` | 预演 Collect／Install，不写文件或同步状态 |

**开始工作前**，先查看状态；有运行副本改动时先 Collect 并审查、提交，再拉取私库：

```powershell
git status --short
git -C local status --short
./local/scripts/Sync-Workspace.ps1 -Mode Status

# 仅在存在待收集的运行副本改动时执行
./local/scripts/Sync-Workspace.ps1 -Mode Collect
# 有私库改动时先按下方流程提交，随后拉取
git -C local pull --ff-only
./local/scripts/Sync-Workspace.ps1 -Mode Install
```

引擎自身按其工作区状态独立拉取；私库更新不会更新引擎代码。合并或切换版本后，核对开发记录引用的引擎 commit 与实际源码。

**完成工作后**，将进度、经验及待办写回私库 docs；skill／agent 在原运行目录修改后执行 Collect，再审查并提交：

```powershell
./local/scripts/Sync-Workspace.ps1 -Mode Collect
git -C local status --short
# 按本次任务选择明确路径；下面是完整协作资料范围示例
git -C local add -- README.md .gitignore .gitattributes workspace-manifest.json docs scripts workspace
git -C local diff --cached --check
git -C local diff --cached --stat
git -C local diff --cached
git -C local commit -m "Update development workspace"
git -C local push
```

同步脚本不自动提交或联网；只有 push 成功的提交才在远端。不要在引擎根强制添加 `local/`、`.agents/` 或 `.codex/`。两个仓库的提交和推送范围分别核对。

## 冲突与删除

同步基线位于忽略的 `.sync/state.json`。首次两侧内容不同、双方都修改、覆盖方向错误或已同步文件缺失时，工具先阻止整批复制，不提供强制覆盖开关。

遇到冲突时保留两份文件，比较并合并内容，确认需要的版本后将两侧统一，再重新运行同步。不要通过删除 `.sync/`、reset/clean 或直接覆盖来绕过冲突。Git 拉取分叉也按普通合并流程解决，不强推。

工具不传播删除。新增文件需审查并加入 `workspace-manifest.json`；删除或改名需同时核对清单、运行副本和私库副本。多个聊天共享工作区时，由一个协调者在文件编辑完成后执行同步。

每个文件使用独立临时文件发布和哈希校验；发生 I/O 故障时可能已有部分文件复制，不能把它当成跨文件原子事务，应先 Status 再处理。

## Codex 与补充模型共用的阅读顺序

1. 引擎根 `AGENTS.md` → [私有入口](docs/AgentEntry.md)。
2. [开发状态](docs/DevelopmentStatus.md)与[协作规范](docs/AgentDevelopment.md)。
3. 本任务对应的原运行目录 skill，以及引擎的公开领域文档和源码。
4. 写作任务额外读取[知乎规范](docs/ZhihuSeries.md)、[底稿](docs/ZhihuSeriesLedger.md)与本机输出路径。

Codex 与 DeepSeek（文章中称“补充模型”）使用同一份进度和规范，不按模型复制文档，不因切换模型而改变目录或 provider 配置。历史 PASS、截图路径或旧机器路径不能冒充当前机器的验证；原始证据没有随本库上传时须明确说明。

## 验证与详细规范

在引擎根执行隔离测试：

```powershell
pwsh -NoProfile -File local/scripts/Test-WorkspaceSync.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File local/scripts/Test-WorkspaceSync.ps1
```

测试创建独立临时夹具，覆盖安装／收集、双侧冲突、删除保护、WhatIf、非法路径、链接与锁竞争，不操作真实工程的技能内容。

- [同步设计与换机说明](docs/WorkspaceSync.md)
- [公开／私有／仅本机内容边界](docs/RepositoryPolicy.md)
- [文件位置索引](docs/LocalDevelopmentGuide.md)

本库中的 `docs/` 按安装到引擎 `local/` 后的相对路径引用公开源码或运行 skills；部分跨仓库链接只在完整本地工作区可达。`workspace/` 中的技能引用也按其安装后的原位置解析。
