import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/device_identity.dart';
import '../datasources/local/secure_storage.dart';
import '../datasources/remote/api_client.dart';
import '../dtos/auth_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  final SecureStorage _storage;
  final DeviceIdentity _device;

  AuthRepositoryImpl(this._api, this._storage, this._device);

  @override
  Future<AuthResult> login(String username, String password, {String? turnstileToken}) async {
    final data = <String, dynamic>{
      'username': username,
      'password': password,
      'client_type': 'mobile',
      'device_id': await _device.deviceId(),
      'device_info': await _device.deviceInfo(),
    };
    if (turnstileToken != null) data['turnstile_token'] = turnstileToken;
    final json = await _api.post('/auth/login', data: data);
    final result = AuthDto.fromLogin(json);
    await _storage.saveToken(result.token);
    await _storage.saveUsername(username);
    _api.updateToken(result.token);
    return result;
  }

  @override
  Future<AuthResult> verifyTotp(String tempToken, String code, {String? turnstileToken}) async {
    final data = <String, dynamic>{
      'temp_token': tempToken,
      'code': code,
      'client_type': 'mobile',
      'device_id': await _device.deviceId(),
      'device_info': await _device.deviceInfo(),
    };
    if (turnstileToken != null) data['turnstile_token'] = turnstileToken;
    final json = await _api.post('/auth/verify-totp', data: data);
    final result = AuthDto.fromLogin(json);
    await _storage.saveToken(result.token);
    _api.updateToken(result.token);
    return result;
  }

  @override
  Future<AuthResult> verifyBackupCode(String tempToken, String backupCode, {String? turnstileToken}) async {
    final data = <String, dynamic>{
      'temp_token': tempToken,
      'backup_code': backupCode,
      'client_type': 'mobile',
      'device_id': await _device.deviceId(),
      'device_info': await _device.deviceInfo(),
    };
    if (turnstileToken != null) data['turnstile_token'] = turnstileToken;
    final json = await _api.post('/auth/verify-backup', data: data);
    final result = AuthDto.fromLogin(json);
    await _storage.saveToken(result.token);
    _api.updateToken(result.token);
    return result;
  }

  @override
  Future<User> getProfile() async {
    final json = await _api.get('/auth/me');
    return User.fromJson(json);
  }

  @override
  Future<void> logout() async {
    try { await _api.post('/auth/logout'); } catch (_) {}
    await _storage.deleteToken();
    _api.updateToken(null);
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _api.post('/auth/change-password', data: {'old_password': oldPassword, 'new_password': newPassword});
  }

  @override
  Future<bool> getTotpStatus() async {
    final json = await _api.get('/auth/totp/status');
    return json['enabled'] as bool? ?? false;
  }

  @override
  Future<Map<String, dynamic>> setupTotp() async {
    return await _api.post('/auth/totp/setup');
  }

  @override
  Future<List<String>> enableTotp(String code) async {
    final json = await _api.post('/auth/totp/enable', data: {'code': code});
    return (json['backup_codes'] as List<dynamic>).cast<String>();
  }

  @override
  Future<void> disableTotp(String password) async {
    await _api.post('/auth/totp/disable', data: {'password': password});
  }

  @override
  Future<void> confirmQrLogin(String qrToken) async {
    await _api.post('/auth/qr/confirm', data: {'qr_token': qrToken});
  }

  @override
  Future<Map<String, dynamic>> getTurnstileConfig() async {
    return await _api.get('/auth/turnstile/config');
  }

  @override
  Future<List<Map<String, dynamic>>> getSessions() async {
    final json = await _api.get('/auth/sessions');
    if (json case List l) {
      return l.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  @override
  Future<void> kickSession(String token) async {
    await _api.post('/auth/sessions/kick', data: {'token': token});
  }

  @override
  Future<void> kickAllOtherSessions() async {
    await _api.post('/auth/sessions/kick-all');
  }
}
