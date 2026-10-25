import 'dart:async';

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class LogEntry {
  final DateTime time;
  final LogLevel level;
  final String message;

  const LogEntry(this.time, this.level, this.message);

  String get levelLabel => switch (level) {
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO',
        LogLevel.warn => 'WARN',
        LogLevel.error => 'ERROR',
      };
}

/// 全局运行日志：环形缓冲最近 N 条，供「运行日志」页面查看与排障。
///
/// 覆盖三类来源：
/// 1. 代码埋点（AppLogger.d/i/w/e）
/// 2. Widget 构建异常（FlutterError.onError）
/// 3. 未捕获的异步异常（PlatformDispatcher.instance.onError）
///
/// 异常在记录后仍走 Flutter 默认呈现（debug 红屏不受影响）。
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  static const _maxEntries = 500;

  final List<LogEntry> _entries = <LogEntry>[];
  final StreamController<List<LogEntry>> _updates =
      StreamController<List<LogEntry>>.broadcast();

  List<LogEntry> get entries => List.unmodifiable(_entries);
  Stream<List<LogEntry>> get updates => _updates.stream;

  void log(LogLevel level, String message) {
    _entries.add(LogEntry(DateTime.now(), level, message));
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
    if (!_updates.isClosed) _updates.add(entries);
    debugPrint('[${level.name.toUpperCase()}] $message');
  }

  static void d(String message) => instance.log(LogLevel.debug, message);
  static void i(String message) => instance.log(LogLevel.info, message);
  static void w(String message) => instance.log(LogLevel.warn, message);
  static void e(String message) => instance.log(LogLevel.error, message);

  void clear() {
    _entries.clear();
    if (!_updates.isClosed) _updates.add(entries);
  }

  /// 安装全局异常捕获。应在 main 中 runApp 前调用。
  void installErrorHandlers() {
    FlutterError.onError = (details) {
      // 保留默认呈现（debug 红屏 / release 上报）
      FlutterError.presentError(details);
      e('UI异常: ${details.exceptionAsString()}');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      e('未捕获异常: $error');
      // 已记录并兜底，避免进程直接崩溃
      return true;
    };
  }
}
