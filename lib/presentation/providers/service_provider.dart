import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/service_info.dart';
import '../../di/providers.dart';

final serviceListProvider = FutureProvider<List<ServiceInfo>>((ref) async {
  return ref.read(serviceRepositoryProvider).list();
});

final serviceActionProvider = StateNotifierProvider.family<
    ServiceActionNotifier, ServiceActionState, String>((ref, name) {
  return ServiceActionNotifier(ref.read(serviceRepositoryProvider), name);
});

class ServiceActionState {
  final bool isLoading;
  final String? error;
  final bool success;
  const ServiceActionState(
      {this.isLoading = false, this.error, this.success = false});
}

class ServiceActionNotifier extends StateNotifier<ServiceActionState> {
  final dynamic _repo;
  final String name;

  ServiceActionNotifier(this._repo, this.name)
      : super(const ServiceActionState());

  Future<void> start() async {
    await _action('start', () => _repo.start(name));
  }

  Future<void> stop() async {
    await _action('stop', () => _repo.stop(name));
  }

  Future<void> restart() async {
    await _action('restart', () => _repo.restart(name));
  }

  Future<void> _action(String label, Future<void> Function() action) async {
    if (state.isLoading) return; // 连点去重：上一操作未完成前忽略
    state = ServiceActionState(isLoading: true);
    try {
      await action();
      state = ServiceActionState(success: true);
    } catch (e) {
      state = ServiceActionState(error: '$label 失败: $e');
    }
  }
}
