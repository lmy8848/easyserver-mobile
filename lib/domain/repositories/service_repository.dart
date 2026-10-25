import '../entities/service_info.dart';

abstract class ServiceRepository {
  Future<List<ServiceInfo>> list();
  Future<List<ServiceInfo>> getDetails(List<String> names);
  Future<ServiceInfo> get(String name);
  Future<void> start(String name);
  Future<void> stop(String name);
  Future<void> restart(String name);
  Future<void> enable(String name);
  Future<void> disable(String name);
  Future<List<Map<String, dynamic>>> getLogs(String name, {int? tail});
  Stream<String> streamServiceLogs(String name);
  void disconnectServiceLogs(String name);
}
