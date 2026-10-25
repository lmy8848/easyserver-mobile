// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthResultImpl _$$AuthResultImplFromJson(Map<String, dynamic> json) =>
    _$AuthResultImpl(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      mustChangePass: json['must_change_pass'] as bool,
      requiresTotp: json['requires_totp'] as bool? ?? false,
      tempToken: json['temp_token'] as String?,
    );

Map<String, dynamic> _$$AuthResultImplToJson(_$AuthResultImpl instance) =>
    <String, dynamic>{
      'token': instance.token,
      'user': instance.user,
      'must_change_pass': instance.mustChangePass,
      'requires_totp': instance.requiresTotp,
      'temp_token': instance.tempToken,
    };
