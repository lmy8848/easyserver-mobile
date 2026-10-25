import '../../domain/entities/container_info.dart';
import '../../domain/repositories/container_repository.dart';
import '../datasources/remote/api_client.dart';

class ContainerRepositoryImpl implements ContainerRepository {
  final ApiClient _api;
  ContainerRepositoryImpl(this._api);

  @override
  Future<bool> engineAvailable() async {
    final json = await _api.get('/container/status');
    return json['installed'] == true && json['running'] == true;
  }

  @override
  Future<List<ContainerInfo>> list() async {
    // all=true 包含已停止的容器
    final data = await _api
        .get('/container/instances', queryParameters: {'all': 'true'});
    final items =
        (data['items'] ?? data['_items'] ?? const []) as List<dynamic>;
    return items
        .map((e) => ContainerInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> start(String id) => _api.post('/container/instances/$id/start');

  @override
  Future<void> stop(String id) => _api.post('/container/instances/$id/stop');

  @override
  Future<void> restart(String id) =>
      _api.post('/container/instances/$id/restart');

  @override
  Future<void> remove(String id) => _api.delete('/container/instances/$id');

  @override
  Future<String> logs(String id, {int tail = 200}) async {
    final json = await _api
        .get('/container/instances/$id/logs', queryParameters: {'tail': tail});
    return json['logs'] as String? ?? '';
  }
}
