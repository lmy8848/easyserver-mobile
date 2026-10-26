# DevBoard Qt 重构计划（方案 B：Qt 壳 + scrcpy 协议）

> 状态：评审通过 ｜ 版本：v1.1 ｜ 日期：2026-10-26
> 目标产物：`tools/devboard-qt/`（新），`tools/devboard/`（Flutter 版冻结保留）
> UI 规范：见 [UI.md](UI.md)（布局/交互/快捷键/状态机，实现以其为准）

---

## 1. 背景与目标

### 1.1 为什么要重构

现有 DevBoard 是 Flutter Windows 桌面应用，镜像方案经历了三轮尝试，均触及硬约束：

| 方案 | 结果 | 硬约束 |
|---|---|---|
| adb screenrecord → ffmpeg → media_kit(mpv) 纹理 | 能出画，但延迟 200-300ms、输入靠 `adb shell input`（每次约 50ms） | 多一跳转封装；输入无多点/滚轮 |
| scrcpy 原生窗口 SetParent 内嵌 | 真嵌入但**悬停必闪**、画面不随窗口缩放 | Flutter 用 D3D 交换链，外部 SDL/D3D 窗口属 airspace 冲突；reparent 后 SDL swapchain 不再重算尺寸 |
| scrcpy 归属窗口（owned window）覆盖 | 不闪，但**拖动主窗口会脱节** | 本质是覆盖层，不是子窗口 |

结论：**只要视频源是"别人的窗口"，在 Flutter 里就不可能同时做到真嵌入 + 不闪 + 等比缩放。**
唯一干净的出路是让视频成为本进程自己的绘制内容，并且直接从 scrcpy-server 取流，省掉中间转封装。

### 1.2 目标

- 镜像质量与 scrcpy 对齐：端到端延迟 < 100ms、60fps、任意窗口缩放等比显示
- 输入走 scrcpy control socket：支持多点触控、滑动、滚轮、按键、文本
- 保留现有 DevBoard 的全部开发辅助能力（adb 终端 / logcat / 设备信息 / APK 操作 / 无线配对 / 自动重连）
- 单一进程、单窗口、无"覆盖层"技巧

### 1.3 非目标

- 不做跨平台（先只做 Windows；架构上预留 macOS/Linux，但本期不验证）
- 不改动主 App `easyserver_mobile`
- 不重写 scrcpy 本体，只实现**协议客户端**

---

## 2. 范围与功能对照

| 现有功能（Flutter） | Qt 实现 | 阶段 |
|---|---|---|
| 设备列表 / chip 切换 / 刷新 | `DeviceBar` + `AdbClient::devices()` | M0 |
| 无线配对向导（配对码 + connect） | `PairWizardDialog` | M4 |
| 无线掉线自动重连 | `ConnectionWatcher`（3s 轮询 + 上次目标持久化） | M4 |
| 实时镜像 | `MirrorView`（scrcpy-server 直连） | M1-M3 |
| 抓帧模式（降级） | `SnapshotView`（adb exec-out screencap） | M4 |
| 返回/主页/多任务/电源 | control socket `INJECT_KEYCODE` | M3 |
| 点按 / 滑动 / 发送文本 | control socket `INJECT_TOUCH_EVENT` / `INJECT_TEXT` | M3 |
| adb 终端 | `TerminalPanel`（QProcess 交互式 shell） | M4 |
| logcat | `LogcatPanel`（QProcess 流式 + 过滤 + 暂停） | M4 |
| 设备信息（型号/系统/ABI/分辨率/DPI/电量） | `DeviceInfoPanel` | M4 |
| 安装/卸载/列出应用/截图/录屏 30s | `ActionsPanel` | M4 |

**丢弃**：Flutter 相关依赖（media_kit / ffmpeg 转封装 / win32_embed），以及所有 `SetParent` 相关代码。

---

## 3. 目标架构

### 3.1 运行时拓扑

```
┌──────────────────────────── DevBoard.exe (Qt) ────────────────────────────┐
│  UI 线程                                                                  │
│   ├─ MainWindow ── DeviceBar / MirrorView / SidePanels / StatusBar        │
│   └─ MirrorView：QOpenGLWidget，只负责把最新 VideoFrame 画成纹理          │
│            ▲ 每帧 post 一个 frame（三缓冲，丢旧帧）                        │
│  解码线程（独立 QThread）                                                  │
│   └─ H264Decoder (libavcodec) → YUV420P → 上传到 GL 纹理                  │
│            ▲ AVPacket 队列（有界，丢非关键帧保低延迟）                      │
│  IO 线程（QThread）                                                        │
│   ├─ VideoSocket：读 12 字节帧头 + payload → AVPacket                     │
│   └─ ControlSocket：写触摸/按键/滚轮/文本消息                              │
└───────────────┬──────────────────────────────────┬────────────────────────┘
                │ tcp://127.0.0.1:<port> (forward) │
        ┌───────▼────────┐                 ┌───────▼────────┐
        │ adb server     │                 │ adb server     │
        └───────┬────────┘                 └───────┬────────┘
                │ localabstract:scrcpy             │
        ┌───────▼──────────────────────────────────▼────────┐
        │ 设备端 scrcpy-server (Java, app_process 启动)      │
        │  MediaCodec 硬编 H.264  ← SurfaceControl 抓屏      │
        └───────────────────────────────────────────────────┘
```

要点：
- **不需要 ffmpeg.exe**，也不需要 SDL —— 视频直接进本进程解码
- 设备端只有一个 Java 进程（scrcpy-server），随连接建立/断开
- 客户端只占用两个本地 TCP 端口（`adb forward` 分配）

### 3.2 模块划分

```
tools/devboard-qt/
├── CMakeLists.txt
├── cmake/                        # 依赖查找、windeployqt、资源拷贝
├── third_party/                  # scrcpy-server jar（随包分发，锁定版本）
├── src/
│   ├── main.cpp
│   ├── core/                     # 与 UI 无关，可单测
│   │   ├── AdbClient.{h,cpp}         # adb 路径解析、devices、shell、push、forward
│   │   ├── AdbProcess.{h,cpp}        # QProcess 封装（超时/取消/编码）
│   │   ├── ScrcpyServer.{h,cpp}      # 启动/停止 server、参数拼装、端口分配
│   │   ├── VideoSocket.{h,cpp}       # 握手 + 帧头解析
│   │   ├── ControlSocket.{h,cpp}     # control 消息序列化
│   │   └── DeviceModel.{h,cpp}       # 设备状态、连接目标持久化
│   ├── media/
│   │   ├── IDecoder.h                # 解码器抽象（软解/硬解可换）
│   │   ├── FfmpegDecoder.{h,cpp}     # libavcodec 软解
│   │   ├── VideoFrame.h              # YUV420P 平面 + 尺寸 + pts
│   │   └── FrameQueue.{h,cpp}        # 有界队列，满则丢旧帧
│   ├── ui/
│   │   ├── MainWindow.{h,cpp}        # QML 引擎装载 + C++ 类型注册
│   │   ├── qml/                      # Main.qml / DeviceBar / MirrorPage / SidePanels
│   │   ├── MirrorView.{h,cpp}        # QOpenGLWidget + YUV shader
│   │   ├── DeviceBar.{h,cpp}
│   │   ├── SidePanels.{h,cpp}        # QTabWidget
│   │   ├── TerminalPanel.{h,cpp}
│   │   ├── LogcatPanel.{h,cpp}
│   │   ├── DeviceInfoPanel.{h,cpp}
│   │   ├── ActionsPanel.{h,cpp}
│   │   ├── PairWizardDialog.{h,cpp}
│   │   └── SnapshotView.{h,cpp}
│   └── app/
│       ├── MirrorController.{h,cpp}  # 编排：server→socket→decoder→view 的状态机
│       └── ConnectionWatcher.{h,cpp} # 自动重连
└── tests/
    ├── test_framing.cpp              # 帧头解析 golden test
    └── test_control_msg.cpp          # control 消息字节序 golden test
```

### 3.3 线程模型与背压

| 线程 | 职责 | 队列策略 |
|---|---|---|
| UI 线程 | 渲染、事件 | `MirrorView` 只取最新帧（三缓冲） |
| IO 线程 | 读 video socket、写 control socket | 读循环阻塞等待，不缓冲 |
| 解码线程 | `avcodec_send_packet` / `receive_frame` | 输入队列容量 3；满了丢**非关键帧**（保证低延迟优先于完整性） |

原则：**任何环节都不允许无限缓冲**。延迟优先，卡顿次之。

---

## 4. 技术选型

| 项 | 选择 | 理由 |
|---|---|---|
| 语言 | C++17 | Qt 6 + FFmpeg 生态成熟 |
| UI 框架 | **Qt Widgets**（非 QML） | 现有面板是表格/终端/表单类，Widgets 更快落地；QML 的收益主要在动效 |
| Qt 版本 | Qt 6.5 LTS，LGPL 动态链接 | 内部工具，动态链接即可合规 |
| 构建 | CMake 3.21+ / MSVC 2022 | Qt 6 官方构建方式，便于 CI |
| 依赖管理 | vcpkg（ffmpeg 静态裁剪）或系统 FFmpeg | 见 §9 风险 |
| 解码 | **libavcodec 软解**（M1-M3），M5 评估 D3D11VA | 软解兼容性最好，1080x2400 单路 CPU 约 10-15%，先保证可用 |
| 渲染 | `QOpenGLWidget` + YUV420P→RGB shader | 避免每帧 `QImage` 转换（那是 1080x2400 每帧 10MB 拷贝） |
| 输入 | scrcpy control socket | 延迟 <5ms，支持多点/滚轮，这是选 B 的核心收益 |
| 打包 | `windeployqt` + 资源目录 | 单目录绿色分发 |

---

## 5. 关键设计决策（ADR）

**ADR-001｜用 scrcpy-server 直连，不用 `screenrecord` + ffmpeg**
- 决策：客户端自己拉起 `scrcpy-server`，直接读 video socket。
- 理由：省掉一次进程间转封装（ffmpeg），延迟从 ~250ms 降到 ~80ms；输入可走 control socket。
- 代价：与 server 协议版本耦合，需锁定 jar 版本（见 ADR-006）。

**ADR-002（v1.1 修订）｜Qt Quick（QML）+ Material 深色风格，替代 Qt Widgets**
- 修订原因：产品要求更丰富的 UI 表现（现代观感/动效/圆角组件）。Qt Quick Controls 2
  开箱提供 Material 主题、Chip/Tab/Sheet 等现代组件与动画，最贴近目标观感。
- 镜像渲染：自定义 QQuickItem，在 scene graph 中以 YUV 三平面纹理 + shader
  上屏（与 QOpenGLWidget 同等性能路径，无每帧 QImage 拷贝）；C++ 后端核心
  （AdbClient/ScrcpyServer/VideoSocket/ControlSocket/FfmpegDecoder）完全不变。
- 代价：QML 与 C++ 边界需要暴露类型注册；原 M2 的 QOpenGLWidget 方案改为
  QQuickItem 方案（工作量相当）。
- 依赖补充：qtdeclarative/qtshadertools（随 Qt 套件自带）。

**ADR-003｜解码器抽象为 `IDecoder`，软解优先**
- 理由：硬解在不同 GPU/驱动上行为不一（尤其 1080x2400 非标分辨率），先用软解保证可用；M5 再加 `D3D11Decoder` 并在设置里可切换。
- 约束：`IDecoder` 只暴露 `feed(packet)` / `takeFrame()`，不泄漏 FFmpeg 类型到 UI 层。

**ADR-004｜视频用 OpenGL 纹理渲染，不用 QLabel/QImage**
- 理由：`QImage` 路径每帧一次大内存拷贝 + 格式转换，60fps 下 CPU 直接吃满。
- 做法：三个 `GL_LUMINANCE` 平面纹理（Y/U/V），片元着色器做 BT.601/709 转换；`QOpenGLWidget` 的 `paintGL` 里只画一个全屏 quad，等比缩放靠 viewport。

**ADR-005｜control socket 独立线程 + 事件合并**
- 理由：触摸移动事件频率高（120Hz），不能和视频读循环抢线程。
- 做法：UI 事件进环形队列，写线程按序发送；连续 MOVE 事件可合并（保留最后一点）。

**ADR-006｜scrcpy-server 版本锁定并随包分发**
- 决策：`third_party/scrcpy-server` 固定 2.7，`ScrcpyServer` 中常量 `kServerVersion = "2.7"`，启动参数里的版本号必须与 jar 一致，否则 server 拒绝启动。
- 升级流程：换 jar → 改常量 → 跑 `tests/test_framing` + 手工回归。

---

## 6. 分阶段实施计划

> 每阶段结束必须**可运行、可验收**，不允许"半成品合并"。

### M0 骨架与 adb 层（1-2 天）
- CMake 工程 + Qt 主窗口（左右分栏 + 状态栏）
- `AdbClient`：路径解析（优先随包 `bin/scrcpy27/adb.exe`）、`devices -l`、`shell`、`push`、`forward`
- `DeviceBar`：设备列表、刷新、当前设备切换
- **验收**：能列出无线/USB 设备，切换设备后标题栏更新

### M1 取流与首帧（2-3 天）
- `ScrcpyServer`：push jar → 启动 `app_process` → `adb forward` → 连接 video socket
- `VideoSocket`：先建 video 连接**再建 control 连接**（少一条服务端就不发数据，见附录 A.2），然后解析 1 字节 dummy + 64 字节设备名 + 4 字节 codec + 4 字节宽 + 4 字节高
- `FfmpegDecoder`：低延迟配置（`AV_CODEC_FLAG_LOW_DELAY`、`thread_count=1`）
- 首帧先用 `QImage` 显示（临时，M2 替换）
- **验收**：点击"连接"后 **1.5s 内出现首帧**，画面随手机操作变化

### M2 渲染与布局（2 天）
- `MirrorView`：`QOpenGLWidget` + YUV shader + 等比缩放（letterbox 由布局算，不留黑边）
- DPI 适配、窗口缩放/最大化、全屏
- **验收**：窗口任意缩放画面等比跟随、无闪烁、CPU < 15%

### M3 输入通道（2 天）
- `ControlSocket`：`INJECT_TOUCH_EVENT`（含多点）、`INJECT_KEYCODE`、`INJECT_SCROLL_EVENT`、`INJECT_TEXT`
- 坐标换算：Widget 逻辑坐标 → 设备像素（按视频显示区域等比映射）
- 底部按键条（返回/主页/多任务/电源）+ 文本输入框
- **验收**：点按/滑动/滚轮/打字全部生效，点击响应 < 80ms

### M4 功能补齐（3 天）
- `TerminalPanel`（交互式 adb shell）、`LogcatPanel`（流式 + 过滤 + 暂停）
- `DeviceInfoPanel`、`ActionsPanel`（安装/卸载/列应用/截图/录屏 30s）
- `PairWizardDialog`（无线配对）、`ConnectionWatcher`（3s 轮询 + 上次目标持久化 + 自动重连）
- 抓帧降级模式 `SnapshotView`
- **验收**：功能对照表（§2）全部打勾

### M5 打磨与打包（2 天）
- 延迟测量与调优（丢帧策略、队列深度）
- 可选 `D3D11Decoder` 硬解后端
- `windeployqt` 打包 + 资源目录整理 + 启动脚本
- **验收**：见 §8 指标全部达标，绿色包可直接拷给同事运行

**合计约 12 人日**（不含评审与联调缓冲，建议按 3 周排期）。

---

## 7. 验收指标

| 指标 | 目标 | 测量方法 |
|---|---|---|
| 首帧时间 | < 1.5s | 点击连接到首帧出现的计时 |
| 端到端延迟 | < 100ms | 手机与 PC 同屏拍手机秒表，对比读数差 |
| 帧率 | 1080x2400 稳定 60fps | `--max-fps=60` 下统计实际解码帧率 |
| CPU | 软解 < 15%，硬解 < 8% | 任务管理器单进程 |
| 内存 | < 300MB | 同上 |
| 缩放 | 任意尺寸等比、无黑边、无闪烁 | 手工拖拽/最大化 |
| 断连恢复 | 拔网/锁屏后 10s 内自动恢复 | 手工 |

---

## 8. 风险与缓解

| 风险 | 影响 | 缓解 |
|---|---|---|
| scrcpy 协议随版本变化 | server 拒绝启动 / 帧头错位 | 锁定 2.7，jar 随包，常量校验；升级需回归 |
| FFmpeg 体积与许可 | 包体大 / 合规 | 只启用 h264 解码器 + 静态裁剪；LGPL 动态链接 |
| 硬解兼容性 | 部分机器黑屏 | 软解兜底，设置项可切 |
| 无线 adb 不稳定 | 设备掉线 | 沿用现有自动重连（3s 轮询 + 上次目标） |
| 触摸坐标偏差 | 点击错位 | 用设备真实分辨率做映射，加调试叠加层显示映射点 |
| Qt 授权 | 合规风险 | LGPL 动态链接，内部工具可用 |

---

## 9. 测试策略

- **单元测试**：帧头解析（构造 12 字节 golden）、control 消息序列化（对齐 `scrcpy/app/src/control_msg.c` 的字节布局）
- **集成测试**：脚本拉起 server + 回放预录 H.264 文件，验证解码链路
- **手工回归清单**：设备增删、锁屏/息屏、横竖屏旋转、窗口缩放/最大化/全屏、长时间 30 分钟稳定性

---

## 10. 迁移与回退

- 新旧并存：`tools/devboard`（Flutter）冻结并打 tag `devboard-flutter-final`，只修阻塞性 bug
- 功能对照表逐项勾选，全部勾完再删旧目录
- **回退条件**：M1 若在 3 天内无法稳定出首帧，暂停 Qt 路线，Flutter 版回退到"抓帧模式"作为可用态

---

## 附录 A：scrcpy 协议要点（2.7）

### A.1 启动 server

```bash
adb -s <serial> push third_party/scrcpy-server /data/local/tmp/scrcpy-server.jar
adb -s <serial> shell CLASSPATH=/data/local/tmp/scrcpy-server.jar \
    app_process / com.genymobile.scrcpy.Server 2.7 \
    log_level=info audio=false max_size=0 max_fps=60 \
    video_bit_rate=8000000 tunnel_forward=true \
    send_device_meta=true send_frame_meta=true send_codec_meta=true
adb -s <serial> forward tcp:<port> localabstract:scrcpy
```

`2.7` 必须与 jar 版本一致。`tunnel_forward=true` 表示由 adb forward 转发，客户端连 `tcp:<port>`。

### A.2 连接顺序（实测踩坑点）

启动 server 后，客户端必须对同一个 forward 端口**连续建立两条连接**：

1. 第一条 = video socket
2. 第二条 = control socket

**只连第一条时，服务端不会发送任何数据**（会一直阻塞，表现为"连上了但收不到字节"）。
实测：仅连 video 时 5 秒超时零字节；补上 control 连接后立刻收到握手数据。

### A.3 video socket 握手（已实测验证，scrcpy-server 2.7 / Redmi M2012K11C / Android 14）

```
[1 byte  dummy 0x00]
[64 byte 设备名，UTF-8，不足补 0]
[4 byte  codec id]       // 'h264' = 0x68323634（大端）
[4 byte  width]
[4 byte  height]
```

实测值：
```
dummy    : 00
设备名   : "M2012K11C"（补 0 到 64 字节）
codec    : 68 32 36 34  ("h264")
width    : 1080
height   : 2400
```

### A.4 帧结构（`send_frame_meta=true`）

```
[8 byte  pts|flags]      // 高 2 位为 flag，其余为 pts
                         // bit63 = CONFIG（SPS/PPS），bit62 = KEY_FRAME
[4 byte  size]
[size    H.264 数据]
```

`CONFIG` 包不是画面帧，要单独送给解码器做 extradata 初始化。

实测首帧：`pts_flags = 0x8000000000000000`（CONFIG 位），`size = 32`（SPS/PPS 共 32 字节）。
据此可确认 flag 位定义与字节序无误。

### A.5 control 消息（大端，部分为 16.16 定点）

| type | 名称 | 负载 |
|---|---|---|
| 0 | INJECT_KEYCODE | action(1) keycode(4) repeat(4) metaState(4) |
| 1 | INJECT_TEXT | len(4) + UTF-8 |
| 2 | INJECT_TOUCH_EVENT | action(1) pointerId(8) x(4) y(4) w(2) h(2) pressure(2) buttons(4) |
| 3 | INJECT_SCROLL_EVENT | x(4) y(4) w(2) h(2) hscroll(2) vscroll(2) buttons(4) |
| 4 | BACK_OR_SCREEN_ON | action(1) |
| 10 | SET_SCREEN_POWER_MODE | mode(1) |

坐标与 pressure 均为定点数（位移 16 位），需按设备真实分辨率换算。
完整定义以 `scrcpy/app/src/control_msg.c` 与 `server/.../ControlMessage.java` 为准。

---

## 附录 B：与 Flutter 版的代码映射

| Flutter | Qt | 备注 |
|---|---|---|
| `adb_service.dart` | `core/AdbClient` | 逻辑可逐条翻译，注意 `resolveAdb` 优先随包 adb |
| `mirror_controller.dart` | `app/MirrorController` + `core/VideoSocket` | 协议部分重写，不再需要 ffmpeg |
| `screen_panel.dart` | `ui/MirrorView` + `ui/SnapshotView` | 渲染换成 OpenGL |
| `panels.dart` | `ui/*Panel` | 4 个 Tab 一一对应 |
| `pair_wizard.dart` | `ui/PairWizardDialog` | 流程一致 |
| `main.dart` 的 `_watch()` | `app/ConnectionWatcher` | 3s 轮询 + 上次目标重连 |
