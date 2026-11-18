# 实际 RHI 切片 M2

目标：D3D11 实际执行 typed resource/graphics pipeline/attachment pass/draw，并保留严格11、混合DXR及12请求回退的M1行为。

状态：本轮主场景RHI切片验收通过；Debug无告警、CTest24/24、13张迁移前后图字节一致、专项GPU与完整Editor均通过。

- [v1](v1.md)：首次集成、WARP回读和启动矩阵。
- [v2](v2.md)：审查后的失败恢复、最终构建、13张旧新图字节一致、217次完整HRT及最终相机／材质状态／UV／GC专项。
- [v3](v3.md)：Editor测试需要项目.rasset材质，改用Git已提交Sandbox隔离夹具，最终全套与Diagnostics通过，exit0/errors0；保留首次失败证据。

实际执行范围见[公开说明](../../../../docs/RenderBackends.md#实际-rhi-执行范围)，可复用判断见[RhiMigration](../../experience/RhiMigration.md)。

边界：不包括原生D3D12主后端、完整Render Graph、全生命周期和所有后处理／编辑器资源迁移。RenderDoc实际捕获、设备丢失、可控resize失败故障注入未验收。用户Sandbox资产不修改。引擎代码本轮未提交；协作记录收尾单独同步。
