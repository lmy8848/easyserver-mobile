// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'container_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ContainerPort _$ContainerPortFromJson(Map<String, dynamic> json) {
  return _ContainerPort.fromJson(json);
}

/// @nodoc
mixin _$ContainerPort {
  @JsonKey(name: 'host_port')
  String? get hostPort => throw _privateConstructorUsedError;
  @JsonKey(name: 'container_port')
  String? get containerPort => throw _privateConstructorUsedError;
  String? get protocol => throw _privateConstructorUsedError;

  /// Serializes this ContainerPort to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContainerPort
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContainerPortCopyWith<ContainerPort> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContainerPortCopyWith<$Res> {
  factory $ContainerPortCopyWith(
          ContainerPort value, $Res Function(ContainerPort) then) =
      _$ContainerPortCopyWithImpl<$Res, ContainerPort>;
  @useResult
  $Res call(
      {@JsonKey(name: 'host_port') String? hostPort,
      @JsonKey(name: 'container_port') String? containerPort,
      String? protocol});
}

/// @nodoc
class _$ContainerPortCopyWithImpl<$Res, $Val extends ContainerPort>
    implements $ContainerPortCopyWith<$Res> {
  _$ContainerPortCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContainerPort
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hostPort = freezed,
    Object? containerPort = freezed,
    Object? protocol = freezed,
  }) {
    return _then(_value.copyWith(
      hostPort: freezed == hostPort
          ? _value.hostPort
          : hostPort // ignore: cast_nullable_to_non_nullable
              as String?,
      containerPort: freezed == containerPort
          ? _value.containerPort
          : containerPort // ignore: cast_nullable_to_non_nullable
              as String?,
      protocol: freezed == protocol
          ? _value.protocol
          : protocol // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ContainerPortImplCopyWith<$Res>
    implements $ContainerPortCopyWith<$Res> {
  factory _$$ContainerPortImplCopyWith(
          _$ContainerPortImpl value, $Res Function(_$ContainerPortImpl) then) =
      __$$ContainerPortImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'host_port') String? hostPort,
      @JsonKey(name: 'container_port') String? containerPort,
      String? protocol});
}

/// @nodoc
class __$$ContainerPortImplCopyWithImpl<$Res>
    extends _$ContainerPortCopyWithImpl<$Res, _$ContainerPortImpl>
    implements _$$ContainerPortImplCopyWith<$Res> {
  __$$ContainerPortImplCopyWithImpl(
      _$ContainerPortImpl _value, $Res Function(_$ContainerPortImpl) _then)
      : super(_value, _then);

  /// Create a copy of ContainerPort
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hostPort = freezed,
    Object? containerPort = freezed,
    Object? protocol = freezed,
  }) {
    return _then(_$ContainerPortImpl(
      hostPort: freezed == hostPort
          ? _value.hostPort
          : hostPort // ignore: cast_nullable_to_non_nullable
              as String?,
      containerPort: freezed == containerPort
          ? _value.containerPort
          : containerPort // ignore: cast_nullable_to_non_nullable
              as String?,
      protocol: freezed == protocol
          ? _value.protocol
          : protocol // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ContainerPortImpl implements _ContainerPort {
  const _$ContainerPortImpl(
      {@JsonKey(name: 'host_port') this.hostPort,
      @JsonKey(name: 'container_port') this.containerPort,
      this.protocol});

  factory _$ContainerPortImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContainerPortImplFromJson(json);

  @override
  @JsonKey(name: 'host_port')
  final String? hostPort;
  @override
  @JsonKey(name: 'container_port')
  final String? containerPort;
  @override
  final String? protocol;

  @override
  String toString() {
    return 'ContainerPort(hostPort: $hostPort, containerPort: $containerPort, protocol: $protocol)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContainerPortImpl &&
            (identical(other.hostPort, hostPort) ||
                other.hostPort == hostPort) &&
            (identical(other.containerPort, containerPort) ||
                other.containerPort == containerPort) &&
            (identical(other.protocol, protocol) ||
                other.protocol == protocol));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, hostPort, containerPort, protocol);

  /// Create a copy of ContainerPort
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContainerPortImplCopyWith<_$ContainerPortImpl> get copyWith =>
      __$$ContainerPortImplCopyWithImpl<_$ContainerPortImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContainerPortImplToJson(
      this,
    );
  }
}

abstract class _ContainerPort implements ContainerPort {
  const factory _ContainerPort(
      {@JsonKey(name: 'host_port') final String? hostPort,
      @JsonKey(name: 'container_port') final String? containerPort,
      final String? protocol}) = _$ContainerPortImpl;

  factory _ContainerPort.fromJson(Map<String, dynamic> json) =
      _$ContainerPortImpl.fromJson;

  @override
  @JsonKey(name: 'host_port')
  String? get hostPort;
  @override
  @JsonKey(name: 'container_port')
  String? get containerPort;
  @override
  String? get protocol;

  /// Create a copy of ContainerPort
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContainerPortImplCopyWith<_$ContainerPortImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ContainerInfo _$ContainerInfoFromJson(Map<String, dynamic> json) {
  return _ContainerInfo.fromJson(json);
}

/// @nodoc
mixin _$ContainerInfo {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get image => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  List<ContainerPort> get ports => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'running_for')
  String? get runningFor => throw _privateConstructorUsedError;

  /// Serializes this ContainerInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContainerInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContainerInfoCopyWith<ContainerInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContainerInfoCopyWith<$Res> {
  factory $ContainerInfoCopyWith(
          ContainerInfo value, $Res Function(ContainerInfo) then) =
      _$ContainerInfoCopyWithImpl<$Res, ContainerInfo>;
  @useResult
  $Res call(
      {String id,
      String name,
      String image,
      String status,
      String state,
      List<ContainerPort> ports,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'running_for') String? runningFor});
}

/// @nodoc
class _$ContainerInfoCopyWithImpl<$Res, $Val extends ContainerInfo>
    implements $ContainerInfoCopyWith<$Res> {
  _$ContainerInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContainerInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? image = null,
    Object? status = null,
    Object? state = null,
    Object? ports = null,
    Object? createdAt = freezed,
    Object? runningFor = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      ports: null == ports
          ? _value.ports
          : ports // ignore: cast_nullable_to_non_nullable
              as List<ContainerPort>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      runningFor: freezed == runningFor
          ? _value.runningFor
          : runningFor // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ContainerInfoImplCopyWith<$Res>
    implements $ContainerInfoCopyWith<$Res> {
  factory _$$ContainerInfoImplCopyWith(
          _$ContainerInfoImpl value, $Res Function(_$ContainerInfoImpl) then) =
      __$$ContainerInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String image,
      String status,
      String state,
      List<ContainerPort> ports,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'running_for') String? runningFor});
}

/// @nodoc
class __$$ContainerInfoImplCopyWithImpl<$Res>
    extends _$ContainerInfoCopyWithImpl<$Res, _$ContainerInfoImpl>
    implements _$$ContainerInfoImplCopyWith<$Res> {
  __$$ContainerInfoImplCopyWithImpl(
      _$ContainerInfoImpl _value, $Res Function(_$ContainerInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ContainerInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? image = null,
    Object? status = null,
    Object? state = null,
    Object? ports = null,
    Object? createdAt = freezed,
    Object? runningFor = freezed,
  }) {
    return _then(_$ContainerInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      ports: null == ports
          ? _value._ports
          : ports // ignore: cast_nullable_to_non_nullable
              as List<ContainerPort>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      runningFor: freezed == runningFor
          ? _value.runningFor
          : runningFor // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ContainerInfoImpl extends _ContainerInfo {
  const _$ContainerInfoImpl(
      {required this.id,
      required this.name,
      required this.image,
      required this.status,
      required this.state,
      final List<ContainerPort> ports = const [],
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'running_for') this.runningFor})
      : _ports = ports,
        super._();

  factory _$ContainerInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContainerInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String image;
  @override
  final String status;
  @override
  final String state;
  final List<ContainerPort> _ports;
  @override
  @JsonKey()
  List<ContainerPort> get ports {
    if (_ports is EqualUnmodifiableListView) return _ports;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ports);
  }

  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'running_for')
  final String? runningFor;

  @override
  String toString() {
    return 'ContainerInfo(id: $id, name: $name, image: $image, status: $status, state: $state, ports: $ports, createdAt: $createdAt, runningFor: $runningFor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContainerInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.state, state) || other.state == state) &&
            const DeepCollectionEquality().equals(other._ports, _ports) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.runningFor, runningFor) ||
                other.runningFor == runningFor));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, image, status, state,
      const DeepCollectionEquality().hash(_ports), createdAt, runningFor);

  /// Create a copy of ContainerInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContainerInfoImplCopyWith<_$ContainerInfoImpl> get copyWith =>
      __$$ContainerInfoImplCopyWithImpl<_$ContainerInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContainerInfoImplToJson(
      this,
    );
  }
}

abstract class _ContainerInfo extends ContainerInfo {
  const factory _ContainerInfo(
          {required final String id,
          required final String name,
          required final String image,
          required final String status,
          required final String state,
          final List<ContainerPort> ports,
          @JsonKey(name: 'created_at') final String? createdAt,
          @JsonKey(name: 'running_for') final String? runningFor}) =
      _$ContainerInfoImpl;
  const _ContainerInfo._() : super._();

  factory _ContainerInfo.fromJson(Map<String, dynamic> json) =
      _$ContainerInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get image;
  @override
  String get status;
  @override
  String get state;
  @override
  List<ContainerPort> get ports;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'running_for')
  String? get runningFor;

  /// Create a copy of ContainerInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContainerInfoImplCopyWith<_$ContainerInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
