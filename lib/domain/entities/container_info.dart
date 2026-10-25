import 'package:freezed_annotation/freezed_annotation.dart';
part 'container_info.freezed.dart';
part 'container_info.g.dart';

@freezed
class ContainerPort with _$ContainerPort {
  const factory ContainerPort({
    @JsonKey(name: 'host_port') String? hostPort,
    @JsonKey(name: 'container_port') String? containerPort,
    String? protocol,
  }) = _ContainerPort;

  factory ContainerPort.fromJson(Map<String, dynamic> json) =>
      _$ContainerPortFromJson(json);
}

@freezed
class ContainerInfo with _$ContainerInfo {
  const factory ContainerInfo({
    required String id,
    required String name,
    required String image,
    required String status,
    required String state,
    @Default([]) List<ContainerPort> ports,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'running_for') String? runningFor,
  }) = _ContainerInfo;

  const ContainerInfo._();

  bool get isRunning => state == 'running';

  factory ContainerInfo.fromJson(Map<String, dynamic> json) =>
      _$ContainerInfoFromJson(json);
}
