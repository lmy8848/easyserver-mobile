abstract class SettingsRepository {
  Future<Map<String, dynamic>> getSettings();
  Future<Map<String, dynamic>> getSystemInfo();
  Future<bool> updateServer(Map<String, dynamic> data);
  Future<bool> updateTls(Map<String, dynamic> data);
  Future<bool> updateAuth(Map<String, dynamic> data);
  Future<bool> updateMonitor(Map<String, dynamic> data);
  Future<bool> updateNotify(Map<String, dynamic> data);
  Future<void> restart({bool force = false});
}
