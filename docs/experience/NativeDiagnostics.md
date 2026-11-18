# 原生帧检查与程序诊断

来源：[2026-11-18 Inspector任务](../tasks/2026-11-18-native-inspector/README.md)。数据契约以公开[Diagnostics](../../../docs/Diagnostics.md)为准；本页记录可复用判断，不将未实现回放写成已支持。

## 帧身份和测量范围

场景渲染器同帧还会被材质、资产与缩略图预览调用。捕获只在主场景消费请求，异步timestamp保留原Frame ID；冻结捕获只接纳相同Frame ID的返回结果，离线包不能被Live计时更新。CPU时间是插桩wall time，GPU时间是对应主场景队列区间，不能相加或称为全GPU忙碌时间。D3D12中间readback/flush会产生额外提交，query槽必须绑定真正resolve提交的fence，不能借用稍后的通用fence；poll不提交也不等待。四槽压力测试和真实GPU帧检验其行为。混合DXR和UI另有队列/工作，未被此计时覆盖。

## Draw状态须在命令执行时固定

RHI decorator先成功转发，再观察Draw时的PSO/绑定/常量；不能导出时读取同一buffer的最新内容充当以前Draw的值。常量上传与不可变快照分别有预算，超过上限明确标partial；弱引用和Pass结束释放避免观察器意外延长资源生命。Native阶段在Pass边界清理旧快照和Shader名字，否则同一UI中可能出现“绑定不完整，但Shader仍是上个Pass”的错误身份。若未来一个RHI Pass内混入native Draw，需主动invalidate或消费快照，不能假定当前Pass隔离一直有效。单元测试验证转发失败/后续更新/预算/生命周期，GPU专项验证真实section偏移、材质与多版本常量及native Outline状态。

## 原始数据、显示和子资源

D3D11 depth-stencil资源不允许1×1源框copy；冻结纹理即使为typeless，只要带DSV约束仍须整层复制到staging后选像素。v1 CSM原始读回出现非有限值，改用完整copy后通过；不通过放宽数值断言处理。Shadow按真实array layer复制并保留layer元数据，不能把两层都读首层。相机深度用捕获时near/far/projection显示，shadow是light-space raw depth，不能用主相机解码。显示转换不回写raw，像素读取显式触发同步而不挂hover每帧。

分配显示纹理成功不证明转换正确。v2完整Editor发现深度G/B被错误映射为线性深度；v3/v4对两API本地与offline包逐资源回读全部25个RGBA8显示通道，区分RGB灰阶、R映射与G/B/A原存储通道，并保留raw检查。`readCapturedDisplayPixel`专门读取实际GPU转换结果，不能用同一CPU公式自比代替此证据。

## 冻结、预算与事务

捕获是独立资源，不是Live句柄借用。候选全部copy成功后整体替换，预算或读回失败保留上次有效捕获；Before只包含本帧此前已初始化的资源。ImGui draw list可能已经借用旧SRV，Clear/Load/新捕获需要累积退役集合，不能多次替换时覆盖上一个退役集合；在安全主场景边界回收。raw/display预算不等于峰值内存：候选、新旧退役、CPU metadata与临时readback会并存。验证应包含Live改材质、preview、resize、GC、失败事务与真实UI输入，不仅检查结构体。

## 严格JSON校验也会引入性能错误

vendor nlohmann的DOM callback parser在end_object清理父array时可能对全array扫描；即使callback总返回true，65537个空对象仍导致二次方耗时。改为SAX预检重复键/深度/数组数量，再普通无callback DOM解析。保留巨大数组拒绝测试和阶段诊断，不删除“慢测试”或拉长超时；本轮整组metadata从超过200秒降为1.45秒。这个结论针对当前vendor实现，升级后仍须独立测量，不能泛化为所有JSON callback都有此复杂度。

## 离线包和调试工具的证据边界

文件容器先验证长度/预算/校验值，metadata再验证schema/类型/有限值/资源尺寸与状态关系，最后候选发布。错误文件不能抹掉当前快照，原子保存失败不删除原文件。校验和检测意外损坏，不等于签名认证。来源11的包在12显示、来源12在11显示，应检查真实图像并保留origin backend身份，不要求原资产；这证明离线浏览，不证明API replay。

程序调试以真实有界日志、统一线程/帧身份、图形验证与进程memory为基础。进程working set/private bytes、逻辑GPU cache估算、累计RHI创建次数必须分开；仪表盘不能伪造VRAM residency、分配栈或采样CPU profiler。UI测试采用真实控件输入与截图，300px窄工具窗也应可滚动/换行，并保护Live Actor、相机、选择与Undo。截图验收和程序断言各自保留，不把其中一项当成另一项。

ImGui的ImPool条目指针不能跨新table创建长期缓存；记录稳定ID，下一次操作前重新GetByKey，再借用实际Window。v3新增partial选择自测因此访问异常，v4修复fixture后通过，未改生产窗口行为或删除断言。原生跨窗焦点失败先查实际foreground owner/窗口可见enabled；本轮前台为LockApp，无法靠synthetic focus证明OS拖放。可以仅对本次自有HWND用已有helper一次激活，失败保留并明确需要解锁后补验，不尝试解锁、不持续抢焦点、不放宽测试，清理仅限自有fixture进程。
