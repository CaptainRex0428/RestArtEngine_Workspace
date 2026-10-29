## 面数统计已分类提交（2026-10-29）

已提交 d7d2fe65f9adf63a3958b5307e8f8840b1143f7f（feat(editor): show scene and post-clipping triangle statistics），仅13个公开源码／测试／技术文档路径，未推送。提交以当时HEAD 2c84e99为父，精确tree 2b2fd9d89071192c13656040eb23f6dfc6f1124e；将本任务增量从Material/Import/frustum/渲染缓存等工作区改动中剥离，用独立index和HEAD导出源码验证后提交。独立Debug构建通过，完整editor-self-test退出0、29 geometry cases全PASS、D3D11错误0，证据 artifacts/triangle-statistics/commit-validation/；对应产物 build/triangle-statistics-commit/Debug/RestArtEngine.exe。先前31case是混合其他任务CPUfrustum的集成证据，提交树本身只含GPU裁剪统计、不含CPUfrustum。提交过程77个已记录工作文件字节未变，真实暂存区已按这13路径同步，其他dirty保留。详细提交结果见 artifacts/triangle-statistics/commit-result.json。

# 场景与视口三角面数交付（2026-10-29）

用户目标：统计场景总体三角面数与视口裁剪后的三角面数。已实现，未提交／推送。

行为与边界：Scene Overview、视口只读叠加和Profiler显示同一主场景快照；场景按Actor实例累加indices/3，包含隐藏与缺材质实例，排除未引用资产和缺失mesh。GPU独立四槽PIPELINE_STATISTICS仅围Forward/GBuffer主geometry，异步DONOTFLUSH，不包括阴影/outline/fullscreen/preview；sample frame独立，Pending/Unavailable/NoViewport/N/A不伪造0。纯硬件成图N/A，Realtime GI的主光栅有效。裁剪可拆面增加输出，非深度遮挡后可见面。

文件归属：新增SceneGeometryStatistics.h和GeometryStatistics.inl；SceneRenderer接线；ViewportInteraction/DiagnosticsPanel显示；SceneEditor Overview；DiagnosticsSmoke定向GPU用例；EditorSmoke以raw scene target比较材质/outline，Gizmo仅比较中央区域，避免统计HUD异步文字造成误报/假阳性。三篇公开技术文档已同步。

最终验证：从固定源码快照 artifacts/triangle-statistics/candidate 构建，命令 cmake --build build/triangle-statistics-verified --config Debug --target RestArtEngine --parallel 4 -- /nodeReuse:false，退出0。可执行文件 build/triangle-statistics-verified/Debug/RestArtEngine.exe，SHA256 4ABDCEB9CA4048273C0FF9E90BB62DF054F64495484865B999ABF520967C6275（若文件后续变化以现场hash为准）。--editor-self-test 使用HEAD Sandbox导出的隔离工程、固定candidate引擎/Shader根和独立工作目录。

最终 artifacts/triangle-statistics/delivery/smoke.log 退出0，diagnostics/diagnostics-report.json passed=true，31条geometry case全部PASS、gpuReady=true，RTX5060，D3D11 validation errors=0。覆盖Fwd/Deferred、CPU视锥开启时scene2/input0/post0、禁用时2/2/0、共享mesh重复4/4/4、隐藏4/2/2、空场景0、缺材质2/0/0、shadow/outline排除、Profiler关闭、两个工具预览隔离、隐藏viewport、resize旧样本失效、near-plane 1→2、纯hardware N/A、Realtime GI有效。完整材质/拖放/Gizmo/停靠/诊断/导入回归通过；实际检查Scene+HUD与双主题Profiler截图。23个原Projects文件SHA256前后不变；主bin用户进程未关闭、未覆盖。没有Release或其他后端运行声明。

过程记录：首构建正遇并行MeshQuery模块未接入链接，配置由其任务补齐后重建。run-01旧截图比较被HUD变化干扰，改raw target读回，不放松画面等式；run-02已完整通过。随后并行材质任务在编译中用Cull/ZTest/ZWrite替换Two-sided，final/final-retry混合了旧EditorSmoke.obj与新SceneEditor.obj，旧ID1238191156由只读审查精确确认，故使用固定源码快照。快照中另一任务的near/far宏命名错误通过同步其已修复的nearPixel/useFarSurface文件解决。verified首轮缺少新cull/depth raw前缀，已同步源中的正确覆盖；verified-final显示另一任务新增CPU frustum默认开启，使outside input从2变0，已同步其开启/关闭双用例，GPU post均0；delivery最终31项全过。上述原始失败均保留，未删除断言。

并行改动：RaySceneInput/geometryKey/MeshQuery/frustum、FBX导入、材质Cull/ZTest/ZWrite、Shader及用户Sandbox改动均来自其他任务，保留。公开源文件不能整文件暂存；将来若提交本聊天，依照baseline与任务增量逐hunk甄别。运行skills/agents未改，不需要Collect。临时原始证据和源码快照只在artifacts，不进入两个Git仓库。
