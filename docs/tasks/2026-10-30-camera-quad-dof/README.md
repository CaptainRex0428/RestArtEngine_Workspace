# 四分屏与景深

目标：在统一相机首版上实现四格视口与可编辑、可保存的景深，并完成实际GPU及编辑交互验收。

状态：已完成实现与验收，见 [v2](v2.md)，保留[v1](v1.md)首轮指标失败证据。[Camera经验](../../experience/Camera.md)已更新。

范围：四格独立相机及输入归属，当前激活格使用主渲染/DXR历史，其余格独立Raster输出；镜头DOF参数、光栅屏幕空间景深、渐进路径追踪薄透镜采样、撤销与v7持久化。多个同时常驻DXR历史不在本轮。

交付：Debug无警告构建，20/20CPU、Camera GPU37次DXR调度、GI1568次调度、完整Editor（含三格正交拾取）均通过，图形错误0。最终两行工具栏视觉微调通过额外构建与16帧实际演示截图验收。公开说明、经验与进度同步；原Projects34文件不变。

入口：artifacts/camera-quad-dof/Open-CameraStudio.cmd（四格）及View-DepthOfField.cmd（景深）；真实截图FourViews.png、DepthOfField.png。无剩余阻塞；后续多路同时常驻DXR历史不属本轮。未提交、未推送。
