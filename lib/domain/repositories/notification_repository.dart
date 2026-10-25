import '../entities/notification_item.dart';

abstract class NotificationRepository {
  Future<List<NotificationItem>> list(
      {bool unreadOnly = false, int limit = 50});
  Future<int> getUnreadCount();
  Future<void> markAsRead(int id);
  Future<void> markAllAsRead();
  Future<void> delete(int id);
}
