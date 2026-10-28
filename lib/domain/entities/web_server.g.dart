// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WebServerImpl _$$WebServerImplFromJson(Map<String, dynamic> json) =>
    _$WebServerImpl(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      defaultPort: (json['default_port'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      version: json['version'] as String? ?? '',
      pid: (json['pid'] as num?)?.toInt() ?? 0,
      memoryBytes: (json['memory_bytes'] as num?)?.toInt() ?? 0,
      uptime: json['uptime'] as String? ?? '',
      autoStart: json['auto_start'] as bool? ?? false,
    );

Map<String, dynamic> _$$WebServerImplToJson(_$WebServerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'display_name': instance.displayName,
      'description': instance.description,
      'service_name': instance.serviceName,
      'default_port': instance.defaultPort,
      'status': instance.status,
      'version': instance.version,
      'pid': instance.pid,
      'memory_bytes': instance.memoryBytes,
      'uptime': instance.uptime,
      'auto_start': instance.autoStart,
    };

_$WebConfigTestImpl _$$WebConfigTestImplFromJson(Map<String, dynamic> json) =>
    _$WebConfigTestImpl(
      valid: json['valid'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );

Map<String, dynamic> _$$WebConfigTestImplToJson(_$WebConfigTestImpl instance) =>
    <String, dynamic>{
      'valid': instance.valid,
      'message': instance.message,
    };

_$WebsiteImpl _$$WebsiteImplFromJson(Map<String, dynamic> json) =>
    _$WebsiteImpl(
      id: (json['id'] as num?)?.toInt() ?? 0,
      webServerId: (json['web_server_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      rootPath: json['root_path'] as String? ?? '',
      port: (json['port'] as num?)?.toInt() ?? 0,
      projectType: json['project_type'] as String? ?? 'static',
      appPort: (json['app_port'] as num?)?.toInt() ?? 0,
      sslEnabled: json['ssl_enabled'] as bool? ?? false,
      proxyEnabled: json['proxy_enabled'] as bool? ?? false,
      proxyPass: json['proxy_pass'] as String? ?? '',
      startCommand: json['start_command'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );

Map<String, dynamic> _$$WebsiteImplToJson(_$WebsiteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'web_server_id': instance.webServerId,
      'name': instance.name,
      'domain': instance.domain,
      'root_path': instance.rootPath,
      'port': instance.port,
      'project_type': instance.projectType,
      'app_port': instance.appPort,
      'ssl_enabled': instance.sslEnabled,
      'proxy_enabled': instance.proxyEnabled,
      'proxy_pass': instance.proxyPass,
      'start_command': instance.startCommand,
      'status': instance.status,
    };
