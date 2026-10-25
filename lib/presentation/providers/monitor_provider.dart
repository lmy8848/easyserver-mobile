import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/monitor_snapshot.dart';
import '../../di/providers.dart';

/// 自动刷新失败的轻提示（保留旧数据展示）；手动刷新失败走 AsyncValue.error
/// 渲染完整错误区块。UI 读取本状态显示横幅。
final monitorErrorProvider = StateProvider<String?>((_) => null);

final monitorProvider =
    StateNotifierProvider<MonitorNotifier, AsyncValue<MonitorSnapshot?>>((ref) {
  return MonitorNotifier(ref);
});

class MonitorNotifier extends StateNotifier<AsyncValue<MonitorSnapshot?>> {
  final Ref _ref;
  StreamSubscription? _subscription;

  MonitorNotifier(this._ref) : super(const AsyncValue.data(null));

  /// [silent] 自动刷新模式：失败不进入 error 区块（不打断已有数据展示），
  /// 错误写入 [monitorErrorProvider] 由 UI 以横幅轻提示呈现。
  Future<void> fetchStats({bool silent = false}) async {
    if (!silent) state = const AsyncValue.loading();
    try {
      final snapshot = await _ref.read(monitorRepositoryProvider).getStats();
      if (!mounted) return;
      state = AsyncValue.data(snapshot);
      _ref.read(monitorErrorProvider.notifier).state = null;
    } catch (e, st) {
      if (!mounted) return;
      final current = state.value;
      if (silent && current != null) {
        _ref.read(monitorErrorProvider.notifier).state = e.toString();
        return;
      }
      state = AsyncValue.error(e, st);
    }
  }

  void startStreaming() {
    final repo = _ref.read(monitorRepositoryProvider);
    _subscription = repo.streamMonitor().listen((snapshot) {
      state = AsyncValue.data(snapshot);
    });
  }

  void stopStreaming() {
    _subscription?.cancel();
    _ref.read(monitorRepositoryProvider).disconnectMonitor();
  }

  @override
  void dispose() {
    stopStreaming();
    super.dispose();
  }
}
