import 'package:flutter/material.dart';

/// 轻量全局 Toast：无 Context 依赖，供 provider 层操作结果反馈使用。
/// 由 HomeScreen 在 initState 时 bind(ScaffoldMessenger) 完成注入。
class AppToast {
  AppToast._();
  static ScaffoldMessengerState? _messenger;

  static void bind(ScaffoldMessengerState messenger) => _messenger = messenger;

  static void show(String message, {bool error = false}) {
    final messenger = _messenger;
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
        duration: const Duration(seconds: 2),
      ));
  }
}
