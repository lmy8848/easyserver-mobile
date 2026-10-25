import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repo;
  LoginUseCase(this._repo);

  Future<AuthResult> call(String username, String password, {String? turnstileToken}) {
    if (username.trim().isEmpty) throw ArgumentError('用户名不能为空');
    if (password.isEmpty) throw ArgumentError('密码不能为空');
    return _repo.login(username.trim(), password, turnstileToken: turnstileToken);
  }
}
