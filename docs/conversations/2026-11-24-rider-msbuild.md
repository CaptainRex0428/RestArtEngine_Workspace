# Rider 原生 C++ 编译与开源项目配置（2026-11-24）

引擎基线为 `8f7dd2c`。用户希望多人在不同机器上检出工程后都能构建，当前 Rider 会话恢复是第一项验证。

## 报错发生在哪个阶段

Rider 已枚举 VS 2022，但实际调用旧 .NET Framework MSBuild，导致工程载入时找不到 VC 默认属性文件。切换工具链后，当前 Debug x64 方案中的两个项目均构建成功。原始日志中的版本及告警数量见[本机排障](../tasks/2026-11-24-rider-msbuild/v1.md)。

## 哪些配置要随源码交付

开源仓库保存对 Windows C++ 工具链的要求、检测规则和 Rider 配置模板。生成解决方案时用各台机器的 VS Installer 查询结果填入真实路径，可覆盖不同版本类型和自选安装位置。用户已有的个人覆盖有更高优先级，已有工作区遇到旧错误时需对照 Rider 的实际构建工具。[JetBrains 设置层说明](https://www.jetbrains.com/help/rider/Sharing_Configuration_Options.html)

实施与全新检出的验证范围见[任务记录](../tasks/2026-11-24-rider-msbuild/v2.md)。
