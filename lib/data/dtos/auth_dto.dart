import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';

class AuthDto {
  static AuthResult fromLogin(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        mustChangePass: json['must_change_pass'] as bool? ?? false,
        requiresTotp: json['requires_totp'] as bool? ?? false,
        tempToken: json['temp_token'] as String?,
      );
}
