import '../entities/auth_result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthResult> login(String username, String password,
      {String? turnstileToken});
  Future<AuthResult> verifyTotp(String tempToken, String code,
      {String? turnstileToken});
  Future<AuthResult> verifyBackupCode(String tempToken, String backupCode,
      {String? turnstileToken});
  Future<User> getProfile();
  Future<void> logout();
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<bool> getTotpStatus();
  Future<Map<String, dynamic>> setupTotp();
  Future<List<String>> enableTotp(String code);
  Future<void> disableTotp(String password);
  Future<void> confirmQrLogin(String qrToken);
  Future<Map<String, dynamic>> getTurnstileConfig();
  Future<List<Map<String, dynamic>>> getSessions();
  Future<void> kickSession(String token);
  Future<void> kickAllOtherSessions();
}
