// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'container_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContainerPortImpl _$$ContainerPortImplFromJson(Map<String, dynamic> json) =>
    _$ContainerPortImpl(
      hostPort: json['host_port'] as String?,
      containerPort: json['container_port'] as String?,
      protocol: json['protocol'] as String?,
    );

Map<String, dynamic> _$$ContainerPortImplToJson(_$ContainerPortImpl instance) =>
    <String, dynamic>{
      'host_port': instance.hostPort,
      'container_port': instance.containerPort,
      'protocol': instance.protocol,
    };

_$ContainerInfoImpl _$$ContainerInfoImplFromJson(Map<String, dynamic> json) =>
    _$ContainerInfoImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      status: json['status'] as String,
      state: json['state'] as String,
      ports: (json['ports'] as List<dynamic>?)
              ?.map((e) => ContainerPort.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] as String?,
      runningFor: json['running_for'] as String?,
    );

Map<String, dynamic> _$$ContainerInfoImplToJson(_$ContainerInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image': instance.image,
      'status': instance.status,
      'state': instance.state,
      'ports': instance.ports,
      'created_at': instance.createdAt,
      'running_for': instance.runningFor,
    };
