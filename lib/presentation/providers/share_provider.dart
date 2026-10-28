import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/action_guard.dart';
import '../../di/providers.dart';
import '../../domain/entities/file_share.dart';

/// 外链列表：创建/删除/清理后 invalidate 刷新
final shareListProvider = FutureProvider.autoDispose<List<FileShare>>((ref) {
  return ref.read(shareRepositoryProvider).list();
});

/// 外链操作：写操作全部经 ActionGuard 去重，连点不发二次请求
class ShareActions {
  final Ref _ref;
  ShareActions(this._ref);

  Future<FileShare?> create(CreateShareInput input) async {
    final share = await globalActionGuard.run(
        'share:create:${input.filePath}',
        () => _ref.read(shareRepositoryProvider).create(input));
    _ref.invalidate(shareListProvider);
    return share;
  }

  Future<void> delete(FileShare share) async {
    await globalActionGuard.run('share:delete:${share.id}',
        () => _ref.read(shareRepositoryProvider).delete(share.id));
    _ref.invalidate(shareListProvider);
  }

  /// 清理过期外链，返回清理条数（守卫在途时返回 null）
  Future<int?> cleanup() async {
    final n = await globalActionGuard.run(
        'share:cleanup', () => _ref.read(shareRepositoryProvider).cleanup());
    if (n != null) _ref.invalidate(shareListProvider);
    return n;
  }

  void refresh() => _ref.invalidate(shareListProvider);
}

final shareActionsProvider = Provider<ShareActions>((ref) => ShareActions(ref));
