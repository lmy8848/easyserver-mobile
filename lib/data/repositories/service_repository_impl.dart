import 'dart:async';
import '../../domain/entities/service_info.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/remote/api_client.dart';
import '../datasources/remote/ws_client.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ApiClient _api;
  final WsClient _wsClient;
  final Map<String, StreamController<String>> _logControllers = {};

  ServiceRepositoryImpl(this._api, this._wsClient);

  @override
  Future<List<ServiceInfo>> list() async {
    final data = await _api.get('/services');
    // 后端返回 httpx.Page{items,total}；_unwrapResponse 会把裸列表包成 {'_items': ...}
    final items = (data['items'] ?? data['_items']) as List<dynamic>? ?? [];
    return items
        .map((e) => ServiceInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ServiceInfo>> getDetails(List<String> names) async {
    final data = await _api.post('/services/details', data: {'names': names});
    final items =
        (data['_items'] ?? data['items'] ?? const []) as List<dynamic>;
    return items
        .map((e) => ServiceInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ServiceInfo> get(String name) async {
    final json = await _api.get('/services/$name');
    return ServiceInfo.fromJson(json);
  }

  @override
  Future<void> start(String name) async {
    await _api.post('/services/$name/start');
  }

  @override
  Future<void> stop(String name) async {
    await _api.post('/services/$name/stop');
  }

  @override
  Future<void> restart(String name) async {
    await _api.post('/services/$name/restart');
  }

  @override
  Future<void> enable(String name) async {
    await _api.post('/services/$name/enable');
  }

  @override
  Future<void> disable(String name) async {
    await _api.post('/services/$name/disable');
  }

  @override
  Future<List<Map<String, dynamic>>> getLogs(String name, {int? tail}) async {
    final params = <String, dynamic>{};
    if (tail != null) params['tail'] = tail;
    final json =
        await _api.get('/services/$name/logs', queryParameters: params);
    return (json['lines'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        [];
  }

  @override
  Stream<String> streamServiceLogs(String name) {
    final controller = StreamController<String>.broadcast();
    _logControllers[name] = controller;
    _wsClient.stream.listen((msg) {
      if (msg['type'] == 'log') {
        controller.add(msg['data'] as String? ?? '');
      }
    });
    return controller.stream;
  }

  @override
  void disconnectServiceLogs(String name) {
    _logControllers[name]?.close();
    _logControllers.remove(name);
  }
}
