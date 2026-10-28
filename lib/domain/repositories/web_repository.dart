import '../entities/web_server.dart';

abstract class WebRepository {
  /// Web 服务器列表（后端返回前会刷新状态）
  Future<List<WebServer>> listServers();

  Future<void> startServer(int id);
  Future<void> stopServer(int id);
  Future<void> restartServer(int id);
  Future<void> reloadServer(int id);

  /// 指定服务器的网站列表
  Future<List<Website>> listWebsites(int serverId);

  /// 配置检测（后端真实执行 nginx -t 等检测命令）
  Future<WebConfigTest> testConfig(int serverId);

  Future<void> createWebsite(int serverId, CreateWebsiteInput input);
  Future<void> deleteWebsite(int serverId, int websiteId);
  Future<void> enableWebsite(int serverId, int websiteId);
  Future<void> disableWebsite(int serverId, int websiteId);
}
