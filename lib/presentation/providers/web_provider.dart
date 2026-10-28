import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/action_guard.dart';
import '../../di/providers.dart';
import '../../domain/entities/web_server.dart';

/// Web 服务器列表（后端返回前已刷新状态）
final webServersProvider =
    FutureProvider.autoDispose<List<WebServer>>((ref) {
  return ref.read(webRepositoryProvider).listServers();
});

/// 指定服务器的网站列表：增删/启停后 invalidate
final websitesProvider = FutureProvider.autoDispose
    .family<List<Website>, int>((ref, serverId) {
  return ref.read(webRepositoryProvider).listWebsites(serverId);
});

/// 网站管理操作：写操作全部经 ActionGuard 去重
class WebActions {
  final Ref _ref;
  WebActions(this._ref);

  Future<bool> serverAction(String action, WebServer server) async {
    final repo = _ref.read(webRepositoryProvider);
    final ok = await globalActionGuard.run<bool>('web:server:$action:${server.id}',
        () async {
      switch (action) {
        case 'start':
          await repo.startServer(server.id);
        case 'stop':
          await repo.stopServer(server.id);
        case 'restart':
          await repo.restartServer(server.id);
        case 'reload':
          await repo.reloadServer(server.id);
        default:
          return false;
      }
      return true;
    });
    if (ok == true) _ref.invalidate(webServersProvider);
    return ok ?? false;
  }

  Future<bool> websiteAction(
      String action, int serverId, Website site) async {
    final repo = _ref.read(webRepositoryProvider);
    final ok =
        await globalActionGuard.run<bool>('web:site:$action:${site.id}',
            () async {
      switch (action) {
        case 'enable':
          await repo.enableWebsite(serverId, site.id);
        case 'disable':
          await repo.disableWebsite(serverId, site.id);
        case 'delete':
          await repo.deleteWebsite(serverId, site.id);
        default:
          return false;
      }
      return true;
    });
    if (ok == true) _ref.invalidate(websitesProvider(serverId));
    return ok ?? false;
  }

  Future<bool> createWebsite(
      int serverId, CreateWebsiteInput input) async {
    final ok = await globalActionGuard.run<bool>(
        'web:site:create:$serverId',
        () => _ref
            .read(webRepositoryProvider)
            .createWebsite(serverId, input)
            .then((_) => true));
    if (ok == true) _ref.invalidate(websitesProvider(serverId));
    return ok ?? false;
  }

  void refreshServers() => _ref.invalidate(webServersProvider);

  void refreshWebsites(int serverId) =>
      _ref.invalidate(websitesProvider(serverId));
}

final webActionsProvider = Provider<WebActions>((ref) => WebActions(ref));
