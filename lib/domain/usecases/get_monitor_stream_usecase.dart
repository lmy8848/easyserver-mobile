import '../entities/monitor_snapshot.dart';
import '../repositories/monitor_repository.dart';

class GetMonitorStreamUseCase {
  final MonitorRepository _repo;
  GetMonitorStreamUseCase(this._repo);
  Stream<MonitorSnapshot> call() => _repo.streamMonitor();
}
