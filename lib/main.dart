import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/logger/app_logger.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 全局异常捕获（Widget 构建 + 未捕获异步异常）进运行日志，供「账户与安全 → 运行日志」查看
  AppLogger.instance.installErrorHandlers();
  AppLogger.i('应用启动');
  runApp(const ProviderScope(child: EasyServerMobileApp()));
}
