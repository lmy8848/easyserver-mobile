// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'web_server.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WebServer _$WebServerFromJson(Map<String, dynamic> json) {
  return _WebServer.fromJson(json);
}

/// @nodoc
mixin _$WebServer {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'service_name')
  String get serviceName => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_port')
  int get defaultPort => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  int get pid => throw _privateConstructorUsedError;
  @JsonKey(name: 'memory_bytes')
  int get memoryBytes => throw _privateConstructorUsedError;
  String get uptime => throw _privateConstructorUsedError;
  @JsonKey(name: 'auto_start')
  bool get autoStart => throw _privateConstructorUsedError;

  /// Serializes this WebServer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WebServer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WebServerCopyWith<WebServer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebServerCopyWith<$Res> {
  factory $WebServerCopyWith(WebServer value, $Res Function(WebServer) then) =
      _$WebServerCopyWithImpl<$Res, WebServer>;
  @useResult
  $Res call(
      {int id,
      String name,
      @JsonKey(name: 'display_name') String displayName,
      String description,
      @JsonKey(name: 'service_name') String serviceName,
      @JsonKey(name: 'default_port') int defaultPort,
      String status,
      String version,
      int pid,
      @JsonKey(name: 'memory_bytes') int memoryBytes,
      String uptime,
      @JsonKey(name: 'auto_start') bool autoStart});
}

/// @nodoc
class _$WebServerCopyWithImpl<$Res, $Val extends WebServer>
    implements $WebServerCopyWith<$Res> {
  _$WebServerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WebServer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? displayName = null,
    Object? description = null,
    Object? serviceName = null,
    Object? defaultPort = null,
    Object? status = null,
    Object? version = null,
    Object? pid = null,
    Object? memoryBytes = null,
    Object? uptime = null,
    Object? autoStart = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      serviceName: null == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      defaultPort: null == defaultPort
          ? _value.defaultPort
          : defaultPort // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      pid: null == pid
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as int,
      memoryBytes: null == memoryBytes
          ? _value.memoryBytes
          : memoryBytes // ignore: cast_nullable_to_non_nullable
              as int,
      uptime: null == uptime
          ? _value.uptime
          : uptime // ignore: cast_nullable_to_non_nullable
              as String,
      autoStart: null == autoStart
          ? _value.autoStart
          : autoStart // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WebServerImplCopyWith<$Res>
    implements $WebServerCopyWith<$Res> {
  factory _$$WebServerImplCopyWith(
          _$WebServerImpl value, $Res Function(_$WebServerImpl) then) =
      __$$WebServerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      @JsonKey(name: 'display_name') String displayName,
      String description,
      @JsonKey(name: 'service_name') String serviceName,
      @JsonKey(name: 'default_port') int defaultPort,
      String status,
      String version,
      int pid,
      @JsonKey(name: 'memory_bytes') int memoryBytes,
      String uptime,
      @JsonKey(name: 'auto_start') bool autoStart});
}

/// @nodoc
class __$$WebServerImplCopyWithImpl<$Res>
    extends _$WebServerCopyWithImpl<$Res, _$WebServerImpl>
    implements _$$WebServerImplCopyWith<$Res> {
  __$$WebServerImplCopyWithImpl(
      _$WebServerImpl _value, $Res Function(_$WebServerImpl) _then)
      : super(_value, _then);

  /// Create a copy of WebServer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? displayName = null,
    Object? description = null,
    Object? serviceName = null,
    Object? defaultPort = null,
    Object? status = null,
    Object? version = null,
    Object? pid = null,
    Object? memoryBytes = null,
    Object? uptime = null,
    Object? autoStart = null,
  }) {
    return _then(_$WebServerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      serviceName: null == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      defaultPort: null == defaultPort
          ? _value.defaultPort
          : defaultPort // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      pid: null == pid
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as int,
      memoryBytes: null == memoryBytes
          ? _value.memoryBytes
          : memoryBytes // ignore: cast_nullable_to_non_nullable
              as int,
      uptime: null == uptime
          ? _value.uptime
          : uptime // ignore: cast_nullable_to_non_nullable
              as String,
      autoStart: null == autoStart
          ? _value.autoStart
          : autoStart // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WebServerImpl implements _WebServer {
  const _$WebServerImpl(
      {this.id = 0,
      this.name = '',
      @JsonKey(name: 'display_name') this.displayName = '',
      this.description = '',
      @JsonKey(name: 'service_name') this.serviceName = '',
      @JsonKey(name: 'default_port') this.defaultPort = 0,
      this.status = '',
      this.version = '',
      this.pid = 0,
      @JsonKey(name: 'memory_bytes') this.memoryBytes = 0,
      this.uptime = '',
      @JsonKey(name: 'auto_start') this.autoStart = false});

  factory _$WebServerImpl.fromJson(Map<String, dynamic> json) =>
      _$$WebServerImplFromJson(json);

  @override
  @JsonKey()
  final int id;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey(name: 'service_name')
  final String serviceName;
  @override
  @JsonKey(name: 'default_port')
  final int defaultPort;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final String version;
  @override
  @JsonKey()
  final int pid;
  @override
  @JsonKey(name: 'memory_bytes')
  final int memoryBytes;
  @override
  @JsonKey()
  final String uptime;
  @override
  @JsonKey(name: 'auto_start')
  final bool autoStart;

  @override
  String toString() {
    return 'WebServer(id: $id, name: $name, displayName: $displayName, description: $description, serviceName: $serviceName, defaultPort: $defaultPort, status: $status, version: $version, pid: $pid, memoryBytes: $memoryBytes, uptime: $uptime, autoStart: $autoStart)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebServerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.defaultPort, defaultPort) ||
                other.defaultPort == defaultPort) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.pid, pid) || other.pid == pid) &&
            (identical(other.memoryBytes, memoryBytes) ||
                other.memoryBytes == memoryBytes) &&
            (identical(other.uptime, uptime) || other.uptime == uptime) &&
            (identical(other.autoStart, autoStart) ||
                other.autoStart == autoStart));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      displayName,
      description,
      serviceName,
      defaultPort,
      status,
      version,
      pid,
      memoryBytes,
      uptime,
      autoStart);

  /// Create a copy of WebServer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WebServerImplCopyWith<_$WebServerImpl> get copyWith =>
      __$$WebServerImplCopyWithImpl<_$WebServerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WebServerImplToJson(
      this,
    );
  }
}

abstract class _WebServer implements WebServer {
  const factory _WebServer(
      {final int id,
      final String name,
      @JsonKey(name: 'display_name') final String displayName,
      final String description,
      @JsonKey(name: 'service_name') final String serviceName,
      @JsonKey(name: 'default_port') final int defaultPort,
      final String status,
      final String version,
      final int pid,
      @JsonKey(name: 'memory_bytes') final int memoryBytes,
      final String uptime,
      @JsonKey(name: 'auto_start') final bool autoStart}) = _$WebServerImpl;

  factory _WebServer.fromJson(Map<String, dynamic> json) =
      _$WebServerImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  String get description;
  @override
  @JsonKey(name: 'service_name')
  String get serviceName;
  @override
  @JsonKey(name: 'default_port')
  int get defaultPort;
  @override
  String get status;
  @override
  String get version;
  @override
  int get pid;
  @override
  @JsonKey(name: 'memory_bytes')
  int get memoryBytes;
  @override
  String get uptime;
  @override
  @JsonKey(name: 'auto_start')
  bool get autoStart;

  /// Create a copy of WebServer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WebServerImplCopyWith<_$WebServerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WebConfigTest _$WebConfigTestFromJson(Map<String, dynamic> json) {
  return _WebConfigTest.fromJson(json);
}

/// @nodoc
mixin _$WebConfigTest {
  bool get valid => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;

  /// Serializes this WebConfigTest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WebConfigTest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WebConfigTestCopyWith<WebConfigTest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebConfigTestCopyWith<$Res> {
  factory $WebConfigTestCopyWith(
          WebConfigTest value, $Res Function(WebConfigTest) then) =
      _$WebConfigTestCopyWithImpl<$Res, WebConfigTest>;
  @useResult
  $Res call({bool valid, String message});
}

/// @nodoc
class _$WebConfigTestCopyWithImpl<$Res, $Val extends WebConfigTest>
    implements $WebConfigTestCopyWith<$Res> {
  _$WebConfigTestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WebConfigTest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? valid = null,
    Object? message = null,
  }) {
    return _then(_value.copyWith(
      valid: null == valid
          ? _value.valid
          : valid // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WebConfigTestImplCopyWith<$Res>
    implements $WebConfigTestCopyWith<$Res> {
  factory _$$WebConfigTestImplCopyWith(
          _$WebConfigTestImpl value, $Res Function(_$WebConfigTestImpl) then) =
      __$$WebConfigTestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool valid, String message});
}

/// @nodoc
class __$$WebConfigTestImplCopyWithImpl<$Res>
    extends _$WebConfigTestCopyWithImpl<$Res, _$WebConfigTestImpl>
    implements _$$WebConfigTestImplCopyWith<$Res> {
  __$$WebConfigTestImplCopyWithImpl(
      _$WebConfigTestImpl _value, $Res Function(_$WebConfigTestImpl) _then)
      : super(_value, _then);

  /// Create a copy of WebConfigTest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? valid = null,
    Object? message = null,
  }) {
    return _then(_$WebConfigTestImpl(
      valid: null == valid
          ? _value.valid
          : valid // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WebConfigTestImpl implements _WebConfigTest {
  const _$WebConfigTestImpl({this.valid = false, this.message = ''});

  factory _$WebConfigTestImpl.fromJson(Map<String, dynamic> json) =>
      _$$WebConfigTestImplFromJson(json);

  @override
  @JsonKey()
  final bool valid;
  @override
  @JsonKey()
  final String message;

  @override
  String toString() {
    return 'WebConfigTest(valid: $valid, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebConfigTestImpl &&
            (identical(other.valid, valid) || other.valid == valid) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, valid, message);

  /// Create a copy of WebConfigTest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WebConfigTestImplCopyWith<_$WebConfigTestImpl> get copyWith =>
      __$$WebConfigTestImplCopyWithImpl<_$WebConfigTestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WebConfigTestImplToJson(
      this,
    );
  }
}

abstract class _WebConfigTest implements WebConfigTest {
  const factory _WebConfigTest({final bool valid, final String message}) =
      _$WebConfigTestImpl;

  factory _WebConfigTest.fromJson(Map<String, dynamic> json) =
      _$WebConfigTestImpl.fromJson;

  @override
  bool get valid;
  @override
  String get message;

  /// Create a copy of WebConfigTest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WebConfigTestImplCopyWith<_$WebConfigTestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Website _$WebsiteFromJson(Map<String, dynamic> json) {
  return _Website.fromJson(json);
}

/// @nodoc
mixin _$Website {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'web_server_id')
  int get webServerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get domain => throw _privateConstructorUsedError;
  @JsonKey(name: 'root_path')
  String get rootPath => throw _privateConstructorUsedError;
  int get port => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_type')
  String get projectType => throw _privateConstructorUsedError;
  @JsonKey(name: 'app_port')
  int get appPort => throw _privateConstructorUsedError;
  @JsonKey(name: 'ssl_enabled')
  bool get sslEnabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'proxy_enabled')
  bool get proxyEnabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'proxy_pass')
  String get proxyPass => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_command')
  String get startCommand => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Serializes this Website to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Website
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WebsiteCopyWith<Website> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebsiteCopyWith<$Res> {
  factory $WebsiteCopyWith(Website value, $Res Function(Website) then) =
      _$WebsiteCopyWithImpl<$Res, Website>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'web_server_id') int webServerId,
      String name,
      String domain,
      @JsonKey(name: 'root_path') String rootPath,
      int port,
      @JsonKey(name: 'project_type') String projectType,
      @JsonKey(name: 'app_port') int appPort,
      @JsonKey(name: 'ssl_enabled') bool sslEnabled,
      @JsonKey(name: 'proxy_enabled') bool proxyEnabled,
      @JsonKey(name: 'proxy_pass') String proxyPass,
      @JsonKey(name: 'start_command') String startCommand,
      String status});
}

/// @nodoc
class _$WebsiteCopyWithImpl<$Res, $Val extends Website>
    implements $WebsiteCopyWith<$Res> {
  _$WebsiteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Website
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? webServerId = null,
    Object? name = null,
    Object? domain = null,
    Object? rootPath = null,
    Object? port = null,
    Object? projectType = null,
    Object? appPort = null,
    Object? sslEnabled = null,
    Object? proxyEnabled = null,
    Object? proxyPass = null,
    Object? startCommand = null,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      webServerId: null == webServerId
          ? _value.webServerId
          : webServerId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      domain: null == domain
          ? _value.domain
          : domain // ignore: cast_nullable_to_non_nullable
              as String,
      rootPath: null == rootPath
          ? _value.rootPath
          : rootPath // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      projectType: null == projectType
          ? _value.projectType
          : projectType // ignore: cast_nullable_to_non_nullable
              as String,
      appPort: null == appPort
          ? _value.appPort
          : appPort // ignore: cast_nullable_to_non_nullable
              as int,
      sslEnabled: null == sslEnabled
          ? _value.sslEnabled
          : sslEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      proxyEnabled: null == proxyEnabled
          ? _value.proxyEnabled
          : proxyEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      proxyPass: null == proxyPass
          ? _value.proxyPass
          : proxyPass // ignore: cast_nullable_to_non_nullable
              as String,
      startCommand: null == startCommand
          ? _value.startCommand
          : startCommand // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WebsiteImplCopyWith<$Res> implements $WebsiteCopyWith<$Res> {
  factory _$$WebsiteImplCopyWith(
          _$WebsiteImpl value, $Res Function(_$WebsiteImpl) then) =
      __$$WebsiteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'web_server_id') int webServerId,
      String name,
      String domain,
      @JsonKey(name: 'root_path') String rootPath,
      int port,
      @JsonKey(name: 'project_type') String projectType,
      @JsonKey(name: 'app_port') int appPort,
      @JsonKey(name: 'ssl_enabled') bool sslEnabled,
      @JsonKey(name: 'proxy_enabled') bool proxyEnabled,
      @JsonKey(name: 'proxy_pass') String proxyPass,
      @JsonKey(name: 'start_command') String startCommand,
      String status});
}

/// @nodoc
class __$$WebsiteImplCopyWithImpl<$Res>
    extends _$WebsiteCopyWithImpl<$Res, _$WebsiteImpl>
    implements _$$WebsiteImplCopyWith<$Res> {
  __$$WebsiteImplCopyWithImpl(
      _$WebsiteImpl _value, $Res Function(_$WebsiteImpl) _then)
      : super(_value, _then);

  /// Create a copy of Website
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? webServerId = null,
    Object? name = null,
    Object? domain = null,
    Object? rootPath = null,
    Object? port = null,
    Object? projectType = null,
    Object? appPort = null,
    Object? sslEnabled = null,
    Object? proxyEnabled = null,
    Object? proxyPass = null,
    Object? startCommand = null,
    Object? status = null,
  }) {
    return _then(_$WebsiteImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      webServerId: null == webServerId
          ? _value.webServerId
          : webServerId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      domain: null == domain
          ? _value.domain
          : domain // ignore: cast_nullable_to_non_nullable
              as String,
      rootPath: null == rootPath
          ? _value.rootPath
          : rootPath // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as int,
      projectType: null == projectType
          ? _value.projectType
          : projectType // ignore: cast_nullable_to_non_nullable
              as String,
      appPort: null == appPort
          ? _value.appPort
          : appPort // ignore: cast_nullable_to_non_nullable
              as int,
      sslEnabled: null == sslEnabled
          ? _value.sslEnabled
          : sslEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      proxyEnabled: null == proxyEnabled
          ? _value.proxyEnabled
          : proxyEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      proxyPass: null == proxyPass
          ? _value.proxyPass
          : proxyPass // ignore: cast_nullable_to_non_nullable
              as String,
      startCommand: null == startCommand
          ? _value.startCommand
          : startCommand // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WebsiteImpl implements _Website {
  const _$WebsiteImpl(
      {this.id = 0,
      @JsonKey(name: 'web_server_id') this.webServerId = 0,
      this.name = '',
      this.domain = '',
      @JsonKey(name: 'root_path') this.rootPath = '',
      this.port = 0,
      @JsonKey(name: 'project_type') this.projectType = 'static',
      @JsonKey(name: 'app_port') this.appPort = 0,
      @JsonKey(name: 'ssl_enabled') this.sslEnabled = false,
      @JsonKey(name: 'proxy_enabled') this.proxyEnabled = false,
      @JsonKey(name: 'proxy_pass') this.proxyPass = '',
      @JsonKey(name: 'start_command') this.startCommand = '',
      this.status = ''});

  factory _$WebsiteImpl.fromJson(Map<String, dynamic> json) =>
      _$$WebsiteImplFromJson(json);

  @override
  @JsonKey()
  final int id;
  @override
  @JsonKey(name: 'web_server_id')
  final int webServerId;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String domain;
  @override
  @JsonKey(name: 'root_path')
  final String rootPath;
  @override
  @JsonKey()
  final int port;
  @override
  @JsonKey(name: 'project_type')
  final String projectType;
  @override
  @JsonKey(name: 'app_port')
  final int appPort;
  @override
  @JsonKey(name: 'ssl_enabled')
  final bool sslEnabled;
  @override
  @JsonKey(name: 'proxy_enabled')
  final bool proxyEnabled;
  @override
  @JsonKey(name: 'proxy_pass')
  final String proxyPass;
  @override
  @JsonKey(name: 'start_command')
  final String startCommand;
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'Website(id: $id, webServerId: $webServerId, name: $name, domain: $domain, rootPath: $rootPath, port: $port, projectType: $projectType, appPort: $appPort, sslEnabled: $sslEnabled, proxyEnabled: $proxyEnabled, proxyPass: $proxyPass, startCommand: $startCommand, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebsiteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.webServerId, webServerId) ||
                other.webServerId == webServerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.domain, domain) || other.domain == domain) &&
            (identical(other.rootPath, rootPath) ||
                other.rootPath == rootPath) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.projectType, projectType) ||
                other.projectType == projectType) &&
            (identical(other.appPort, appPort) || other.appPort == appPort) &&
            (identical(other.sslEnabled, sslEnabled) ||
                other.sslEnabled == sslEnabled) &&
            (identical(other.proxyEnabled, proxyEnabled) ||
                other.proxyEnabled == proxyEnabled) &&
            (identical(other.proxyPass, proxyPass) ||
                other.proxyPass == proxyPass) &&
            (identical(other.startCommand, startCommand) ||
                other.startCommand == startCommand) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      webServerId,
      name,
      domain,
      rootPath,
      port,
      projectType,
      appPort,
      sslEnabled,
      proxyEnabled,
      proxyPass,
      startCommand,
      status);

  /// Create a copy of Website
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WebsiteImplCopyWith<_$WebsiteImpl> get copyWith =>
      __$$WebsiteImplCopyWithImpl<_$WebsiteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WebsiteImplToJson(
      this,
    );
  }
}

abstract class _Website implements Website {
  const factory _Website(
      {final int id,
      @JsonKey(name: 'web_server_id') final int webServerId,
      final String name,
      final String domain,
      @JsonKey(name: 'root_path') final String rootPath,
      final int port,
      @JsonKey(name: 'project_type') final String projectType,
      @JsonKey(name: 'app_port') final int appPort,
      @JsonKey(name: 'ssl_enabled') final bool sslEnabled,
      @JsonKey(name: 'proxy_enabled') final bool proxyEnabled,
      @JsonKey(name: 'proxy_pass') final String proxyPass,
      @JsonKey(name: 'start_command') final String startCommand,
      final String status}) = _$WebsiteImpl;

  factory _Website.fromJson(Map<String, dynamic> json) = _$WebsiteImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'web_server_id')
  int get webServerId;
  @override
  String get name;
  @override
  String get domain;
  @override
  @JsonKey(name: 'root_path')
  String get rootPath;
  @override
  int get port;
  @override
  @JsonKey(name: 'project_type')
  String get projectType;
  @override
  @JsonKey(name: 'app_port')
  int get appPort;
  @override
  @JsonKey(name: 'ssl_enabled')
  bool get sslEnabled;
  @override
  @JsonKey(name: 'proxy_enabled')
  bool get proxyEnabled;
  @override
  @JsonKey(name: 'proxy_pass')
  String get proxyPass;
  @override
  @JsonKey(name: 'start_command')
  String get startCommand;
  @override
  String get status;

  /// Create a copy of Website
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WebsiteImplCopyWith<_$WebsiteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
