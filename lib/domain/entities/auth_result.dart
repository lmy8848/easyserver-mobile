import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';
part 'auth_result.freezed.dart';
part 'auth_result.g.dart';

@freezed
class AuthResult with _$AuthResult {
  const factory AuthResult({
    required String token,
    required User user,
    @JsonKey(name: 'must_change_pass') required bool mustChangePass,
    @JsonKey(name: 'requires_totp') @Default(false) bool requiresTotp,
    @JsonKey(name: 'temp_token') String? tempToken,
  }) = _AuthResult;

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);
}
