# DevBoard-Qt 架构审查与缺陷修复（2026-10-27）

范围：`tools/devboard-qt`（Qt 6.5.3 Widgets 壳 + 嵌入 scrcpy 官方客户端）。
触发：用户提出「感觉缺个设置功能」「丰富功能并审查架构及 bug 缺陷」。本文记录审查结论、修复方式与验证结果。

## 1. 审查前的结构问题

| # | 问题 | 影响 |
|---|---|---|
| A1 | 无配置抽象，`QSettings` 键名与默认值散落在 `MainWindow.cpp` | 新增配置要改多处、键名易写错 |
| A2 | `MainWindow.cpp` 约 980 行，UI 构建 / 设备管理 / 截图录屏 / logcat / 快捷键全在一个类 | 责任过载，改动容易互相影响 |
| A3 | 错误反馈不统一：有的 `emit errorOccurred`，有的直接 `setText` | 用户看到的信息不一致，部分失败静默 |
| A4 | 镜像参数（`720`、`60`）、重连（`6` 次 / `3000ms`）全部硬编码 | 无法按网络与机器调整 |
| A5 | 无持久化：设备、窗口几何、镜像参数都不记忆 | 每次启动要重新选设备、窗口位置漂移 |
| A6 | 无自动化测试 | 回归靠手点 |

## 2. 缺陷清单与修复

| # | 缺陷 | 根因 | 修复 |
|---|---|---|---|
| B1 | 镜像参数硬编码 | `m_scrcpy->start(serial, 720, 60)` 两处调用 | `Settings::MirrorOptions` + `ScrcpyProcess::start(serial)` 内部拼参数（分辨率/帧率/码率/保持唤醒/关屏） |
| B2 | 不记忆上次设备 | 只支持 `--serial` 启动参数 | `conn/lastSerial` 写盘；启动时待设备在线后自动连接（`m_pendingSerial`），`--serial` 优先 |
| B3 | 窗口几何不持久 | 未调用 `saveGeometry/restoreGeometry` | 构造时恢复、`closeEvent` 保存；`ui/geometry` |
| B4 | 设置只有截图目录 | 裸 `QSettings` 读写单键 | 新增 `Settings` + `SettingsDialog`（镜像/连接/路径/界面四组） |
| B5 | adb 探测第二段失效 | 复用第一个循环已上溯到根目录的 `dir`，再上溯是空操作 | 保存 `startDir` 后重新上溯 |
| B6 | 宿主 resize 后嵌入窗口不跟随 | 只在 `embedWindow` 里 `MoveWindow` 一次 | `eventFilter` 监听 `m_mirrorHost` 的 `Resize`，150ms 防抖后 `ScrcpyProcess::resizeEmbedded()`；尺寸相同则跳过，避免无意义的 SDL resize |
| B7 | logcat 行被静默丢弃 | `appendLogLines` 每次最多 300 行，多余直接 return | 改为 `flushBatch` 分批插入全部行 |
| B8 | logcat 切换实例竞态 | `readyRead` lambda 用成员 `m_logcat` | 改为捕获局部 `proc`，`finished` 时判 `m_logcat == proc` 再清空 |
| B9 | 操作串到错误设备 | 终端/日志/设备信息/截图/录屏/包列表都用下拉框 `currentSerial()` | 新增 `activeSerial()`（镜像中的设备优先），全部操作路径改用它；未连接镜像时退回下拉框 |
| B10 | scrcpy 启动失败时按钮卡住 | 找不到 exe 只 `emit errorOccurred` | 补 `emit runningChanged(false)` |
| B11 | 设备离线也重连，预算秒空 | 重连前不检查在线状态 | 离线时状态栏「设备离线，等待恢复…」并重启定时器，不消耗预算；`reconnectMax<=0` 时不自动重连 |
| B12 | 退出不清理录屏 | 仅 `closeEvent` 保存几何 | 关闭时若在录屏，向设备端发 `kill -INT` 并删除远程临时文件 |
| B13 | 截图回退文件重名 | 固定 `/sdcard/devboard-shot-tmp.png` | 改为带毫秒时间戳的文件名 |
| B14 | 工具条 `saveState` 警告 | 工具条未设 `objectName` | 两行工具条都设 `objectName`（`deviceBar` / `keyBar`），且不再 `restoreState`：布局固定，恢复旧状态会把按键栏拉回同一行并盖住右侧面板 |
| B15 | 鼠标滚轮卡死 | `eventFilter` 把 Qt 滚轮事件用 `PostMessage(WM_MOUSEWHEEL)` 回贴给镜像子窗口；SDL 不处理时 `DefWindowProc` 又把它气泡回父窗口，形成闭环，每秒产生数百次注入；scrcpy 控制队列（上限 60）被灌满后每丢一条打一条 WARN，应用日志约 700 行/秒写盘并推 UI | 删除滚轮转发：光标在子窗口上时 Windows 已直接把 `WM_MOUSEWHEEL` 投递给它，Qt 只放行不拦截；`consumeLog` 对相同行 1 秒内去重（只输出一行 + 重复计数） |

## 3. 本次新增

- `src/Settings.h/.cpp`：`MirrorOptions` / `ConnOptions` / `UiOptions` 三个结构 + 路径与窗口几何读写；`QSettings("DevBoard","DevBoard")`；`resetAll()`。
- `src/SettingsDialog.h/.cpp`：四分组设置对话框，Save / Cancel / RestoreDefaults，只在 Save 时落盘。
- 第二行工具条「按键」：返回(4) / 主页(3) / 多任务(187) / 音量−(25) / 音量+(24) / 电源(26) / 旋转（`accelerometer_rotation=0` + `user_rotation` 0→1→2→3 循环）。
- `activeSerial()`：镜像设备优先，保证面板操作和画面是同一台机器。
- 日志补齐：`[settings] applied`、`[mirror] resize follow`、`[key] keyevent`、`[mirror] auto connect last device`、`[record] cancelled on app close`。

## 4. 验证记录（真机 M2012K11C，无线 adb）

- 启动恢复几何：保存 1234x834 @ (222,111) → 重启后一致。
- 自动连上次设备：无 `--serial` 启动，日志 `[mirror] auto connect last device "192.168.1.10:39423"`，1 秒内嵌入。
- 设置对话框：`Ctrl+,` 打开，四组控件完整；RestoreDefaults → Save 后注册表 `mirror/maxSize=720`，日志 `[settings] applied font=13 followResize=true captureDir=... reconnect=6 x 3 s`。
- 按键栏：主页 → `[key] keyevent 3`，设备回到桌面；旋转 → `user_rotation` 依次 1/2/3/0。
- resize 跟随：窗口拉到 1300x900 → `[mirror] resize follow QSize(458,768)` + `[scrcpy] resize embedded`，截图无重影、画面完整。
- 关闭：`[scrcpy] stopping` → `[scrcpy] exited code=62097 userStop=true`，几何写盘。

## 5. 后续建议（未实施）

1. 拆分 `MainWindow`：`CaptureController`（截图/录屏）、`LogcatController`、`DeviceActions`，`MainWindow` 只做装配与布局。
2. 引入 Qt Test 覆盖 `Settings` 默认值与 `AdbClient` 的 `devices -l` 解析。
3. 镜像区宽高比自适应：目前 scrcpy 按窗口等比 letterbox，窗口过宽会有黑边，可考虑按视频比例限制宿主宽度。

## 6. 实测：嵌入版 vs 独立 scrcpy（M2012K11C，无线 adb）

同参数（`--max-size=1080 --max-fps=60 --video-bit-rate=32M --no-audio --stay-awake`，编码输出 488x1080）、同窗口尺寸、同一段脚本滑动负载（设备端连续 `input swipe` 约 26 秒）：

| 指标 | 独立 scrcpy | 嵌入版 |
| --- | --- | --- |
| `--print-fps` | 51–58，掉帧时 34–45（skipped 10 次） | 56–60，掉帧时 40–45（skipped 13 次） |
| scrcpy CPU（18 秒负载） | 1.57 s | 1.52 s |
| 壳进程（devboard-qt） | — | 空闲约 0.6 s／12 秒；滚轮风暴修复前可达 4 s+／12 秒 |

结论：嵌入本身不劣化帧率与 CPU。主观「不如 scrcpy 流畅」主要来自三点：

1. 滚轮风暴（B15，已修）：在镜像上滚动会让整机卡死，这是最直接的体感差异。
2. 镜像面板把 488x1080 视频等比缩到约 317x702（面板 440 宽 + letterbox），画面比独立窗口小且经过缩放。
3. 设备端 `input swipe/input tap` 每次都要拉起一个 Java 进程，抢 CPU 时两边都会掉帧（`N fps (+M frames skipped)`），不是壳层问题。

若仍要压缩延迟：可把镜像区做成可全屏/收起右侧面板，让视频按原始比例铺满；或把设置里的分辨率上限调到「原始」减少缩放层级。
