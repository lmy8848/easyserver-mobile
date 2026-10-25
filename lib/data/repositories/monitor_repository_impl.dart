import 'dart:async';
import '../../domain/entities/monitor_snapshot.dart';
import '../../domain/repositories/monitor_repository.dart';
import '../datasources/remote/api_client.dart';
import '../datasources/remote/ws_client.dart';
import '../dtos/monitor_dto.dart';

class MonitorRepositoryImpl implements MonitorRepository {
  final ApiClient _api;
  final WsClient _wsClient;
  StreamController<MonitorSnapshot>? _controller;

  MonitorRepositoryImpl(this._api, this._wsClient);

  @override
  Future<MonitorSnapshot> getStats() async {
    final json = await _api.get('/monitor/stats');
    return MonitorDto.fromJson(json);
  }

  @override
  Future<List<MonitorSnapshot>> getHistory({String? start, String? end}) async {
    final params = <String, dynamic>{};
    if (start != null) params['start'] = start;
    if (end != null) params['end'] = end;
    final json = await _api.get('/monitor/history', queryParameters: params);
    return MonitorDto.historyFromJson(json);
  }

  @override
  Stream<MonitorSnapshot> streamMonitor() {
    _controller = StreamController<MonitorSnapshot>.broadcast();
    _wsClient.stream.listen((msg) {
      if (msg['type'] == 'snapshot') {
        final snapshot = MonitorSnapshot.fromJson(msg['data'] as Map<String, dynamic>);
        _controller?.add(snapshot);
      }
    });
    return _controller!.stream;
  }

  @override
  void disconnectMonitor() {
    _wsClient.disconnect();
    _controller?.close();
    _controller = null;
  }
}
