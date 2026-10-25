// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServiceInfoImpl _$$ServiceInfoImplFromJson(Map<String, dynamic> json) =>
    _$ServiceInfoImpl(
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      state: json['state'] as String,
      subState: json['sub_state'] as String?,
      enabled: json['enabled'] as bool?,
      pid: (json['pid'] as num?)?.toInt(),
      memoryBytes: (json['memory_bytes'] as num?)?.toInt(),
      cpuPercent: (json['cpu_percent'] as num?)?.toDouble(),
      uptimeSeconds: (json['uptime_seconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ServiceInfoImplToJson(_$ServiceInfoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'display_name': instance.displayName,
      'description': instance.description,
      'category': instance.category,
      'state': instance.state,
      'sub_state': instance.subState,
      'enabled': instance.enabled,
      'pid': instance.pid,
      'memory_bytes': instance.memoryBytes,
      'cpu_percent': instance.cpuPercent,
      'uptime_seconds': instance.uptimeSeconds,
    };
