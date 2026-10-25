import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/monitor_snapshot.dart';
import '../../di/providers.dart';

final monitorProvider =
    StateNotifierProvider<MonitorNotifier, AsyncValue<MonitorSnapshot?>>((ref) {
  return MonitorNotifier(ref);
});

class MonitorNotifier extends StateNotifier<AsyncValue<MonitorSnapshot?>> {
  final Ref _ref;
  StreamSubscription? _subscription;

  MonitorNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> fetchStats() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref
        .read(monitorRepositoryProvider)
        .getStats()
        .then((v) => v as MonitorSnapshot?));
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
