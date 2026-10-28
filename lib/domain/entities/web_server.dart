import 'package:freezed_annotation/freezed_annotation.dart';

part 'web_server.freezed.dart';
part 'web_server.g.dart';

/// Web 服务器（后端 web.WebServer）
@freezed
class WebServer with _$WebServer {
  const factory WebServer({
    @Default(0) int id,
    @Default('') String name,
    @JsonKey(name: 'display_name') @Default('') String displayName,
    @Default('') String description,
    @JsonKey(name: 'service_name') @Default('') String serviceName,
    @JsonKey(name: 'default_port') @Default(0) int defaultPort,
    @Default('') String status,
    @Default('') String version,
    @Default(0) int pid,
    @JsonKey(name: 'memory_bytes') @Default(0) int memoryBytes,
    @Default('') String uptime,
    @JsonKey(name: 'auto_start') @Default(false) bool autoStart,
  }) = _WebServer;

  factory WebServer.fromJson(Map<String, dynamic> json) =>
      _$WebServerFromJson(json);
}

/// 配置检测结果（GET /web-servers/:id/test-config，后端真实执行检测命令）
@freezed
class WebConfigTest with _$WebConfigTest {
  const factory WebConfigTest({
    @Default(false) bool valid,
    @Default('') String message,
  }) = _WebConfigTest;

  factory WebConfigTest.fromJson(Map<String, dynamic> json) =>
      _$WebConfigTestFromJson(json);
}

/// 网站（后端 web.Website）
@freezed
class Website with _$Website {
  const factory Website({
    @Default(0) int id,
    @JsonKey(name: 'web_server_id') @Default(0) int webServerId,
    @Default('') String name,
    @Default('') String domain,
    @JsonKey(name: 'root_path') @Default('') String rootPath,
    @Default(0) int port,
    @JsonKey(name: 'project_type') @Default('static') String projectType,
    @JsonKey(name: 'app_port') @Default(0) int appPort,
    @JsonKey(name: 'ssl_enabled') @Default(false) bool sslEnabled,
    @JsonKey(name: 'proxy_enabled') @Default(false) bool proxyEnabled,
    @JsonKey(name: 'proxy_pass') @Default('') String proxyPass,
    @JsonKey(name: 'start_command') @Default('') String startCommand,
    @Default('') String status,
  }) = _Website;

  factory Website.fromJson(Map<String, dynamic> json) =>
      _$WebsiteFromJson(json);
}

/// 新建网站请求（后端 CreateWebsiteRequest，必填 name/domain/root_path）
class CreateWebsiteInput {
  final String name;
  final String domain;
  final String rootPath;
  final int port;
  final String projectType;
  final int appPort;
  final String proxyPass;
  final String startCommand;

  const CreateWebsiteInput({
    required this.name,
    required this.domain,
    required this.rootPath,
    this.port = 0,
    this.projectType = 'static',
    this.appPort = 0,
    this.proxyPass = '',
    this.startCommand = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'domain': domain,
        'root_path': rootPath,
        'port': port,
        'project_type': projectType,
        'app_port': appPort,
        'proxy_pass': proxyPass,
        'start_command': startCommand,
      };
}
