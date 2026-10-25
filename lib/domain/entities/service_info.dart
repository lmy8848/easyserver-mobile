import 'package:freezed_annotation/freezed_annotation.dart';
part 'service_info.freezed.dart';
part 'service_info.g.dart';

@freezed
class ServiceInfo with _$ServiceInfo {
  const factory ServiceInfo({
    required String name,
    @JsonKey(name: 'display_name') required String displayName,
    String? description,
    String? category,
    required String state,
    @JsonKey(name: 'sub_state') String? subState,
    bool? enabled,
    int? pid,
    @JsonKey(name: 'memory_bytes') int? memoryBytes,
    @JsonKey(name: 'cpu_percent') double? cpuPercent,
    @JsonKey(name: 'uptime_seconds') int? uptimeSeconds,
  }) = _ServiceInfo;

  factory ServiceInfo.fromJson(Map<String, dynamic> json) => _$ServiceInfoFromJson(json);
}
