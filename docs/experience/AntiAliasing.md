# 抗锯齿与交换链借用

场景：为前向／延迟光栅加入可配置 Off／FXAA／TAA，并在原生 D3D12 上完成启动、窗口 resize、预览隔离和热编译验收。

## 原因与规则

- AA Pass 的输出如果就是调用者目标，不能写入跨帧持久成员。FXAA 曾把 `pass.colors[0].texture` 缓存在 `aaResolvedImage`，非编辑器渲染时该值就是交换链；D3D12 `ResizeBuffers` 要求所有 backbuffer 引用释放，因此编辑器窗口从加载尺寸放大时启动失败。
- TAA 的历史图（RGBA16F，两张 ping-pong）可以持久；FXAA 的目标不行。需要引用最终图像时，按帧从当前目标取，或仅在 capture 边界临时使用。
- 原生 D3D12 resize 顺序：`endRenderPass` → reset 外部 swapchain 句柄 → 释放 UI descriptor／pending 对象借用 → `waitIdle` → `ResizeBuffers`。`pendingObjects_` 可能积累数百个延迟释放对象，不能只依赖每帧清空。
- AA 回退要显式：实时 DXR GI／独立硬件 resolve 请求 TAA 时用 FXAA（GI 历史不能接受逐帧光栅抖动）；Progressive PT 跳过额外 AA；数据视图保留原始像素；离屏工具预览默认 FXAA，不消费主场景 TAA 历史。

## 验证方法

- 正常启动并 resize（加载窗 → 编辑器窗）：退出 0、D3D12 validation 0。
- `--aa-self-test` 分别在 D3D11 与原生 D3D12 运行，质量对照超采样参考，不以“画面变了”代替边缘指标。
- `--aa-ui-self-test` 验证真实 combo、权重、保存往返与双主题截图。
- CTest 与 `--native-d3d12-self-test` 覆盖管线、预览、热编译和 resize。
- 编辑器自测的原生窗口 focus 断言受桌面前台影响；相关代码未变时标为环境竞争，不能当作 AA 回归。

## 边界

未实现 MSAA（需要多采样附件、PSO 采样数和延迟 G-buffer 契约）、HDR 时间重建、运动矢量、Vulkan／OpenGL 验证。TAA 对物体运动、透明和动态变形仍会出现拖影或软化。

来源：[抗锯齿任务 v4](../tasks/2026-11-19-antialiasing/v4.md)；提交 `b142549`。
