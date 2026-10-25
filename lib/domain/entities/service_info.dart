import 'package:freezed_annotation/freezed_annotation.dart';
part 'service_info.freezed.dart';
part 'service_info.g.dart';

@freezed
class ServiceInfo with _$ServiceInfo {
  const factory ServiceInfo({
    required String name,
    // 后端 systemd.ServiceInfo 无 display_name/category 字段；
    // short_name 为托管服务去前缀短名（系统服务等于 name）
    @JsonKey(name: 'short_name') String? shortName,
    String? description,
    required String state,
    @JsonKey(name: 'sub_state') String? subState,
    @JsonKey(name: 'unit_file_state') String? unitFileState,
    bool? enabled,
    int? pid,
    @JsonKey(name: 'memory_bytes') int? memoryBytes,
    @JsonKey(name: 'cpu_percent') double? cpuPercent,
    @JsonKey(name: 'uptime_seconds') int? uptimeSeconds,
    bool? managed,
  }) = _ServiceInfo;

  factory ServiceInfo.fromJson(Map<String, dynamic> json) =>
      _$ServiceInfoFromJson(json);
}
