# Rider 编译原生 C++ 项目时找不到 Microsoft.Cpp.Default.props

目标为开源项目的 Windows 构建。安装 VS 2022 C++ 工具后，贡献者应能运行 `scripts/GenerateWIN.bat`，打开生成的解决方案并直接构建 Debug x64。

- [v1 本机排障](v1.md)记录 MSB4019 的原因和 Rider 首次成功构建。
- [v2 跨机器生成配置](v2.md)在另一盘符的全新检出上通过。未带 Rider 个人设置，由生成配置选出 MSBuild，命令行全量构建 Debug x64，0 错误。实际验证使用一台 Windows 机器。
- [讨论结论](../../conversations/2026-11-24-rider-msbuild.md)和[工具链排查经验](../../experience/RiderMsBuild.md)。
