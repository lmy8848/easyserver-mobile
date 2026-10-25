# DevBoard · 移动端开发脚手架

Windows 桌面应用（Flutter），为 EasyServer Mobile 的日常开发提供一站式真机调试能力：
屏幕实时监视、鼠标点击/滑动操控、文本注入、ADB 命令终端、无线设备管理。

## 功能

| 区域 | 能力 |
|---|---|
| 屏幕监视 | 定时抓帧（1/2/3/5s 可调，可暂停/手动），自适应比例显示 |
| 屏幕操控 | 点击画面即注入 tap；拖拽即 swipe（带最小位移防误触）；返回/主页/多任务/电源键；文本输入框 |
| 设备管理 | 自动列出 adb 设备（含无线）；一键连接 `IP:端口`；多设备 chip 选择 |
| ADB 终端 | 自由执行 adb 命令（自动附加 `-s <serial>`），输出滚动缓冲 800 行 |

## 运行

```bash
cd tools/devboard
flutter run -d windows
```

adb 路径探测顺序：环境变量 `DEVBOARD_ADB` → `PATH` → `C:\android-sdk\platform-tools\adb.exe`。
未安装 adb 时按提示设置 `DEVBOARD_ADB` 指向 adb.exe。

## 无线调试配对（首次）

1. 手机：设置 → 开发者选项 → 无线调试 → 「使用配对码配对设备」
2. DevBoard 之外的终端执行：`adb pair <IP:配对端口> <6位配对码>`（弹窗时效约 2 分钟，端口每次打开会变）
3. 配对成功后，DevBoard 里点「连接无线设备」填 `IP:连接端口`（无线调试主界面显示的端口）

配对一次即可，之后无线调试开着就能连。

## 已知限制

- 无线 adb 的 `screencap` 每帧约 1-2s（PNG ~2MB），实时性不如 scrcpy 的 H.264 串流；
  开发调试足够，需要高帧率时建议用 USB 连接或 scrcpy 配合使用。
- 多设备条目：无线设备会同时出现 IP 与 mDNS 两个条目，选择任意一个均可。
