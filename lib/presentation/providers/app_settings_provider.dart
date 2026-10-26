import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../core/logger/app_logger.dart';

/// 应用设置集中管理：应用锁（生物识别）、通知提示、通知轮询间隔。
/// 全部持久化到 SharedPreferences；改动即时生效。
class AppSettingsState {
  final bool appLockEnabled; // 开启后：App 回到前台需生物识别解锁
  final bool notifyEnabled; // 新通知到达 App 内提示
  final int notifyIntervalSec; // 通知轮询间隔（秒）

  const AppSettingsState({
    this.appLockEnabled = false,
    this.notifyEnabled = true,
    this.notifyIntervalSec = 30,
  });

  AppSettingsState copyWith(
          {bool? appLockEnabled,
          bool? notifyEnabled,
          int? notifyIntervalSec}) =>
      AppSettingsState(
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        notifyEnabled: notifyEnabled ?? this.notifyEnabled,
        notifyIntervalSec: notifyIntervalSec ?? this.notifyIntervalSec,
      );
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  static const _kAppLock = 'app_lock_enabled';
  static const _kNotify = 'notify_enabled';
  static const _kNotifyInterval = 'notify_interval_sec';

  final Ref _ref;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AppSettingsNotifier(this._ref) : super(const AppSettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final storage = _ref.read(settingsStorageProvider);
    await storage.init();
    if (!mounted) return;
    state = state.copyWith(
      appLockEnabled: storage.getBool(_kAppLock),
      notifyEnabled: storage.getBool(_kNotify, defaultValue: true),
      notifyIntervalSec: storage.getInt(_kNotifyInterval, defaultValue: 30),
    );
  }

  /// 设备是否支持生物识别
  Future<bool> deviceSupportsBiometrics() async {
    try {
      final ok = await _localAuth.canCheckBiometrics;
      return ok || await _localAuth.isDeviceSupported();
    } catch (e) {
      AppLogger.w('生物识别能力检测失败: $e');
      return false;
    }
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    state = state.copyWith(appLockEnabled: enabled);
    final storage = _ref.read(settingsStorageProvider);
    await storage.init();
    await storage.setBool(_kAppLock, enabled);
  }

  Future<void> setNotifyEnabled(bool enabled) async {
    state = state.copyWith(notifyEnabled: enabled);
    final storage = _ref.read(settingsStorageProvider);
    await storage.init();
    await storage.setBool(_kNotify, enabled);
  }

  Future<void> setNotifyInterval(int seconds) async {
    state = state.copyWith(notifyIntervalSec: seconds);
    final storage = _ref.read(settingsStorageProvider);
    await storage.init();
    await storage.setInt(_kNotifyInterval, seconds);
  }

  /// 弹出系统生物识别验证；成功返回 true
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: '验证身份以解锁 EasyServer',
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      AppLogger.w('生物识别验证失败: $e');
      return false;
    }
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>(
  (ref) => AppSettingsNotifier(ref),
);
