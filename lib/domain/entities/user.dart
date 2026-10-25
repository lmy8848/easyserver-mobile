import 'package:freezed_annotation/freezed_annotation.dart';
part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String username,
    required String role,
    @JsonKey(name: 'must_change_pass') @Default(false) bool mustChangePass,
    @JsonKey(name: 'last_login_at') String? lastLoginAt,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'is_locked') @Default(false) bool isLocked,
    @JsonKey(name: 'ip_whitelist') String? ipWhitelist,
    @JsonKey(name: 'totp_enabled') @Default(false) bool totpEnabled,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
