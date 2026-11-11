# 2026-11-11 RHI 管线绑定契约反射校验

状态：通过（本轮切片）
引擎基线：`1bb5110` + 本轮工作区改动
协作库基线：`main`（本轮未同步）

## 目标

补上审计中挂起的缺口：`IRenderBackend::createPipeline` 只验证编译，不验证 shader 的绑定是否与调用方声明的 `t0..tN / s0 / b0` 契约一致。目标是让错误的绑定在管线创建阶段失败，并让 DX11 与 DX12 报同样的错。

## 结果摘要

- `RhiPipelineDesc` 增加 `sourceCount` 与 `constantBufferSize`。
- DX11 用 `D3DReflect`、DX12 用 `IDxcUtils::CreateReflection`，共用同一校验函数。
- `SceneRenderer` 七条后处理管线补齐真实声明；`BackendSmoke` 增加负例与真实 shader 双 API 检查。
- 验证：Debug 构建无 warning；`--backend-self-test`、`--taa-self-test`、`Validate-Render.ps1` 全部 PASS。

## 未完成

- 反射只覆盖源码级绑定，不验证运行时 descriptor / root signature 绑定。
- `BackendTests` CPU 套件本轮未运行（未配置 CMake）。
- DX12 场景共享接入与调试视图 RHI 化仍未开始。

## 证据

- `artifacts/backend-reflect/`、`artifacts/reflect-regression/`、`artifacts/taa-reflect/`
- 详见 [v1.md](v1.md)。
