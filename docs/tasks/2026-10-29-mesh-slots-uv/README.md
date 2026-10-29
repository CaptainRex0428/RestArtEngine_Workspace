# 多材质 Slot 与最多四套 UV
目标：同一个模型.rasset保存面材质分区及UV0-3，Actor独立绑定，各渲染与拾取路径一致，旧资产兼容。
当前：实现与验收完成，见[v3](v3.md)。18/18 CPU、网格属性GPU、完整Editor、硬件光追、GI与千万面回归通过；常用Debug程序已更新，未提交／推送。基线含其他任务未提交实现，必须保留。
经验入口：[多材质与可选属性](../../experience/MeshAttributes.md)、[大网格缓存](../../experience/MeshPerformance.md)、[资产生命周期](../../experience/AssetLifecycle.md)。

