# Project Settings 依赖与重启反馈

状态：实现、612项配置断言和三模式隔离GUI验收通过；当前完整工程含用户暂停的AA未完成实现，完整集成待其恢复后补验。最新：[v3](v3.md)，[v1](v1.md)、[v2](v2.md)保留失败证据。

目标：显式父选项编辑联动取消依赖/竞争勾选；区分即时特性和保存后重启的启动策略；保留设备降级与加载旧配置时的请求。引擎基线a28f38c，七项Sandbox本地文件保护，不自动提交引擎。

实现由当前聊天直接负责ProjectSettings UI、独立规则和相关测试；构建/GPU串行。经验复用[BackendSelection](../../experience/BackendSelection.md)，收尾补充本次规则与证据。
