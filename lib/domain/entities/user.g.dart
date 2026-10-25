// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      role: json['role'] as String,
      mustChangePass: json['must_change_pass'] as bool? ?? false,
      lastLoginAt: json['last_login_at'] as String?,
      createdAt: json['created_at'] as String?,
      isLocked: json['is_locked'] as bool? ?? false,
      ipWhitelist: json['ip_whitelist'] as String?,
      totpEnabled: json['totp_enabled'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'role': instance.role,
      'must_change_pass': instance.mustChangePass,
      'last_login_at': instance.lastLoginAt,
      'created_at': instance.createdAt,
      'is_locked': instance.isLocked,
      'ip_whitelist': instance.ipWhitelist,
      'totp_enabled': instance.totpEnabled,
    };
