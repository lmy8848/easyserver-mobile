import 'package:freezed_annotation/freezed_annotation.dart';
part 'notification_item.freezed.dart';
part 'notification_item.g.dart';

@freezed
class NotificationItem with _$NotificationItem {
  const factory NotificationItem({
    required int id,
    required String type,
    required String title,
    required String message,
    required String level,
    @JsonKey(name: 'is_read') required bool isRead,
    String? metadata,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _NotificationItem;

  factory NotificationItem.fromJson(Map<String, dynamic> json) => _$NotificationItemFromJson(json);
}
