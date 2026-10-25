import '../entities/monitor_snapshot.dart';

abstract class MonitorRepository {
  Future<MonitorSnapshot> getStats();
  Future<List<MonitorSnapshot>> getHistory({String? start, String? end});
  Stream<MonitorSnapshot> streamMonitor();
  void disconnectMonitor();
}
