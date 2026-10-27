import '../../domain/entities/cron_task.dart';
import '../../domain/repositories/cron_repository.dart';
import '../datasources/remote/api_client.dart';

class CronRepositoryImpl implements CronRepository {
  final ApiClient _api;

  CronRepositoryImpl(this._api);

  @override
  Future<List<CronTask>> list() async {
    // 后端分页参数是 page_size（默认 50），这里一次取到上限 200
    final data = await _api
        .get('/cron/tasks', queryParameters: {'page': 1, 'page_size': 200});
    final items = (data['items'] ?? data['_items']) as List<dynamic>? ?? [];
    return items
        .map((e) => CronTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CronTask> get(String name) async {
    final json = await _api.get('/cron/tasks/$name');
    return CronTask.fromJson(json);
  }

  @override
  Future<void> create(CronTaskInput input) async {
    await _api.post('/cron/tasks', data: input.toJson());
  }

  @override
  Future<void> update(String name, CronTaskInput input) async {
    await _api.put('/cron/tasks/$name', data: input.toJson());
  }

  @override
  Future<void> delete(String name) async {
    await _api.delete('/cron/tasks/$name');
  }

  @override
  Future<void> enable(String name) async {
    await _api.post('/cron/tasks/$name/enable');
  }

  @override
  Future<void> disable(String name) async {
    await _api.post('/cron/tasks/$name/disable');
  }

  @override
  Future<void> run(String name) async {
    await _api.post('/cron/tasks/$name/run');
  }

  @override
  Future<List<CronRun>> runs(String name, {int page = 1, int size = 20}) async {
    final data = await _api.get('/cron/tasks/$name/runs',
        queryParameters: {'page': page, 'page_size': size});
    final items = (data['items'] ?? data['_items']) as List<dynamic>? ?? [];
    return items
        .map((e) => CronRun.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
