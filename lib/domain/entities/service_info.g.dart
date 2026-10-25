// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServiceInfoImpl _$$ServiceInfoImplFromJson(Map<String, dynamic> json) =>
    _$ServiceInfoImpl(
      name: json['name'] as String,
      shortName: json['short_name'] as String?,
      description: json['description'] as String?,
      state: json['state'] as String,
      subState: json['sub_state'] as String?,
      unitFileState: json['unit_file_state'] as String?,
      enabled: json['enabled'] as bool?,
      pid: (json['pid'] as num?)?.toInt(),
      memoryBytes: (json['memory_bytes'] as num?)?.toInt(),
      cpuPercent: (json['cpu_percent'] as num?)?.toDouble(),
      uptimeSeconds: (json['uptime_seconds'] as num?)?.toInt(),
      managed: json['managed'] as bool?,
    );

Map<String, dynamic> _$$ServiceInfoImplToJson(_$ServiceInfoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'short_name': instance.shortName,
      'description': instance.description,
      'state': instance.state,
      'sub_state': instance.subState,
      'unit_file_state': instance.unitFileState,
      'enabled': instance.enabled,
      'pid': instance.pid,
      'memory_bytes': instance.memoryBytes,
      'cpu_percent': instance.cpuPercent,
      'uptime_seconds': instance.uptimeSeconds,
      'managed': instance.managed,
    };
