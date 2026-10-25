// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monitor_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CpuInfoImpl _$$CpuInfoImplFromJson(Map<String, dynamic> json) =>
    _$CpuInfoImpl(
      usagePercent: (json['usage_percent'] as num).toDouble(),
      load1m: (json['load_1m'] as num).toDouble(),
      load5m: (json['load_5m'] as num).toDouble(),
      load15m: (json['load_15m'] as num).toDouble(),
    );

Map<String, dynamic> _$$CpuInfoImplToJson(_$CpuInfoImpl instance) =>
    <String, dynamic>{
      'usage_percent': instance.usagePercent,
      'load_1m': instance.load1m,
      'load_5m': instance.load5m,
      'load_15m': instance.load15m,
    };

_$MemoryInfoImpl _$$MemoryInfoImplFromJson(Map<String, dynamic> json) =>
    _$MemoryInfoImpl(
      totalBytes: (json['total_bytes'] as num).toInt(),
      usedBytes: (json['used_bytes'] as num).toInt(),
      usagePercent: (json['usage_percent'] as num).toDouble(),
    );

Map<String, dynamic> _$$MemoryInfoImplToJson(_$MemoryInfoImpl instance) =>
    <String, dynamic>{
      'total_bytes': instance.totalBytes,
      'used_bytes': instance.usedBytes,
      'usage_percent': instance.usagePercent,
    };

_$DiskInfoImpl _$$DiskInfoImplFromJson(Map<String, dynamic> json) =>
    _$DiskInfoImpl(
      mountPoint: json['mount_point'] as String,
      totalBytes: (json['total_bytes'] as num).toInt(),
      usedBytes: (json['used_bytes'] as num).toInt(),
      usagePercent: (json['usage_percent'] as num).toDouble(),
    );

Map<String, dynamic> _$$DiskInfoImplToJson(_$DiskInfoImpl instance) =>
    <String, dynamic>{
      'mount_point': instance.mountPoint,
      'total_bytes': instance.totalBytes,
      'used_bytes': instance.usedBytes,
      'usage_percent': instance.usagePercent,
    };

_$NetworkInfoImpl _$$NetworkInfoImplFromJson(Map<String, dynamic> json) =>
    _$NetworkInfoImpl(
      bytesSent: (json['bytes_sent'] as num).toInt(),
      bytesRecv: (json['bytes_recv'] as num).toInt(),
    );

Map<String, dynamic> _$$NetworkInfoImplToJson(_$NetworkInfoImpl instance) =>
    <String, dynamic>{
      'bytes_sent': instance.bytesSent,
      'bytes_recv': instance.bytesRecv,
    };

_$ProcessInfoImpl _$$ProcessInfoImplFromJson(Map<String, dynamic> json) =>
    _$ProcessInfoImpl(
      pid: (json['pid'] as num).toInt(),
      name: json['name'] as String,
      user: json['user'] as String,
      cpuPercent: (json['cpu_percent'] as num).toDouble(),
      memPercent: (json['mem_percent'] as num).toDouble(),
      memBytes: (json['mem_bytes'] as num).toInt(),
      state: json['state'] as String,
    );

Map<String, dynamic> _$$ProcessInfoImplToJson(_$ProcessInfoImpl instance) =>
    <String, dynamic>{
      'pid': instance.pid,
      'name': instance.name,
      'user': instance.user,
      'cpu_percent': instance.cpuPercent,
      'mem_percent': instance.memPercent,
      'mem_bytes': instance.memBytes,
      'state': instance.state,
    };

_$SystemInfoImpl _$$SystemInfoImplFromJson(Map<String, dynamic> json) =>
    _$SystemInfoImpl(
      hostname: json['hostname'] as String,
      os: json['os'] as String,
      kernel: json['kernel'] as String,
      arch: json['arch'] as String,
      cpuCores: (json['cpu_cores'] as num).toInt(),
      uptimeSeconds: (json['uptime_seconds'] as num).toInt(),
      localIp: json['local_ip'] as String?,
      publicIp: json['public_ip'] as String?,
    );

Map<String, dynamic> _$$SystemInfoImplToJson(_$SystemInfoImpl instance) =>
    <String, dynamic>{
      'hostname': instance.hostname,
      'os': instance.os,
      'kernel': instance.kernel,
      'arch': instance.arch,
      'cpu_cores': instance.cpuCores,
      'uptime_seconds': instance.uptimeSeconds,
      'local_ip': instance.localIp,
      'public_ip': instance.publicIp,
    };

_$MonitorSnapshotImpl _$$MonitorSnapshotImplFromJson(
        Map<String, dynamic> json) =>
    _$MonitorSnapshotImpl(
      cpu: CpuInfo.fromJson(json['cpu'] as Map<String, dynamic>),
      memory: MemoryInfo.fromJson(json['memory'] as Map<String, dynamic>),
      disk: DiskInfo.fromJson(json['disk'] as Map<String, dynamic>),
      network: NetworkInfo.fromJson(json['network'] as Map<String, dynamic>),
      system: json['system'] == null
          ? null
          : SystemInfo.fromJson(json['system'] as Map<String, dynamic>),
      topProcess: (json['top_process'] as List<dynamic>?)
          ?.map((e) => ProcessInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$$MonitorSnapshotImplToJson(
        _$MonitorSnapshotImpl instance) =>
    <String, dynamic>{
      'cpu': instance.cpu,
      'memory': instance.memory,
      'disk': instance.disk,
      'network': instance.network,
      'system': instance.system,
      'top_process': instance.topProcess,
      'timestamp': instance.timestamp,
    };
