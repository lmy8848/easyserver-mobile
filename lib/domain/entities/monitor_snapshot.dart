import 'package:freezed_annotation/freezed_annotation.dart';
part 'monitor_snapshot.freezed.dart';
part 'monitor_snapshot.g.dart';

@freezed
class CpuInfo with _$CpuInfo {
  const factory CpuInfo({
    @JsonKey(name: 'usage_percent') required double usagePercent,
    @JsonKey(name: 'load_1m') required double load1m,
    @JsonKey(name: 'load_5m') required double load5m,
    @JsonKey(name: 'load_15m') required double load15m,
  }) = _CpuInfo;

  factory CpuInfo.fromJson(Map<String, dynamic> json) =>
      _$CpuInfoFromJson(json);
}

@freezed
class MemoryInfo with _$MemoryInfo {
  const factory MemoryInfo({
    @JsonKey(name: 'total_bytes') required int totalBytes,
    @JsonKey(name: 'used_bytes') required int usedBytes,
    @JsonKey(name: 'usage_percent') required double usagePercent,
  }) = _MemoryInfo;

  factory MemoryInfo.fromJson(Map<String, dynamic> json) =>
      _$MemoryInfoFromJson(json);
}

@freezed
class DiskInfo with _$DiskInfo {
  const factory DiskInfo({
    @JsonKey(name: 'mount_point') required String mountPoint,
    @JsonKey(name: 'total_bytes') required int totalBytes,
    @JsonKey(name: 'used_bytes') required int usedBytes,
    @JsonKey(name: 'usage_percent') required double usagePercent,
  }) = _DiskInfo;

  factory DiskInfo.fromJson(Map<String, dynamic> json) =>
      _$DiskInfoFromJson(json);
}

@freezed
class NetworkInfo with _$NetworkInfo {
  const factory NetworkInfo({
    @JsonKey(name: 'bytes_sent') required int bytesSent,
    @JsonKey(name: 'bytes_recv') required int bytesRecv,
  }) = _NetworkInfo;

  factory NetworkInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkInfoFromJson(json);
}

@freezed
class ProcessInfo with _$ProcessInfo {
  const factory ProcessInfo({
    required int pid,
    required String name,
    required String user,
    @JsonKey(name: 'cpu_percent') required double cpuPercent,
    @JsonKey(name: 'mem_percent') required double memPercent,
    @JsonKey(name: 'mem_bytes') required int memBytes,
    required String state,
  }) = _ProcessInfo;

  factory ProcessInfo.fromJson(Map<String, dynamic> json) =>
      _$ProcessInfoFromJson(json);
}

@freezed
class SystemInfo with _$SystemInfo {
  const factory SystemInfo({
    required String hostname,
    required String os,
    required String kernel,
    required String arch,
    @JsonKey(name: 'cpu_cores') required int cpuCores,
    @JsonKey(name: 'uptime_seconds') required int uptimeSeconds,
  }) = _SystemInfo;

  factory SystemInfo.fromJson(Map<String, dynamic> json) =>
      _$SystemInfoFromJson(json);
}

@freezed
class MonitorSnapshot with _$MonitorSnapshot {
  const factory MonitorSnapshot({
    required CpuInfo cpu,
    required MemoryInfo memory,
    required List<DiskInfo> disk,
    required NetworkInfo network,
    SystemInfo? system,
    @JsonKey(name: 'top_process') List<ProcessInfo>? topProcess,
    required String timestamp,
  }) = _MonitorSnapshot;

  factory MonitorSnapshot.fromJson(Map<String, dynamic> json) =>
      _$MonitorSnapshotFromJson(json);
}
