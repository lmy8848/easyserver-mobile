import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../di/providers.dart';

/// 仪表盘自动刷新间隔（秒）；0 表示关闭自动刷新。
/// 持久化到 SharedPreferences，改动即时生效（仪表盘 watch 本 provider）。
class DashboardRefreshNotifier extends StateNotifier<int> {
  static const _key = 'dashboard_refresh_seconds';
  static const _default = 10;

  DashboardRefreshNotifier(this._ref) : super(_default) {
    final saved = _ref.read(settingsStorageProvider).getInt(_key);
    if (saved >= 0) state = saved;
  }

  final Ref _ref;

  /// 候选间隔（秒）；0 表示关闭
  static const choices = [0, 5, 10, 30, 60];

  Future<void> setInterval(int seconds) async {
    state = seconds;
    await _ref.read(settingsStorageProvider).setInt(_key, seconds);
  }
}

final dashboardRefreshProvider =
    StateNotifierProvider<DashboardRefreshNotifier, int>(
  (ref) => DashboardRefreshNotifier(ref),
);
