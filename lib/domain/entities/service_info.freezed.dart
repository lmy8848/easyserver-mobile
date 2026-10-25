// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ServiceInfo _$ServiceInfoFromJson(Map<String, dynamic> json) {
  return _ServiceInfo.fromJson(json);
}

/// @nodoc
mixin _$ServiceInfo {
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  @JsonKey(name: 'sub_state')
  String? get subState => throw _privateConstructorUsedError;
  bool? get enabled => throw _privateConstructorUsedError;
  int? get pid => throw _privateConstructorUsedError;
  @JsonKey(name: 'memory_bytes')
  int? get memoryBytes => throw _privateConstructorUsedError;
  @JsonKey(name: 'cpu_percent')
  double? get cpuPercent => throw _privateConstructorUsedError;
  @JsonKey(name: 'uptime_seconds')
  int? get uptimeSeconds => throw _privateConstructorUsedError;

  /// Serializes this ServiceInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ServiceInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServiceInfoCopyWith<ServiceInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceInfoCopyWith<$Res> {
  factory $ServiceInfoCopyWith(
          ServiceInfo value, $Res Function(ServiceInfo) then) =
      _$ServiceInfoCopyWithImpl<$Res, ServiceInfo>;
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'display_name') String displayName,
      String? description,
      String? category,
      String state,
      @JsonKey(name: 'sub_state') String? subState,
      bool? enabled,
      int? pid,
      @JsonKey(name: 'memory_bytes') int? memoryBytes,
      @JsonKey(name: 'cpu_percent') double? cpuPercent,
      @JsonKey(name: 'uptime_seconds') int? uptimeSeconds});
}

/// @nodoc
class _$ServiceInfoCopyWithImpl<$Res, $Val extends ServiceInfo>
    implements $ServiceInfoCopyWith<$Res> {
  _$ServiceInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServiceInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? displayName = null,
    Object? description = freezed,
    Object? category = freezed,
    Object? state = null,
    Object? subState = freezed,
    Object? enabled = freezed,
    Object? pid = freezed,
    Object? memoryBytes = freezed,
    Object? cpuPercent = freezed,
    Object? uptimeSeconds = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      subState: freezed == subState
          ? _value.subState
          : subState // ignore: cast_nullable_to_non_nullable
              as String?,
      enabled: freezed == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool?,
      pid: freezed == pid
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as int?,
      memoryBytes: freezed == memoryBytes
          ? _value.memoryBytes
          : memoryBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      cpuPercent: freezed == cpuPercent
          ? _value.cpuPercent
          : cpuPercent // ignore: cast_nullable_to_non_nullable
              as double?,
      uptimeSeconds: freezed == uptimeSeconds
          ? _value.uptimeSeconds
          : uptimeSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ServiceInfoImplCopyWith<$Res>
    implements $ServiceInfoCopyWith<$Res> {
  factory _$$ServiceInfoImplCopyWith(
          _$ServiceInfoImpl value, $Res Function(_$ServiceInfoImpl) then) =
      __$$ServiceInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      @JsonKey(name: 'display_name') String displayName,
      String? description,
      String? category,
      String state,
      @JsonKey(name: 'sub_state') String? subState,
      bool? enabled,
      int? pid,
      @JsonKey(name: 'memory_bytes') int? memoryBytes,
      @JsonKey(name: 'cpu_percent') double? cpuPercent,
      @JsonKey(name: 'uptime_seconds') int? uptimeSeconds});
}

/// @nodoc
class __$$ServiceInfoImplCopyWithImpl<$Res>
    extends _$ServiceInfoCopyWithImpl<$Res, _$ServiceInfoImpl>
    implements _$$ServiceInfoImplCopyWith<$Res> {
  __$$ServiceInfoImplCopyWithImpl(
      _$ServiceInfoImpl _value, $Res Function(_$ServiceInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServiceInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? displayName = null,
    Object? description = freezed,
    Object? category = freezed,
    Object? state = null,
    Object? subState = freezed,
    Object? enabled = freezed,
    Object? pid = freezed,
    Object? memoryBytes = freezed,
    Object? cpuPercent = freezed,
    Object? uptimeSeconds = freezed,
  }) {
    return _then(_$ServiceInfoImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      subState: freezed == subState
          ? _value.subState
          : subState // ignore: cast_nullable_to_non_nullable
              as String?,
      enabled: freezed == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool?,
      pid: freezed == pid
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as int?,
      memoryBytes: freezed == memoryBytes
          ? _value.memoryBytes
          : memoryBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      cpuPercent: freezed == cpuPercent
          ? _value.cpuPercent
          : cpuPercent // ignore: cast_nullable_to_non_nullable
              as double?,
      uptimeSeconds: freezed == uptimeSeconds
          ? _value.uptimeSeconds
          : uptimeSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ServiceInfoImpl implements _ServiceInfo {
  const _$ServiceInfoImpl(
      {required this.name,
      @JsonKey(name: 'display_name') required this.displayName,
      this.description,
      this.category,
      required this.state,
      @JsonKey(name: 'sub_state') this.subState,
      this.enabled,
      this.pid,
      @JsonKey(name: 'memory_bytes') this.memoryBytes,
      @JsonKey(name: 'cpu_percent') this.cpuPercent,
      @JsonKey(name: 'uptime_seconds') this.uptimeSeconds});

  factory _$ServiceInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServiceInfoImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  final String? description;
  @override
  final String? category;
  @override
  final String state;
  @override
  @JsonKey(name: 'sub_state')
  final String? subState;
  @override
  final bool? enabled;
  @override
  final int? pid;
  @override
  @JsonKey(name: 'memory_bytes')
  final int? memoryBytes;
  @override
  @JsonKey(name: 'cpu_percent')
  final double? cpuPercent;
  @override
  @JsonKey(name: 'uptime_seconds')
  final int? uptimeSeconds;

  @override
  String toString() {
    return 'ServiceInfo(name: $name, displayName: $displayName, description: $description, category: $category, state: $state, subState: $subState, enabled: $enabled, pid: $pid, memoryBytes: $memoryBytes, cpuPercent: $cpuPercent, uptimeSeconds: $uptimeSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceInfoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.subState, subState) ||
                other.subState == subState) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.pid, pid) || other.pid == pid) &&
            (identical(other.memoryBytes, memoryBytes) ||
                other.memoryBytes == memoryBytes) &&
            (identical(other.cpuPercent, cpuPercent) ||
                other.cpuPercent == cpuPercent) &&
            (identical(other.uptimeSeconds, uptimeSeconds) ||
                other.uptimeSeconds == uptimeSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      displayName,
      description,
      category,
      state,
      subState,
      enabled,
      pid,
      memoryBytes,
      cpuPercent,
      uptimeSeconds);

  /// Create a copy of ServiceInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceInfoImplCopyWith<_$ServiceInfoImpl> get copyWith =>
      __$$ServiceInfoImplCopyWithImpl<_$ServiceInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ServiceInfoImplToJson(
      this,
    );
  }
}

abstract class _ServiceInfo implements ServiceInfo {
  const factory _ServiceInfo(
          {required final String name,
          @JsonKey(name: 'display_name') required final String displayName,
          final String? description,
          final String? category,
          required final String state,
          @JsonKey(name: 'sub_state') final String? subState,
          final bool? enabled,
          final int? pid,
          @JsonKey(name: 'memory_bytes') final int? memoryBytes,
          @JsonKey(name: 'cpu_percent') final double? cpuPercent,
          @JsonKey(name: 'uptime_seconds') final int? uptimeSeconds}) =
      _$ServiceInfoImpl;

  factory _ServiceInfo.fromJson(Map<String, dynamic> json) =
      _$ServiceInfoImpl.fromJson;

  @override
  String get name;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  String? get description;
  @override
  String? get category;
  @override
  String get state;
  @override
  @JsonKey(name: 'sub_state')
  String? get subState;
  @override
  bool? get enabled;
  @override
  int? get pid;
  @override
  @JsonKey(name: 'memory_bytes')
  int? get memoryBytes;
  @override
  @JsonKey(name: 'cpu_percent')
  double? get cpuPercent;
  @override
  @JsonKey(name: 'uptime_seconds')
  int? get uptimeSeconds;

  /// Create a copy of ServiceInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServiceInfoImplCopyWith<_$ServiceInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
