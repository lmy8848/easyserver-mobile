import '../../domain/repositories/settings_repository.dart';
import '../datasources/remote/api_client.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final ApiClient _api;
  SettingsRepositoryImpl(this._api);

  @override
  Future<Map<String, dynamic>> getSettings() async => await _api.get('/settings');

  @override
  Future<Map<String, dynamic>> getSystemInfo() async => await _api.get('/settings/system');

  @override
  Future<bool> updateServer(Map<String, dynamic> data) async {
    await _api.put('/settings/server', data: data);
    return true;
  }

  @override
  Future<bool> updateTls(Map<String, dynamic> data) async {
    await _api.put('/settings/tls', data: data);
    return true;
  }

  @override
  Future<bool> updateAuth(Map<String, dynamic> data) async {
    await _api.put('/settings/auth', data: data);
    return true;
  }

  @override
  Future<bool> updateMonitor(Map<String, dynamic> data) async {
    await _api.put('/settings/monitor', data: data);
    return true;
  }

  @override
  Future<bool> updateNotify(Map<String, dynamic> data) async {
    await _api.put('/settings/notify', data: data);
    return true;
  }

  @override
  Future<void> restart({bool force = false}) async {
    await _api.post('/settings/restart', data: force ? {'force': true} : null);
  }
}
