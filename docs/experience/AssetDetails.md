# 资产详情：Slot 材质声明与环绕预览

场景：用户希望在网格的 Asset Details 窗口里声明材质 Slot，并能以物体为中心旋转查看预览。两者都在编辑器 GUI 层，不改变渲染管线。

## Slot 材质的语义

- 网格的 `MeshMaterialSlot::defaultMaterialId` 是**资产级默认**：Actor 未覆盖该 Slot 时继承；`0` 表示 Actor fallback。Actor 级 Slot 覆盖仍在 Details 面板，优先级更高。
- 声明不是新增几何 Slot。Add/Remove Slot 需要重划分 `MeshSection` 的三角形区间，属于导入器／几何编辑；详情窗口只做已有 Slot 的默认材质绑定。
- 旧式单材质网格没有显式 `materialSlots`；可在首次声明时补一个 `Default` Slot（单 Slot 不需 section），保持旧资产兼容。
- 保存要走容器的完整写入：`makeMeshAssetFile` → `attachThumbnail`（保留原缩略图）→ `writeAssetFile`。不是增量 patch，大网格会阻塞 UI，需要提示。
- Engine Content 只读：显示分配但禁用编辑和保存。
- **刷新陷阱**：保存后 `refreshContent()` 会重建 AssetRegistry 与 AssetLibrary，之前的 `entry`／`mesh` 指针都会失效。保存前复制 AssetId／relativePath，保存后重新 `findMesh`，之后的 UI 不再解引用旧指针。
- 默认材质修改后把预览缓存置为无效即可；几何 key 不变，不需要重传 GPU 网格。

## 居中环绕预览

- 渲染器只负责按 `yaw/pitch/zoom` 从**包围盒中心**取景；编辑器只保存交互状态。这样旋转和缩放天然不会把物体移出画面。
- 预览区域没有独立 ImGui item：用 `IsMouseHoveringRect` + `IsMouseDragging` + `MouseWheel` 处理，双击复位；缓存键必须包含相机参数，否则拖动后还显示旧图。
- 详情窗口从 560 宽的只读卡片变成可编辑网格面板后，默认高度要容纳 Slot/UV；保留手动 resize，25+ Slot 时滚动。

## 验证

- 真实输入自测：`SmokeInput` 必须在第一次使用前 `attach(context)`，否则合成鼠标事件不会进入 ImGui；在预览矩形内拖拽并比较 `readPreviewPixels` 前后像素。
- 布局断言易受滚动条出现导致 `TextWrapped` 多一行影响；先渲染一帧再滚到底，箭头断言才能稳定。
- Slot 序列化用 CPU 往返测试（`makeMeshAssetFile` + `writeAssetFile` + `readMeshAssetFile`）覆盖，避免只依赖 UI 截图。
- CTest 与 editor self-test 同时跑；自测通过不代表用户 398 MB 网格写入耗时已优化。

## 边界

未做 Slot 增删、拖拽材质分配、保存进度／异步写入和旋转持久化。

来源：[任务 v1](../tasks/2026-11-19-mesh-details-slots/v1.md)；提交 `79bf6d0`。
