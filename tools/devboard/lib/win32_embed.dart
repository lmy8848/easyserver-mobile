import 'dart:ffi';
import 'dart:async';

import 'package:ffi/ffi.dart';

/// Win32 窗口嵌入：把 scrcpy 的镜像窗口 SetParent 进 DevBoard 主窗口，
/// 并随 Flutter 布局同步位置/尺寸（经典 scrcpy-GUI 壳方案）。
class Win32Embed {
  Win32Embed._();

  static final _user32 = DynamicLibrary.open('user32.dll');
  static final _findWindowW = _user32
      .lookupFunction<
        IntPtr Function(Pointer<Utf16>, Pointer<Utf16>),
        int Function(Pointer<Utf16>, Pointer<Utf16>)
      >('FindWindowW');
  static final _setParent = _user32
      .lookupFunction<IntPtr Function(IntPtr, IntPtr), int Function(int, int)>(
        'SetParent',
      );
  static final _moveWindow = _user32
      .lookupFunction<
        Int32 Function(IntPtr, Int32, Int32, Int32, Int32),
        int Function(int, int, int, int, int)
      >('MoveWindow');
  static final _setWindowLongW = _user32
      .lookupFunction<
        Int32 Function(IntPtr, Int32, Int32),
        int Function(int, int, int)
      >('SetWindowLongW');
  static final _showWindow = _user32
      .lookupFunction<Int32 Function(IntPtr, Int32), int Function(int, int)>(
        'ShowWindow',
      );
  static final _getDpiForWindow = _user32
      .lookupFunction<Uint32 Function(IntPtr), int Function(int)>(
        'GetDpiForWindow',
      );
  static final _isWindow = _user32
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>('IsWindow');

  static const _gwlStyle = -16;
  // 去掉标题栏/边框/系统菜单，只留客户区（WS_POPUP=0x80000000，去除
  // WS_CAPTION|WS_THICKFRAME|WS_SYSMENU|WS_MINIMIZEBOX|WS_MAXIMIZEBOX）
  static const _styleFrameless = 0x80000000;

  static int? findWindow(String title) {
    final t = title.toNativeUtf16();
    try {
      final hwnd = _findWindowW(nullptr, t);
      return hwnd != 0 ? hwnd : null;
    } finally {
      calloc.free(t);
    }
  }

  /// 轮询等待 scrcpy 窗口出现
  static Future<int?> waitForWindow(
    String title, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final hwnd = findWindow(title);
      if (hwnd != null) return hwnd;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return null;
  }

  static void frameless(int hwnd) {
    _setWindowLongW(hwnd, _gwlStyle, _styleFrameless);
    _showWindow(hwnd, 5); // SW_SHOW
  }

  /// 把 scrcpy 窗口挂为 childHwnd（DevBoard 主窗）的子窗口
  static void reparent(int scrcpyHwnd, int childHwnd) {
    _setParent(scrcpyHwnd, childHwnd);
    frameless(scrcpyHwnd);
  }

  /// 物理像素：画布逻辑坐标 × 设备 DPI 缩放
  static double dpiScale(int devboardHwnd) {
    final dpi = _getDpiForWindow(devboardHwnd);
    return dpi == 0 ? 1.0 : dpi / 96.0;
  }

  static void moveTo(int hwnd, int x, int y, int w, int h) {
    _moveWindow(hwnd, x, y, w, h);
  }

  static bool isAlive(int hwnd) => _isWindow(hwnd) != 0;

  /// 从父窗口脱离并还原窗口（关闭前调用）
  static void detach(int hwnd) {
    _setParent(hwnd, 0);
    _showWindow(hwnd, 0); // SW_HIDE
  }
}

/// scrcpy 窗口嵌入会话：负责查找、父化、布局同步与生命周期
class ScrcpyEmbedSession {
  ScrcpyEmbedSession(this.windowTitle);

  final String windowTitle;
  int? _scrcpyHwnd;
  int? _devboardHwnd;
  Timer? _watchdog;

  bool get attached => _scrcpyHwnd != null && Win32Embed.isAlive(_scrcpyHwnd!);

  void setDevboardHwnd(int hwnd) => _devboardHwnd = hwnd;

  Future<bool> attach() async {
    final hwnd = await Win32Embed.waitForWindow(windowTitle);
    if (hwnd == null || _devboardHwnd == null) return false;
    _scrcpyHwnd = hwnd;
    Win32Embed.reparent(hwnd, _devboardHwnd!);
    return true;
  }

  /// 画布在 DevBoard 客户区中的逻辑坐标 → 物理像素移动 scrcpy 窗口
  void layout({
    required double logicalX,
    required double logicalY,
    required double logicalW,
    required double logicalH,
  }) {
    final hwnd = _scrcpyHwnd;
    final parent = _devboardHwnd;
    if (hwnd == null || parent == null || !attached) return;
    final scale = Win32Embed.dpiScale(parent);
    Win32Embed.moveTo(
      hwnd,
      (logicalX * scale).round(),
      (logicalY * scale).round(),
      (logicalW * scale).round(),
      (logicalH * scale).round(),
    );
  }

  /// 看门狗：scrcpy 窗口被外力关闭时通知调用方
  void startWatchdog(void Function() onWindowLost) {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_scrcpyHwnd != null && !attached) {
        _scrcpyHwnd = null;
        onWindowLost();
      }
    });
  }

  void dispose() {
    _watchdog?.cancel();
    final hwnd = _scrcpyHwnd;
    if (hwnd != null && Win32Embed.isAlive(hwnd)) {
      Win32Embed.detach(hwnd);
    }
    _scrcpyHwnd = null;
  }
}
