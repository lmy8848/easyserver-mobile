import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/device_identity.dart';
import '../datasources/local/secure_storage.dart';
import '../datasources/remote/api_client.dart';
import '../dtos/auth_dto.dart';
import '../services/mobile_direct.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  final SecureStorage _storage;
  final DeviceIdentity _device;

  AuthRepositoryImpl(this._api, this._storage, this._device);

  @override
  Future<AuthResult> login(String username, String password,
      {String? turnstileToken}) async {
    final data = <String, dynamic>{
      'username': username,
      'password': password,
      'client_type': 'mobile',
      'device_id': await _device.deviceId(),
      'device_info': await _device.deviceInfo(),
    };
    if (turnstileToken != null) data['turnstile_token'] = turnstileToken;
    final json = await _api.post('/auth/login', data: data);
    final rt = json['refresh_token'] as String?;
    if (rt != null && rt.isNotEmpty) {
      await _storage.saveRefreshToken(rt);
    }
    final result = AuthDto.fromLogin(json);
    await _storage.saveToken(result.token);
    await _storage.saveUsername(username);
    _api.updateToken(result.token);
    await _registerDeviceBestEffort();
    return result;
  }

  @override
  Future<AuthResult> verifyTotp(String tempToken, String code,
      {String? turnstileToken}) async {
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
  Future<AuthResult> verifyBackupCode(String tempToken, String backupCode,
      {String? turnstileToken}) async {
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
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _storage.deleteToken();
    _api.updateToken(null);
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _api.post('/auth/change-password',
        data: {'old_password': oldPassword, 'new_password': newPassword});
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

  /// 用 refresh 换取新 access（单飞由 ApiClient 负责）。网络错误保留登录态，
  /// 只有服务端明确拒绝（401）才视为失败。
  Future<bool> refreshAccess() async {
    final rt = await _storage.getRefreshToken();
    if (rt == null || rt.isEmpty) return false;
    try {
      final json = await _api.post('/auth/refresh', data: {
        'refresh_token': rt,
        'device_id': await _device.deviceId(),
      });
      final token = json['token'] as String?;
      if (token == null || token.isEmpty) return false;
      await _storage.saveToken(token);
      final newRt = json['refresh_token'] as String?;
      if (newRt != null && newRt.isNotEmpty) {
        await _storage.saveRefreshToken(newRt);
      }
      _api.updateToken(token);
      return true;
    } catch (_) {
      return false;
    }
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
    // 后端返回裸列表；_unwrapResponse 会包成 {'_items': [...]}
    final items =
        (json['_items'] ?? json['items'] ?? const []) as List<dynamic>;
    return items.map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  Future<void> kickSession(String sessionId) async {
    await _api.post('/auth/sessions/kick', data: {'id': sessionId});
  }

  @override
  Future<void> kickAllOtherSessions() async {
    await _api.post('/auth/sessions/kick-all');
  }
  /// 登记本机 Ed25519 公钥（供直连通道校验签名）。失败不影响登录。
  Future<void> _registerDeviceBestEffort() async {
    try {
      await _api.post('/auth/devices', data: {
        'device_id': await _device.deviceId(),
        'public_key': await MobileDirect.instance.publicKeyBase64(),
        'name': await _device.deviceInfo(),
      });
    } catch (_) {}
  }
}
