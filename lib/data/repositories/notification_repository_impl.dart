import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/remote/api_client.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiClient _api;
  NotificationRepositoryImpl(this._api);

  @override
  Future<List<NotificationItem>> list(
      {bool unreadOnly = false, int limit = 50}) async {
    final data = await _api.get('/notifications',
        queryParameters: {'unread': unreadOnly, 'limit': limit});
    // 后端返回 httpx.Page{items,total}；_unwrapResponse 会把裸列表包成 {'_items': ...}
    final items = (data['items'] ?? data['_items'] ?? data['notifications'])
            as List<dynamic>? ??
        [];
    return items
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final json = await _api.get('/notifications/unread-count');
    return json['count'] as int? ?? 0;
  }

  @override
  Future<void> markAsRead(int id) async {
    await _api.put('/notifications/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await _api.put('/notifications/read-all');
  }

  @override
  Future<void> delete(int id) async {
    await _api.delete('/notifications/$id');
  }
}
