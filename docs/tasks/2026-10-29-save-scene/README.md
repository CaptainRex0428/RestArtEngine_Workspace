# Save Scene 无响应

目标：已有大模型的项目保存小场景时，不再重复处理未变的整个模型库，同时保持保存、重载、失败重试正确。

状态：当前 [v5](v5.md) 已实现并验证场景／资产保存职责分离。Save／Save As 仅场景；Save material asset 仅选定材质；Save All 汇总保存。12/12 CTest、完整编辑器自测、未保存状态／依赖缺失／新建失败恢复通过；常用 bin 已更新。前版 [v1](v1.md)、[v2](v2.md)、[v3](v3.md)、[v4](v4.md) 保留原始结果。

历史 v4 结果：Debug 无警告构建、11/11 CTest、完整编辑器自测及保存专项通过，D3D11 errors=0；R8 未引用的保存由约 78～89 秒降到约 6 毫秒（保存函数计时）。v5 不将这组历史数字当作当前新测量。公开 Architecture／AssetFormat／EditorGuide、进度与经验已同步；用户 Sandbox 14 个文件在测试前后数量／哈希不变。

经验入口：[大网格性能](../../experience/MeshPerformance.md)。本轮尚未提交／推送。
