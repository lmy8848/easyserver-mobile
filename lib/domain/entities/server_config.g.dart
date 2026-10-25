// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServerConfigImpl _$$ServerConfigImplFromJson(Map<String, dynamic> json) =>
    _$ServerConfigImpl(
      host: json['host'] as String,
      port: (json['port'] as num).toInt(),
      useTls: json['useTls'] as bool? ?? false,
      token: json['token'] as String? ?? '',
    );

Map<String, dynamic> _$$ServerConfigImplToJson(_$ServerConfigImpl instance) =>
    <String, dynamic>{
      'host': instance.host,
      'port': instance.port,
      'useTls': instance.useTls,
      'token': instance.token,
    };
