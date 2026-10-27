import '../entities/cron_task.dart';

abstract class CronRepository {
  Future<List<CronTask>> list();
  Future<CronTask> get(String name);
  Future<void> create(CronTaskInput input);
  Future<void> update(String name, CronTaskInput input);
  Future<void> delete(String name);
  Future<void> enable(String name);
  Future<void> disable(String name);

  /// 手动触发一次（后台异步执行，接口立即返回）
  Future<void> run(String name);

  /// 执行历史，最新的在前
  Future<List<CronRun>> runs(String name, {int page = 1, int size = 20});
}
