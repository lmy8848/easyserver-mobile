import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _tokenKey = 'jwt_token';
  static const _serverUrlKey = 'server_url';
  static const _usernameKey = 'saved_username';
  static const _deviceIdKey = 'device_id';

  // JWT is a sensitive credential -> encrypted at rest via FlutterSecureStorage.
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // --- JWT token (encrypted at rest) ---
  Future<void> saveToken(String token) async {
    await _secure.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secure.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _secure.delete(key: _tokenKey);
  }

  // --- device_id (per-install identifier, not secret) ---
  Future<String?> getDeviceId() async {
    final p = await _prefs;
    return p.getString(_deviceIdKey);
  }

  Future<void> saveDeviceId(String id) async {
    final p = await _prefs;
    await p.setString(_deviceIdKey, id);
  }

  // --- server url ---
  Future<void> saveServerUrl(String url) async {
    final p = await _prefs;
    await p.setString(_serverUrlKey, url);
  }

  Future<String?> getServerUrl() async {
    final p = await _prefs;
    return p.getString(_serverUrlKey);
  }

  Future<void> deleteServerUrl() async {
    final p = await _prefs;
    await p.remove(_serverUrlKey);
  }

  // --- username ---
  Future<void> saveUsername(String username) async {
    final p = await _prefs;
    await p.setString(_usernameKey, username);
  }

  Future<String?> getUsername() async {
    final p = await _prefs;
    return p.getString(_usernameKey);
  }

  Future<void> deleteUsername() async {
    final p = await _prefs;
    await p.remove(_usernameKey);
  }

  Future<void> clearAll() async {
    await _secure.delete(key: _tokenKey);
    final p = await _prefs;
    await p.remove(_serverUrlKey);
    await p.remove(_usernameKey);
    await p.remove(_deviceIdKey);
  }
}
