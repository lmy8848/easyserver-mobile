import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/mobile_direct.dart';
import '../data/datasources/local/device_identity.dart';
import '../data/datasources/local/secure_storage.dart';
import '../data/datasources/local/settings_storage.dart';
import '../data/datasources/remote/api_client.dart';
import '../data/datasources/remote/ws_client.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/monitor_repository_impl.dart';
import '../data/repositories/service_repository_impl.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../data/repositories/file_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/monitor_repository.dart';
import '../domain/repositories/service_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/repositories/file_repository.dart';
import '../data/repositories/cron_repository_impl.dart';
import '../domain/repositories/cron_repository.dart';
import '../data/repositories/firewall_repository_impl.dart';
import '../domain/repositories/firewall_repository.dart';
import '../data/repositories/share_repository_impl.dart';
import '../domain/repositories/share_repository.dart';
import '../data/repositories/web_repository_impl.dart';
import '../domain/repositories/web_repository.dart';
import '../domain/entities/server_config.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

final deviceIdentityProvider = Provider<DeviceIdentity>((ref) {
  return DeviceIdentity(ref.read(secureStorageProvider));
});

final settingsStorageProvider = Provider<SettingsStorage>((ref) {
  final storage = SettingsStorage();
  storage.init();
  return storage;
});

final serverConfigProvider =
    StateNotifierProvider<ServerConfigNotifier, ServerConfig?>((ref) {
  return ServerConfigNotifier(ref.read(secureStorageProvider));
});

class ServerConfigNotifier extends StateNotifier<ServerConfig?> {
  final SecureStorage _storage;
  ServerConfigNotifier(this._storage) : super(null);

  Future<void> loadConfig() async {
    final url = await _storage.getServerUrl();
    if (url != null && url.isNotEmpty) {
      state = ServerConfig.fromUrl(url);
    }
  }

  Future<void> setConfig(ServerConfig config) async {
    state = config;
    final url =
        '${config.useTls ? "https" : "http"}://${config.host}:${config.port}';
    await _storage.saveServerUrl(url);
  }

  Future<void> clearConfig() async {
    state = null;
    await _storage.deleteServerUrl();
  }
}

/// 应用本地已保存的直连配置到 ApiClient（启动、切换服务器后调用）。
Future<void> applyDirectSettings(WidgetRef ref) async {
  final api = ref.read(apiClientProvider);
  final md = MobileDirect.instance;
  final enabled = await md.isEnabled();
  final url = await md.directUrl();
  if (!enabled || url == null || url.isEmpty) {
    api.configureDirect(enabled: false);
    return;
  }
  final deviceId = await ref.read(deviceIdentityProvider).deviceId();
  final fingerprint = await md.fingerprint();
  if (fingerprint == null || fingerprint.isEmpty) {
    // 没有固定指纹就不启用直连：宁可用 CF，也不能接受未校验的证书
    api.configureDirect(enabled: false);
    return;
  }
  api.configureDirect(
    enabled: true,
    url: url,
    signer: (method, uri) =>
        md.signHeaders(method: method, uri: uri, deviceId: deviceId),
    clientFactory: () => md.pinnedHttpClientFor(fingerprint),
  );
}

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(baseUrl: 'http://localhost:8080'));

final wsClientProvider = Provider<WsClient>((ref) => WsClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.read(apiClientProvider);
  final repo = AuthRepositoryImpl(
    api,
    ref.read(secureStorageProvider),
    ref.read(deviceIdentityProvider),
  );
  // 401 静默刷新（单飞逻辑在 ApiClient 内）
  api.onRefreshRequested = repo.refreshAccess;
  return repo;
});

final monitorRepositoryProvider = Provider<MonitorRepository>((ref) {
  return MonitorRepositoryImpl(
      ref.read(apiClientProvider), ref.read(wsClientProvider));
});

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepositoryImpl(
      ref.read(apiClientProvider), ref.read(wsClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.read(apiClientProvider));
});

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return FileRepositoryImpl(ref.read(apiClientProvider));
});

final cronRepositoryProvider = Provider<CronRepository>((ref) {
  return CronRepositoryImpl(ref.read(apiClientProvider));
});

final firewallRepositoryProvider = Provider<FirewallRepository>((ref) {
  return FirewallRepositoryImpl(ref.read(apiClientProvider));
});

final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  return ShareRepositoryImpl(ref.read(apiClientProvider));
});

final webRepositoryProvider = Provider<WebRepository>((ref) {
  return WebRepositoryImpl(ref.read(apiClientProvider));
});
