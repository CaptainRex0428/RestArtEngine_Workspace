# RHI首个切片的完成边界澄清（2026-11-18）

状态：讨论记录，不含新增实现授权；引擎代码改动：否。
参与：用户、Codex。
基线：引擎HEAD14a6b0d + 本聊天未提交M1/M2；协作记录ce8e477。
关联：[M2任务](../tasks/2026-11-18-rhi-slice/README.md)、[概念说明](../learning/PassGraphRhiRelationship.md)、[后端规范](../../../docs/RenderBackends.md)。

## 背景

用户询问交付中的“原生D3D12主后端尚未实现，UI/部分后处理/捕获仍有原生调用；RenderDoc捕获未实测”是什么意思。交付用同一“原生”描述了两种不同概念，应明确API与调用层级。

## 问题与结论

1. 原生D3D12主后端：整个主渲染与呈现由D3D12执行，不依赖D3D11主设备。现有D3D12/DXR模块只执行混合模式光追并回传结果，不等于该主后端；该模式目前依配置严格回退11或启动报错。
2. 剩余原生调用：指UI、Outline、DOF、capture/readback等还直接调用D3D11，绕过新RHI；不表示它们已走D3D12，也不表示功能不可用。主场景几何、阴影、Forward/Deferred已经经RHI→D3D11执行。RHI目前只有实际D3D11实现，不能自动将现有命令翻译成已完成的D3D12后端。
3. RenderDoc未实测：已加可用的资源名称/Pass事件，且独立GPU和Frame Inspector自测通过；没有实际用RenderDoc附加、捕获、打开并逐Pass检查。不能由内部Inspector通过推断外部RenderDoc通过，也不能据“未测”断言工具不支持。

## 方案与取舍

保持严格11和11+12/DXR混合两种实际可用模式；纯12仍待实施。后续补齐RHI资源/绑定/copy/readback/呈现等所需契约与适配，再推进独立12闭环；渲染功能验收与外部工具捕获单列。这是已有阶段方案的边界澄清，本轮不新增运行时代码。

## 未决问题

原生12、余下RHI迁移和实际RenderDoc捕获继续按已有方案实施；没有新增技术选型或用户审批请求。

## 证据与同步

范围以M2 v1-v3、Rhi.h、SceneRenderer、D3D11Rhi及RenderBackends为准；本轮只核对记录，无新GPU结果。更新学习说明与状态链接后单独提交推送协作库；引擎工作树保留。
