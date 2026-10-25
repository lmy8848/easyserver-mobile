import '../entities/container_info.dart';

abstract class ContainerRepository {
  /// 引擎是否可用（未安装/未运行时列表等操作给出引导提示）
  Future<bool> engineAvailable();
  Future<List<ContainerInfo>> list();
  Future<void> start(String id);
  Future<void> stop(String id);
  Future<void> restart(String id);
  Future<void> remove(String id);
  Future<String> logs(String id, {int tail = 200});
}
