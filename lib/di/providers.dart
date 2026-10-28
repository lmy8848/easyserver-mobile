import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/local/device_identity.dart';
import '../data/datasources/local/secure_storage.dart';
import '../data/datasources/local/settings_storage.dart';
import '../data/datasources/remote/api_client.dart';
import '../data/datasources/remote/ws_client.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/monitor_repository_impl.dart';
import '../data/repositories/service_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../data/repositories/file_repository_impl.dart';
import '../data/repositories/terminal_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/monitor_repository.dart';
import '../domain/repositories/service_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/repositories/file_repository.dart';
import '../domain/repositories/terminal_repository.dart';
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

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(baseUrl: 'http://localhost:8080'));

final wsClientProvider = Provider<WsClient>((ref) => WsClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(apiClientProvider),
    ref.read(secureStorageProvider),
    ref.read(deviceIdentityProvider),
  );
});

final monitorRepositoryProvider = Provider<MonitorRepository>((ref) {
  return MonitorRepositoryImpl(
      ref.read(apiClientProvider), ref.read(wsClientProvider));
});

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepositoryImpl(
      ref.read(apiClientProvider), ref.read(wsClientProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.read(apiClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.read(apiClientProvider));
});

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return FileRepositoryImpl(ref.read(apiClientProvider));
});

final terminalRepositoryProvider = Provider<TerminalRepository>((ref) {
  return TerminalRepositoryImpl(ref.read(wsClientProvider));
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
