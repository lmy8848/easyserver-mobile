import 'package:freezed_annotation/freezed_annotation.dart';
part 'server_config.freezed.dart';
part 'server_config.g.dart';

@freezed
class ServerConfig with _$ServerConfig {
  const factory ServerConfig({
    required String host,
    required int port,
    @Default(false) bool useTls,
    @Default('') String token,
  }) = _ServerConfig;

  const ServerConfig._();

  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);

  static ServerConfig fromUrl(String url) {
    final uri = Uri.parse(url);
    return ServerConfig(
      host: uri.host,
      port: uri.port,
      useTls: uri.scheme == 'https',
    );
  }

  String get baseUrl => '${useTls ? "https" : "http"}://$host:$port';
  String get wsUrl => '${useTls ? "wss" : "ws"}://$host:$port';
}
