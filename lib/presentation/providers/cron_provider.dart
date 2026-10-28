import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/action_guard.dart';
import '../../di/providers.dart';
import '../../domain/entities/cron_task.dart';

/// 任务列表：切页/增删改后 invalidate 刷新
final cronListProvider = FutureProvider.autoDispose<List<CronTask>>((ref) {
  return ref.read(cronRepositoryProvider).list();
});

/// 单个任务的执行历史
final cronRunsProvider =
    FutureProvider.autoDispose.family<List<CronRun>, String>((ref, name) {
  return ref.read(cronRepositoryProvider).runs(name);
});

/// 任务操作（启停/运行/删除）：统一走这里，成功后刷新列表。
/// 写操作经 ActionGuard 去重，连点同键只发一次请求。
class CronActions {
  final Ref _ref;
  CronActions(this._ref);

  Future<void> setEnabled(CronTask task, bool enabled) async {
    await globalActionGuard.run(
        'cron:${enabled ? 'enable' : 'disable'}:${task.name}', () async {
      final repo = _ref.read(cronRepositoryProvider);
      if (enabled) {
        await repo.enable(task.name);
      } else {
        await repo.disable(task.name);
      }
    });
  }

  Future<void> run(CronTask task) async {
    await globalActionGuard.run('cron:run:${task.name}',
        () => _ref.read(cronRepositoryProvider).run(task.name));
  }

  Future<void> delete(CronTask task) async {
    await globalActionGuard.run('cron:delete:${task.name}',
        () => _ref.read(cronRepositoryProvider).delete(task.name));
  }

  void refresh() => _ref.invalidate(cronListProvider);
}

final cronActionsProvider = Provider<CronActions>((ref) => CronActions(ref));
