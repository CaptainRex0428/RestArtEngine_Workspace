# Rider 报告缺少 VC 默认属性文件

同一解决方案中的多个 `.vcxproj` 在导入 `Microsoft.Cpp.Default.props` 时同时报 MSB4019，先在 Rider 的 Build Output 中找到 `Use build tool` 和 MSBuild 版本，再对照生成工程的 `VCTargetsPath` 导入与 `PlatformToolset`。驱动器根目录加文件名往往说明属性展开为空。检查 VS 安装实例里相应文件是否存在，可以区分工具链选择错误与组件缺失。

需要支持其他机器时，以解决方案生成器为入口，根据 VS 大版本、MSBuild、目标 CPU 和 C++ 工作负载匹配安装实例。VS 的版本类型和安装盘符都可能变化。Rider 分别读取解决方案层与个人覆盖层，验证时使用没有个人覆盖的检出，观察 IDE 实际工具路径，再构建至少一个原生目标。用显式路径在命令行构建可以检查工具本身，IDE 选择仍需单独取证。

本经验覆盖 Windows 上的 VS 2022、v143 和 Rider 原生 C++ 项目。原始症状、两轮处理及验收见[工具链任务](../tasks/2026-11-24-rider-msbuild/README.md)。
