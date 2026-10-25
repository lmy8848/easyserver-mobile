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
  void startPolling({void Function(NotificationItem item)? onNew}) {
    _timer?.cancel();
    _refresh(announceNew: false);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
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
      );
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(error: '通知刷新失败: $e');
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
    await _ref.read(notificationRepositoryProvider).delete(id);
    final items = state.items.where((e) => e.id != id).toList();
    final unread = items.where((e) => !e.isRead).length;
    state = state.copyWith(items: items, unreadCount: unread);
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
