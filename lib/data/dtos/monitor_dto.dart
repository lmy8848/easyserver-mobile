import '../../domain/entities/monitor_snapshot.dart';

class MonitorDto {
  static MonitorSnapshot fromJson(Map<String, dynamic> json) => MonitorSnapshot.fromJson(json);

  static List<MonitorSnapshot> historyFromJson(Map<String, dynamic> json) {
    final points = json['points'] as List<dynamic>? ?? [];
    return points.map((e) => MonitorSnapshot.fromJson(e as Map<String, dynamic>)).toList();
  }
}
