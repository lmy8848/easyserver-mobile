import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_toast.dart';
import '../../core/logger/app_logger.dart';
import '../../data/repositories/container_repository_impl.dart';
import '../../di/providers.dart';
import '../../domain/entities/container_info.dart';
import '../../domain/repositories/container_repository.dart';

final containerRepositoryProvider = Provider<ContainerRepository>(
    (ref) => ContainerRepositoryImpl(ref.read(apiClientProvider)));

class ContainerState {
  final bool loading;
  final bool engineReady;
  final List<ContainerInfo> items;
  final String? error;

  const ContainerState({
    this.loading = false,
    this.engineReady = true,
    this.items = const [],
    this.error,
  });

  ContainerState copyWith(
      {bool? loading,
      bool? engineReady,
      List<ContainerInfo>? items,
      String? error,
      bool clearError = false}) {
    return ContainerState(
      loading: loading ?? this.loading,
      engineReady: engineReady ?? this.engineReady,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ContainerNotifier extends StateNotifier<ContainerState> {
  final Ref _ref;
  bool _loadedOnce = false;

  ContainerNotifier(this._ref) : super(const ContainerState());

  /// 懒加载：tab 首次可见时拉取；[force] 操作后强制刷新
  Future<void> load({bool force = false}) async {
    if (_loadedOnce && !force) return;
    state = state.copyWith(loading: true, clearError: true);
    final repo = _ref.read(containerRepositoryProvider);
    try {
      // 引擎未就绪时给出引导提示，不作为硬错误
      if (!await repo.engineAvailable()) {
        if (!mounted) return;
        _loadedOnce = true;
        state = state.copyWith(loading: false, engineReady: false, items: []);
        return;
      }
      final items = await repo.list();
      if (!mounted) return;
      _loadedOnce = true;
      state = state.copyWith(loading: false, engineReady: true, items: items);
    } catch (e) {
      if (!mounted) return;
      AppLogger.w('容器列表加载失败: $e');
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> _action(Future<void> Function() op, String successMsg) async {
    try {
      await op();
      await load(force: true);
      AppToast.show(successMsg);
    } catch (e) {
      AppLogger.w('容器操作失败: $e');
      AppToast.show('操作失败: $e', error: true);
    }
  }

  Future<void> start(String id) =>
      _action(() => _ref.read(containerRepositoryProvider).start(id), '已启动');
  Future<void> stop(String id) =>
      _action(() => _ref.read(containerRepositoryProvider).stop(id), '已停止');
  Future<void> restart(String id) =>
      _action(() => _ref.read(containerRepositoryProvider).restart(id), '已重启');
  Future<void> remove(String id) =>
      _action(() => _ref.read(containerRepositoryProvider).remove(id), '已删除');
}

final containerProvider =
    StateNotifierProvider<ContainerNotifier, ContainerState>(
  (ref) => ContainerNotifier(ref),
);
