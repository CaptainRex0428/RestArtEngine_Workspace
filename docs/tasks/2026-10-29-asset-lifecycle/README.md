# 资产重新导入与删除

状态：已完成并提交 `eee716d`，未推送；[v1](v1.md)、[独立提交验收](commit.md)。常用程序保留现有工作区版本。

目标：Content 中从原路径重新导入、选择新的源文件重新导入，以及删除项目资产。重新导入保持 GUID、名称和目标路径，已有 Actor 引用保持；删除保护场景引用、Engine 和项目必要资源。源文件不修改。

分工：backend 负责 AssetImport 与新增 AssetOperations；GUI 负责 SceneEditor、ImportSmoke；测试负责 AssetLifecycleTests；主协调负责构建入口、文档、集成验收。

验收：14/14 CTest、完整隔离 editor-self-test、同 GUID 几何的 GPU 前后画面、两主题列表／网格菜单及删除弹窗通过。新源路径执行服务已验证，原生文件选择窗口本身尚未自动化操作。未提交／推送。
