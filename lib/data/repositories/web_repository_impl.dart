import '../../domain/entities/web_server.dart';
import '../../domain/repositories/web_repository.dart';
import '../datasources/remote/api_client.dart';

class WebRepositoryImpl implements WebRepository {
  final ApiClient _api;

  WebRepositoryImpl(this._api);

  @override
  Future<List<WebServer>> listServers() async {
    final data = await _api
        .get('/web-servers', queryParameters: {'page': 1, 'page_size': 50});
    final items = (data['items'] ?? data['_items']) as List<dynamic>? ?? [];
    return items
        .map((e) => WebServer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> startServer(int id) async {
    await _api.post('/web-servers/$id/start');
  }

  @override
  Future<void> stopServer(int id) async {
    await _api.post('/web-servers/$id/stop');
  }

  @override
  Future<void> restartServer(int id) async {
    await _api.post('/web-servers/$id/restart');
  }

  @override
  Future<void> reloadServer(int id) async {
    await _api.post('/web-servers/$id/reload');
  }

  @override
  Future<List<Website>> listWebsites(int serverId) async {
    final data = await _api.get('/web-servers/$serverId/websites',
        queryParameters: {'page': 1, 'page_size': 100});
    final items = (data['items'] ?? data['_items']) as List<dynamic>? ?? [];
    return items
        .map((e) => Website.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createWebsite(int serverId, CreateWebsiteInput input) async {
    await _api.post('/web-servers/$serverId/websites', data: input.toJson());
  }

  @override
  Future<void> deleteWebsite(int serverId, int websiteId) async {
    await _api.delete('/web-servers/$serverId/websites/$websiteId');
  }

  @override
  Future<void> enableWebsite(int serverId, int websiteId) async {
    await _api.post('/web-servers/$serverId/websites/$websiteId/enable');
  }

  @override
  Future<void> disableWebsite(int serverId, int websiteId) async {
    await _api.post('/web-servers/$serverId/websites/$websiteId/disable');
  }
}
