import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../di/providers.dart';
import '../../domain/entities/notification_item.dart';

/// 通知中心状态：列表 + 未读数 + 30s 轮询（后端通知流为 SSE，Web 适用；
/// 移动端用轮询保证后台可达性，新通知到来时回调 [onNew] 供 UI 弹提示）。
class NotificationState {
  final List<NotificationItem> items;
  final int unreadCount;
  final bool loading;
  final String? error;
  final int? latestSeenId; // 已见过的最新通知 id（用于识别"新"通知）

  const NotificationState({
    this.items = const [],
    this.unreadCount = 0,
    this.loading = false,
    this.error,
    this.latestSeenId,
  });

  NotificationState copyWith({
    List<NotificationItem>? items,
    int? unreadCount,
    bool? loading,
    String? error,
    bool clearError = false,
    int? latestSeenId,
  }) {
    return NotificationState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      latestSeenId: latestSeenId ?? this.latestSeenId,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref _ref;
  Timer? _timer;
  bool _disposed = false;

  NotificationNotifier(this._ref) : super(const NotificationState());

  /// 启动 30s 未读数轮询（首次拉取也刷新列表）。返回新通知的回调供 UI 弹 SnackBar。
  void startPolling(
      {void Function(NotificationItem item)? onNew, int intervalSec = 30}) {
    _timer?.cancel();
    _refresh(announceNew: false);
    _timer = Timer.periodic(Duration(seconds: intervalSec), (_) {
      _refresh(onNew: onNew);
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() => _refresh(announceNew: false);

  Future<void> _refresh(
      {void Function(NotificationItem item)? onNew,
      bool announceNew = true}) async {
    if (_disposed) return;
    final repo = _ref.read(notificationRepositoryProvider);
    // 列表为空时置 loading：首屏与清空后的加载态可达（轮询静默刷新不置）
    if (state.items.isEmpty) state = state.copyWith(loading: true, error: null);
    try {
      final count = await repo.getUnreadCount();
      if (_disposed) return;

      // 未读数变化时拉列表，识别新增通知
      List<NotificationItem>? items;
      if (count != state.unreadCount || state.items.isEmpty) {
        items = await repo.list(limit: 50);
        if (_disposed) return;
      }

      var latestSeen = state.latestSeenId;
      if (items != null && items.isNotEmpty) {
        final newest = items.first.id;
        if (announceNew && latestSeen != null && onNew != null) {
          for (final item in items) {
            if (item.id > latestSeen) {
              onNew(item); // 逐条提示（轮询周期内可能多条）
            }
          }
        }
        latestSeen = newest;
      }

      state = state.copyWith(
        items: items,
        unreadCount: count,
        clearError: true,
        latestSeenId: latestSeen,
        loading: false,
      );
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(error: '通知刷新失败: $e', loading: false);
      }
    }
  }

  Future<void> markAsRead(int id) async {
    await _ref.read(notificationRepositoryProvider).markAsRead(id);
    final items = state.items
        .map((e) => e.id == id ? e.copyWith(isRead: true) : e)
        .toList();
    final unread = items.where((e) => !e.isRead).length;
    state = state.copyWith(items: items, unreadCount: unread);
  }

  Future<void> markAllAsRead() async {
    await _ref.read(notificationRepositoryProvider).markAllAsRead();
    final items = state.items.map((e) => e.copyWith(isRead: true)).toList();
    state = state.copyWith(items: items, unreadCount: 0);
  }

  Future<void> delete(int id) async {
    // Dismissible 的 onDismissed 要求条目从树中立即移除，否则抛
    // "A dismissed Dismissible widget is still part of the tree"（debug 红屏）。
    // 因此先乐观更新本地列表（滑出动画结束时该项已消失），网络删除异步跟进，
    // 失败时按原位置回滚并提示。
    final removedIndex = state.items.indexWhere((e) => e.id == id);
    if (removedIndex < 0) return;
    final removed = state.items[removedIndex];
    final items = [...state.items]..removeAt(removedIndex);
    final unread = items.where((e) => !e.isRead).length;
    state = state.copyWith(items: items, unreadCount: unread);

    try {
      await _ref.read(notificationRepositoryProvider).delete(id);
    } catch (e) {
      if (_disposed) return;
      final restored = [...state.items];
      restored.insert(removedIndex.clamp(0, restored.length), removed);
      final restoredUnread = restored.where((e) => !e.isRead).length;
      state = state.copyWith(
          items: restored, unreadCount: restoredUnread, error: '删除失败: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    super.dispose();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});
