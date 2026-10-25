// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'monitor_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CpuInfo _$CpuInfoFromJson(Map<String, dynamic> json) {
  return _CpuInfo.fromJson(json);
}

/// @nodoc
mixin _$CpuInfo {
  @JsonKey(name: 'usage_percent')
  double get usagePercent => throw _privateConstructorUsedError;
  @JsonKey(name: 'load_1m')
  double get load1m => throw _privateConstructorUsedError;
  @JsonKey(name: 'load_5m')
  double get load5m => throw _privateConstructorUsedError;
  @JsonKey(name: 'load_15m')
  double get load15m => throw _privateConstructorUsedError;

  /// Serializes this CpuInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CpuInfoCopyWith<CpuInfo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CpuInfoCopyWith<$Res> {
  factory $CpuInfoCopyWith(CpuInfo value, $Res Function(CpuInfo) then) =
      _$CpuInfoCopyWithImpl<$Res, CpuInfo>;
  @useResult
  $Res call(
      {@JsonKey(name: 'usage_percent') double usagePercent,
      @JsonKey(name: 'load_1m') double load1m,
      @JsonKey(name: 'load_5m') double load5m,
      @JsonKey(name: 'load_15m') double load15m});
}

/// @nodoc
class _$CpuInfoCopyWithImpl<$Res, $Val extends CpuInfo>
    implements $CpuInfoCopyWith<$Res> {
  _$CpuInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? usagePercent = null,
    Object? load1m = null,
    Object? load5m = null,
    Object? load15m = null,
  }) {
    return _then(_value.copyWith(
      usagePercent: null == usagePercent
          ? _value.usagePercent
          : usagePercent // ignore: cast_nullable_to_non_nullable
              as double,
      load1m: null == load1m
          ? _value.load1m
          : load1m // ignore: cast_nullable_to_non_nullable
              as double,
      load5m: null == load5m
          ? _value.load5m
          : load5m // ignore: cast_nullable_to_non_nullable
              as double,
      load15m: null == load15m
          ? _value.load15m
          : load15m // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CpuInfoImplCopyWith<$Res> implements $CpuInfoCopyWith<$Res> {
  factory _$$CpuInfoImplCopyWith(
          _$CpuInfoImpl value, $Res Function(_$CpuInfoImpl) then) =
      __$$CpuInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'usage_percent') double usagePercent,
      @JsonKey(name: 'load_1m') double load1m,
      @JsonKey(name: 'load_5m') double load5m,
      @JsonKey(name: 'load_15m') double load15m});
}

/// @nodoc
class __$$CpuInfoImplCopyWithImpl<$Res>
    extends _$CpuInfoCopyWithImpl<$Res, _$CpuInfoImpl>
    implements _$$CpuInfoImplCopyWith<$Res> {
  __$$CpuInfoImplCopyWithImpl(
      _$CpuInfoImpl _value, $Res Function(_$CpuInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of CpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? usagePercent = null,
    Object? load1m = null,
    Object? load5m = null,
    Object? load15m = null,
  }) {
    return _then(_$CpuInfoImpl(
      usagePercent: null == usagePercent
          ? _value.usagePercent
          : usagePercent // ignore: cast_nullable_to_non_nullable
              as double,
      load1m: null == load1m
          ? _value.load1m
          : load1m // ignore: cast_nullable_to_non_nullable
              as double,
      load5m: null == load5m
          ? _value.load5m
          : load5m // ignore: cast_nullable_to_non_nullable
              as double,
      load15m: null == load15m
          ? _value.load15m
          : load15m // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CpuInfoImpl implements _CpuInfo {
  const _$CpuInfoImpl(
      {@JsonKey(name: 'usage_percent') required this.usagePercent,
      @JsonKey(name: 'load_1m') required this.load1m,
      @JsonKey(name: 'load_5m') required this.load5m,
      @JsonKey(name: 'load_15m') required this.load15m});

  factory _$CpuInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CpuInfoImplFromJson(json);

  @override
  @JsonKey(name: 'usage_percent')
  final double usagePercent;
  @override
  @JsonKey(name: 'load_1m')
  final double load1m;
  @override
  @JsonKey(name: 'load_5m')
  final double load5m;
  @override
  @JsonKey(name: 'load_15m')
  final double load15m;

  @override
  String toString() {
    return 'CpuInfo(usagePercent: $usagePercent, load1m: $load1m, load5m: $load5m, load15m: $load15m)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CpuInfoImpl &&
            (identical(other.usagePercent, usagePercent) ||
                other.usagePercent == usagePercent) &&
            (identical(other.load1m, load1m) || other.load1m == load1m) &&
            (identical(other.load5m, load5m) || other.load5m == load5m) &&
            (identical(other.load15m, load15m) || other.load15m == load15m));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, usagePercent, load1m, load5m, load15m);

  /// Create a copy of CpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CpuInfoImplCopyWith<_$CpuInfoImpl> get copyWith =>
      __$$CpuInfoImplCopyWithImpl<_$CpuInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CpuInfoImplToJson(
      this,
    );
  }
}

abstract class _CpuInfo implements CpuInfo {
  const factory _CpuInfo(
          {@JsonKey(name: 'usage_percent') required final double usagePercent,
          @JsonKey(name: 'load_1m') required final double load1m,
          @JsonKey(name: 'load_5m') required final double load5m,
          @JsonKey(name: 'load_15m') required final double load15m}) =
      _$CpuInfoImpl;

  factory _CpuInfo.fromJson(Map<String, dynamic> json) = _$CpuInfoImpl.fromJson;

  @override
  @JsonKey(name: 'usage_percent')
  double get usagePercent;
  @override
  @JsonKey(name: 'load_1m')
  double get load1m;
  @override
  @JsonKey(name: 'load_5m')
  double get load5m;
  @override
  @JsonKey(name: 'load_15m')
  double get load15m;

  /// Create a copy of CpuInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CpuInfoImplCopyWith<_$CpuInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MemoryInfo _$MemoryInfoFromJson(Map<String, dynamic> json) {
  return _MemoryInfo.fromJson(json);
}

/// @nodoc
mixin _$MemoryInfo {
  @JsonKey(name: 'total_bytes')
  int get totalBytes => throw _privateConstructorUsedError;
  @JsonKey(name: 'used_bytes')
  int get usedBytes => throw _privateConstructorUsedError;
  @JsonKey(name: 'usage_percent')
  double get usagePercent => throw _privateConstructorUsedError;

  /// Serializes this MemoryInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MemoryInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MemoryInfoCopyWith<MemoryInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoryInfoCopyWith<$Res> {
  factory $MemoryInfoCopyWith(
          MemoryInfo value, $Res Function(MemoryInfo) then) =
      _$MemoryInfoCopyWithImpl<$Res, MemoryInfo>;
  @useResult
  $Res call(
      {@JsonKey(name: 'total_bytes') int totalBytes,
      @JsonKey(name: 'used_bytes') int usedBytes,
      @JsonKey(name: 'usage_percent') double usagePercent});
}

/// @nodoc
class _$MemoryInfoCopyWithImpl<$Res, $Val extends MemoryInfo>
    implements $MemoryInfoCopyWith<$Res> {
  _$MemoryInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MemoryInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalBytes = null,
    Object? usedBytes = null,
    Object? usagePercent = null,
  }) {
    return _then(_value.copyWith(
      totalBytes: null == totalBytes
          ? _value.totalBytes
          : totalBytes // ignore: cast_nullable_to_non_nullable
              as int,
      usedBytes: null == usedBytes
          ? _value.usedBytes
          : usedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      usagePercent: null == usagePercent
          ? _value.usagePercent
          : usagePercent // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MemoryInfoImplCopyWith<$Res>
    implements $MemoryInfoCopyWith<$Res> {
  factory _$$MemoryInfoImplCopyWith(
          _$MemoryInfoImpl value, $Res Function(_$MemoryInfoImpl) then) =
      __$$MemoryInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'total_bytes') int totalBytes,
      @JsonKey(name: 'used_bytes') int usedBytes,
      @JsonKey(name: 'usage_percent') double usagePercent});
}

/// @nodoc
class __$$MemoryInfoImplCopyWithImpl<$Res>
    extends _$MemoryInfoCopyWithImpl<$Res, _$MemoryInfoImpl>
    implements _$$MemoryInfoImplCopyWith<$Res> {
  __$$MemoryInfoImplCopyWithImpl(
      _$MemoryInfoImpl _value, $Res Function(_$MemoryInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of MemoryInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalBytes = null,
    Object? usedBytes = null,
    Object? usagePercent = null,
  }) {
    return _then(_$MemoryInfoImpl(
      totalBytes: null == totalBytes
          ? _value.totalBytes
          : totalBytes // ignore: cast_nullable_to_non_nullable
              as int,
      usedBytes: null == usedBytes
          ? _value.usedBytes
          : usedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      usagePercent: null == usagePercent
          ? _value.usagePercent
          : usagePercent // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemoryInfoImpl implements _MemoryInfo {
  const _$MemoryInfoImpl(
      {@JsonKey(name: 'total_bytes') required this.totalBytes,
      @JsonKey(name: 'used_bytes') required this.usedBytes,
      @JsonKey(name: 'usage_percent') required this.usagePercent});

  factory _$MemoryInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoryInfoImplFromJson(json);

  @override
  @JsonKey(name: 'total_bytes')
  final int totalBytes;
  @override
  @JsonKey(name: 'used_bytes')
  final int usedBytes;
  @override
  @JsonKey(name: 'usage_percent')
  final double usagePercent;

  @override
  String toString() {
    return 'MemoryInfo(totalBytes: $totalBytes, usedBytes: $usedBytes, usagePercent: $usagePercent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoryInfoImpl &&
            (identical(other.totalBytes, totalBytes) ||
                other.totalBytes == totalBytes) &&
            (identical(other.usedBytes, usedBytes) ||
                other.usedBytes == usedBytes) &&
            (identical(other.usagePercent, usagePercent) ||
                other.usagePercent == usagePercent));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, totalBytes, usedBytes, usagePercent);

  /// Create a copy of MemoryInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoryInfoImplCopyWith<_$MemoryInfoImpl> get copyWith =>
      __$$MemoryInfoImplCopyWithImpl<_$MemoryInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoryInfoImplToJson(
      this,
    );
  }
}

abstract class _MemoryInfo implements MemoryInfo {
  const factory _MemoryInfo(
          {@JsonKey(name: 'total_bytes') required final int totalBytes,
          @JsonKey(name: 'used_bytes') required final int usedBytes,
          @JsonKey(name: 'usage_percent') required final double usagePercent}) =
      _$MemoryInfoImpl;

  factory _MemoryInfo.fromJson(Map<String, dynamic> json) =
      _$MemoryInfoImpl.fromJson;

  @override
  @JsonKey(name: 'total_bytes')
  int get totalBytes;
  @override
  @JsonKey(name: 'used_bytes')
  int get usedBytes;
  @override
  @JsonKey(name: 'usage_percent')
  double get usagePercent;

  /// Create a copy of MemoryInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MemoryInfoImplCopyWith<_$MemoryInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DiskInfo _$DiskInfoFromJson(Map<String, dynamic> json) {
  return _DiskInfo.fromJson(json);
}

/// @nodoc
mixin _$DiskInfo {
  @JsonKey(name: 'mount_point')
  String get mountPoint => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_bytes')
  int get totalBytes => throw _privateConstructorUsedError;
  @JsonKey(name: 'used_bytes')
  int get usedBytes => throw _privateConstructorUsedError;
  @JsonKey(name: 'usage_percent')
  double get usagePercent => throw _privateConstructorUsedError;

  /// Serializes this DiskInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DiskInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiskInfoCopyWith<DiskInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiskInfoCopyWith<$Res> {
  factory $DiskInfoCopyWith(DiskInfo value, $Res Function(DiskInfo) then) =
      _$DiskInfoCopyWithImpl<$Res, DiskInfo>;
  @useResult
  $Res call(
      {@JsonKey(name: 'mount_point') String mountPoint,
      @JsonKey(name: 'total_bytes') int totalBytes,
      @JsonKey(name: 'used_bytes') int usedBytes,
      @JsonKey(name: 'usage_percent') double usagePercent});
}

/// @nodoc
class _$DiskInfoCopyWithImpl<$Res, $Val extends DiskInfo>
    implements $DiskInfoCopyWith<$Res> {
  _$DiskInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiskInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mountPoint = null,
    Object? totalBytes = null,
    Object? usedBytes = null,
    Object? usagePercent = null,
  }) {
    return _then(_value.copyWith(
      mountPoint: null == mountPoint
          ? _value.mountPoint
          : mountPoint // ignore: cast_nullable_to_non_nullable
              as String,
      totalBytes: null == totalBytes
          ? _value.totalBytes
          : totalBytes // ignore: cast_nullable_to_non_nullable
              as int,
      usedBytes: null == usedBytes
          ? _value.usedBytes
          : usedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      usagePercent: null == usagePercent
          ? _value.usagePercent
          : usagePercent // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiskInfoImplCopyWith<$Res>
    implements $DiskInfoCopyWith<$Res> {
  factory _$$DiskInfoImplCopyWith(
          _$DiskInfoImpl value, $Res Function(_$DiskInfoImpl) then) =
      __$$DiskInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'mount_point') String mountPoint,
      @JsonKey(name: 'total_bytes') int totalBytes,
      @JsonKey(name: 'used_bytes') int usedBytes,
      @JsonKey(name: 'usage_percent') double usagePercent});
}

/// @nodoc
class __$$DiskInfoImplCopyWithImpl<$Res>
    extends _$DiskInfoCopyWithImpl<$Res, _$DiskInfoImpl>
    implements _$$DiskInfoImplCopyWith<$Res> {
  __$$DiskInfoImplCopyWithImpl(
      _$DiskInfoImpl _value, $Res Function(_$DiskInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiskInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mountPoint = null,
    Object? totalBytes = null,
    Object? usedBytes = null,
    Object? usagePercent = null,
  }) {
    return _then(_$DiskInfoImpl(
      mountPoint: null == mountPoint
          ? _value.mountPoint
          : mountPoint // ignore: cast_nullable_to_non_nullable
              as String,
      totalBytes: null == totalBytes
          ? _value.totalBytes
          : totalBytes // ignore: cast_nullable_to_non_nullable
              as int,
      usedBytes: null == usedBytes
          ? _value.usedBytes
          : usedBytes // ignore: cast_nullable_to_non_nullable
              as int,
      usagePercent: null == usagePercent
          ? _value.usagePercent
          : usagePercent // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DiskInfoImpl implements _DiskInfo {
  const _$DiskInfoImpl(
      {@JsonKey(name: 'mount_point') required this.mountPoint,
      @JsonKey(name: 'total_bytes') required this.totalBytes,
      @JsonKey(name: 'used_bytes') required this.usedBytes,
      @JsonKey(name: 'usage_percent') required this.usagePercent});

  factory _$DiskInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiskInfoImplFromJson(json);

  @override
  @JsonKey(name: 'mount_point')
  final String mountPoint;
  @override
  @JsonKey(name: 'total_bytes')
  final int totalBytes;
  @override
  @JsonKey(name: 'used_bytes')
  final int usedBytes;
  @override
  @JsonKey(name: 'usage_percent')
  final double usagePercent;

  @override
  String toString() {
    return 'DiskInfo(mountPoint: $mountPoint, totalBytes: $totalBytes, usedBytes: $usedBytes, usagePercent: $usagePercent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiskInfoImpl &&
            (identical(other.mountPoint, mountPoint) ||
                other.mountPoint == mountPoint) &&
            (identical(other.totalBytes, totalBytes) ||
                other.totalBytes == totalBytes) &&
            (identical(other.usedBytes, usedBytes) ||
                other.usedBytes == usedBytes) &&
            (identical(other.usagePercent, usagePercent) ||
                other.usagePercent == usagePercent));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, mountPoint, totalBytes, usedBytes, usagePercent);

  /// Create a copy of DiskInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiskInfoImplCopyWith<_$DiskInfoImpl> get copyWith =>
      __$$DiskInfoImplCopyWithImpl<_$DiskInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiskInfoImplToJson(
      this,
    );
  }
}

abstract class _DiskInfo implements DiskInfo {
  const factory _DiskInfo(
          {@JsonKey(name: 'mount_point') required final String mountPoint,
          @JsonKey(name: 'total_bytes') required final int totalBytes,
          @JsonKey(name: 'used_bytes') required final int usedBytes,
          @JsonKey(name: 'usage_percent') required final double usagePercent}) =
      _$DiskInfoImpl;

  factory _DiskInfo.fromJson(Map<String, dynamic> json) =
      _$DiskInfoImpl.fromJson;

  @override
  @JsonKey(name: 'mount_point')
  String get mountPoint;
  @override
  @JsonKey(name: 'total_bytes')
  int get totalBytes;
  @override
  @JsonKey(name: 'used_bytes')
  int get usedBytes;
  @override
  @JsonKey(name: 'usage_percent')
  double get usagePercent;

  /// Create a copy of DiskInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiskInfoImplCopyWith<_$DiskInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NetworkInfo _$NetworkInfoFromJson(Map<String, dynamic> json) {
  return _NetworkInfo.fromJson(json);
}

/// @nodoc
mixin _$NetworkInfo {
  @JsonKey(name: 'bytes_sent')
  int get bytesSent => throw _privateConstructorUsedError;
  @JsonKey(name: 'bytes_recv')
  int get bytesRecv => throw _privateConstructorUsedError;

  /// Serializes this NetworkInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NetworkInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NetworkInfoCopyWith<NetworkInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetworkInfoCopyWith<$Res> {
  factory $NetworkInfoCopyWith(
          NetworkInfo value, $Res Function(NetworkInfo) then) =
      _$NetworkInfoCopyWithImpl<$Res, NetworkInfo>;
  @useResult
  $Res call(
      {@JsonKey(name: 'bytes_sent') int bytesSent,
      @JsonKey(name: 'bytes_recv') int bytesRecv});
}

/// @nodoc
class _$NetworkInfoCopyWithImpl<$Res, $Val extends NetworkInfo>
    implements $NetworkInfoCopyWith<$Res> {
  _$NetworkInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NetworkInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bytesSent = null,
    Object? bytesRecv = null,
  }) {
    return _then(_value.copyWith(
      bytesSent: null == bytesSent
          ? _value.bytesSent
          : bytesSent // ignore: cast_nullable_to_non_nullable
              as int,
      bytesRecv: null == bytesRecv
          ? _value.bytesRecv
          : bytesRecv // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NetworkInfoImplCopyWith<$Res>
    implements $NetworkInfoCopyWith<$Res> {
  factory _$$NetworkInfoImplCopyWith(
          _$NetworkInfoImpl value, $Res Function(_$NetworkInfoImpl) then) =
      __$$NetworkInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'bytes_sent') int bytesSent,
      @JsonKey(name: 'bytes_recv') int bytesRecv});
}

/// @nodoc
class __$$NetworkInfoImplCopyWithImpl<$Res>
    extends _$NetworkInfoCopyWithImpl<$Res, _$NetworkInfoImpl>
    implements _$$NetworkInfoImplCopyWith<$Res> {
  __$$NetworkInfoImplCopyWithImpl(
      _$NetworkInfoImpl _value, $Res Function(_$NetworkInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of NetworkInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bytesSent = null,
    Object? bytesRecv = null,
  }) {
    return _then(_$NetworkInfoImpl(
      bytesSent: null == bytesSent
          ? _value.bytesSent
          : bytesSent // ignore: cast_nullable_to_non_nullable
              as int,
      bytesRecv: null == bytesRecv
          ? _value.bytesRecv
          : bytesRecv // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NetworkInfoImpl implements _NetworkInfo {
  const _$NetworkInfoImpl(
      {@JsonKey(name: 'bytes_sent') required this.bytesSent,
      @JsonKey(name: 'bytes_recv') required this.bytesRecv});

  factory _$NetworkInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$NetworkInfoImplFromJson(json);

  @override
  @JsonKey(name: 'bytes_sent')
  final int bytesSent;
  @override
  @JsonKey(name: 'bytes_recv')
  final int bytesRecv;

  @override
  String toString() {
    return 'NetworkInfo(bytesSent: $bytesSent, bytesRecv: $bytesRecv)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkInfoImpl &&
            (identical(other.bytesSent, bytesSent) ||
                other.bytesSent == bytesSent) &&
            (identical(other.bytesRecv, bytesRecv) ||
                other.bytesRecv == bytesRecv));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, bytesSent, bytesRecv);

  /// Create a copy of NetworkInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkInfoImplCopyWith<_$NetworkInfoImpl> get copyWith =>
      __$$NetworkInfoImplCopyWithImpl<_$NetworkInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NetworkInfoImplToJson(
      this,
    );
  }
}

abstract class _NetworkInfo implements NetworkInfo {
  const factory _NetworkInfo(
          {@JsonKey(name: 'bytes_sent') required final int bytesSent,
          @JsonKey(name: 'bytes_recv') required final int bytesRecv}) =
      _$NetworkInfoImpl;

  factory _NetworkInfo.fromJson(Map<String, dynamic> json) =
      _$NetworkInfoImpl.fromJson;

  @override
  @JsonKey(name: 'bytes_sent')
  int get bytesSent;
  @override
  @JsonKey(name: 'bytes_recv')
  int get bytesRecv;

  /// Create a copy of NetworkInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetworkInfoImplCopyWith<_$NetworkInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProcessInfo _$ProcessInfoFromJson(Map<String, dynamic> json) {
  return _ProcessInfo.fromJson(json);
}

/// @nodoc
mixin _$ProcessInfo {
  int get pid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get user => throw _privateConstructorUsedError;
  @JsonKey(name: 'cpu_percent')
  double get cpuPercent => throw _privateConstructorUsedError;
  @JsonKey(name: 'mem_percent')
  double get memPercent => throw _privateConstructorUsedError;
  @JsonKey(name: 'mem_bytes')
  int get memBytes => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;

  /// Serializes this ProcessInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProcessInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProcessInfoCopyWith<ProcessInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProcessInfoCopyWith<$Res> {
  factory $ProcessInfoCopyWith(
          ProcessInfo value, $Res Function(ProcessInfo) then) =
      _$ProcessInfoCopyWithImpl<$Res, ProcessInfo>;
  @useResult
  $Res call(
      {int pid,
      String name,
      String user,
      @JsonKey(name: 'cpu_percent') double cpuPercent,
      @JsonKey(name: 'mem_percent') double memPercent,
      @JsonKey(name: 'mem_bytes') int memBytes,
      String state});
}

/// @nodoc
class _$ProcessInfoCopyWithImpl<$Res, $Val extends ProcessInfo>
    implements $ProcessInfoCopyWith<$Res> {
  _$ProcessInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProcessInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pid = null,
    Object? name = null,
    Object? user = null,
    Object? cpuPercent = null,
    Object? memPercent = null,
    Object? memBytes = null,
    Object? state = null,
  }) {
    return _then(_value.copyWith(
      pid: null == pid
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as String,
      cpuPercent: null == cpuPercent
          ? _value.cpuPercent
          : cpuPercent // ignore: cast_nullable_to_non_nullable
              as double,
      memPercent: null == memPercent
          ? _value.memPercent
          : memPercent // ignore: cast_nullable_to_non_nullable
              as double,
      memBytes: null == memBytes
          ? _value.memBytes
          : memBytes // ignore: cast_nullable_to_non_nullable
              as int,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProcessInfoImplCopyWith<$Res>
    implements $ProcessInfoCopyWith<$Res> {
  factory _$$ProcessInfoImplCopyWith(
          _$ProcessInfoImpl value, $Res Function(_$ProcessInfoImpl) then) =
      __$$ProcessInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int pid,
      String name,
      String user,
      @JsonKey(name: 'cpu_percent') double cpuPercent,
      @JsonKey(name: 'mem_percent') double memPercent,
      @JsonKey(name: 'mem_bytes') int memBytes,
      String state});
}

/// @nodoc
class __$$ProcessInfoImplCopyWithImpl<$Res>
    extends _$ProcessInfoCopyWithImpl<$Res, _$ProcessInfoImpl>
    implements _$$ProcessInfoImplCopyWith<$Res> {
  __$$ProcessInfoImplCopyWithImpl(
      _$ProcessInfoImpl _value, $Res Function(_$ProcessInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProcessInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pid = null,
    Object? name = null,
    Object? user = null,
    Object? cpuPercent = null,
    Object? memPercent = null,
    Object? memBytes = null,
    Object? state = null,
  }) {
    return _then(_$ProcessInfoImpl(
      pid: null == pid
          ? _value.pid
          : pid // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as String,
      cpuPercent: null == cpuPercent
          ? _value.cpuPercent
          : cpuPercent // ignore: cast_nullable_to_non_nullable
              as double,
      memPercent: null == memPercent
          ? _value.memPercent
          : memPercent // ignore: cast_nullable_to_non_nullable
              as double,
      memBytes: null == memBytes
          ? _value.memBytes
          : memBytes // ignore: cast_nullable_to_non_nullable
              as int,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProcessInfoImpl implements _ProcessInfo {
  const _$ProcessInfoImpl(
      {required this.pid,
      required this.name,
      required this.user,
      @JsonKey(name: 'cpu_percent') required this.cpuPercent,
      @JsonKey(name: 'mem_percent') required this.memPercent,
      @JsonKey(name: 'mem_bytes') required this.memBytes,
      required this.state});

  factory _$ProcessInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProcessInfoImplFromJson(json);

  @override
  final int pid;
  @override
  final String name;
  @override
  final String user;
  @override
  @JsonKey(name: 'cpu_percent')
  final double cpuPercent;
  @override
  @JsonKey(name: 'mem_percent')
  final double memPercent;
  @override
  @JsonKey(name: 'mem_bytes')
  final int memBytes;
  @override
  final String state;

  @override
  String toString() {
    return 'ProcessInfo(pid: $pid, name: $name, user: $user, cpuPercent: $cpuPercent, memPercent: $memPercent, memBytes: $memBytes, state: $state)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProcessInfoImpl &&
            (identical(other.pid, pid) || other.pid == pid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.cpuPercent, cpuPercent) ||
                other.cpuPercent == cpuPercent) &&
            (identical(other.memPercent, memPercent) ||
                other.memPercent == memPercent) &&
            (identical(other.memBytes, memBytes) ||
                other.memBytes == memBytes) &&
            (identical(other.state, state) || other.state == state));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, pid, name, user, cpuPercent, memPercent, memBytes, state);

  /// Create a copy of ProcessInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProcessInfoImplCopyWith<_$ProcessInfoImpl> get copyWith =>
      __$$ProcessInfoImplCopyWithImpl<_$ProcessInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProcessInfoImplToJson(
      this,
    );
  }
}

abstract class _ProcessInfo implements ProcessInfo {
  const factory _ProcessInfo(
      {required final int pid,
      required final String name,
      required final String user,
      @JsonKey(name: 'cpu_percent') required final double cpuPercent,
      @JsonKey(name: 'mem_percent') required final double memPercent,
      @JsonKey(name: 'mem_bytes') required final int memBytes,
      required final String state}) = _$ProcessInfoImpl;

  factory _ProcessInfo.fromJson(Map<String, dynamic> json) =
      _$ProcessInfoImpl.fromJson;

  @override
  int get pid;
  @override
  String get name;
  @override
  String get user;
  @override
  @JsonKey(name: 'cpu_percent')
  double get cpuPercent;
  @override
  @JsonKey(name: 'mem_percent')
  double get memPercent;
  @override
  @JsonKey(name: 'mem_bytes')
  int get memBytes;
  @override
  String get state;

  /// Create a copy of ProcessInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProcessInfoImplCopyWith<_$ProcessInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SystemInfo _$SystemInfoFromJson(Map<String, dynamic> json) {
  return _SystemInfo.fromJson(json);
}

/// @nodoc
mixin _$SystemInfo {
  String get hostname => throw _privateConstructorUsedError;
  String get os => throw _privateConstructorUsedError;
  String get kernel => throw _privateConstructorUsedError;
  String get arch => throw _privateConstructorUsedError;
  @JsonKey(name: 'cpu_cores')
  int get cpuCores => throw _privateConstructorUsedError;
  @JsonKey(name: 'uptime_seconds')
  int get uptimeSeconds => throw _privateConstructorUsedError;

  /// Serializes this SystemInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SystemInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SystemInfoCopyWith<SystemInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SystemInfoCopyWith<$Res> {
  factory $SystemInfoCopyWith(
          SystemInfo value, $Res Function(SystemInfo) then) =
      _$SystemInfoCopyWithImpl<$Res, SystemInfo>;
  @useResult
  $Res call(
      {String hostname,
      String os,
      String kernel,
      String arch,
      @JsonKey(name: 'cpu_cores') int cpuCores,
      @JsonKey(name: 'uptime_seconds') int uptimeSeconds});
}

/// @nodoc
class _$SystemInfoCopyWithImpl<$Res, $Val extends SystemInfo>
    implements $SystemInfoCopyWith<$Res> {
  _$SystemInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SystemInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hostname = null,
    Object? os = null,
    Object? kernel = null,
    Object? arch = null,
    Object? cpuCores = null,
    Object? uptimeSeconds = null,
  }) {
    return _then(_value.copyWith(
      hostname: null == hostname
          ? _value.hostname
          : hostname // ignore: cast_nullable_to_non_nullable
              as String,
      os: null == os
          ? _value.os
          : os // ignore: cast_nullable_to_non_nullable
              as String,
      kernel: null == kernel
          ? _value.kernel
          : kernel // ignore: cast_nullable_to_non_nullable
              as String,
      arch: null == arch
          ? _value.arch
          : arch // ignore: cast_nullable_to_non_nullable
              as String,
      cpuCores: null == cpuCores
          ? _value.cpuCores
          : cpuCores // ignore: cast_nullable_to_non_nullable
              as int,
      uptimeSeconds: null == uptimeSeconds
          ? _value.uptimeSeconds
          : uptimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SystemInfoImplCopyWith<$Res>
    implements $SystemInfoCopyWith<$Res> {
  factory _$$SystemInfoImplCopyWith(
          _$SystemInfoImpl value, $Res Function(_$SystemInfoImpl) then) =
      __$$SystemInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String hostname,
      String os,
      String kernel,
      String arch,
      @JsonKey(name: 'cpu_cores') int cpuCores,
      @JsonKey(name: 'uptime_seconds') int uptimeSeconds});
}

/// @nodoc
class __$$SystemInfoImplCopyWithImpl<$Res>
    extends _$SystemInfoCopyWithImpl<$Res, _$SystemInfoImpl>
    implements _$$SystemInfoImplCopyWith<$Res> {
  __$$SystemInfoImplCopyWithImpl(
      _$SystemInfoImpl _value, $Res Function(_$SystemInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of SystemInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hostname = null,
    Object? os = null,
    Object? kernel = null,
    Object? arch = null,
    Object? cpuCores = null,
    Object? uptimeSeconds = null,
  }) {
    return _then(_$SystemInfoImpl(
      hostname: null == hostname
          ? _value.hostname
          : hostname // ignore: cast_nullable_to_non_nullable
              as String,
      os: null == os
          ? _value.os
          : os // ignore: cast_nullable_to_non_nullable
              as String,
      kernel: null == kernel
          ? _value.kernel
          : kernel // ignore: cast_nullable_to_non_nullable
              as String,
      arch: null == arch
          ? _value.arch
          : arch // ignore: cast_nullable_to_non_nullable
              as String,
      cpuCores: null == cpuCores
          ? _value.cpuCores
          : cpuCores // ignore: cast_nullable_to_non_nullable
              as int,
      uptimeSeconds: null == uptimeSeconds
          ? _value.uptimeSeconds
          : uptimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SystemInfoImpl implements _SystemInfo {
  const _$SystemInfoImpl(
      {required this.hostname,
      required this.os,
      required this.kernel,
      required this.arch,
      @JsonKey(name: 'cpu_cores') required this.cpuCores,
      @JsonKey(name: 'uptime_seconds') required this.uptimeSeconds});

  factory _$SystemInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SystemInfoImplFromJson(json);

  @override
  final String hostname;
  @override
  final String os;
  @override
  final String kernel;
  @override
  final String arch;
  @override
  @JsonKey(name: 'cpu_cores')
  final int cpuCores;
  @override
  @JsonKey(name: 'uptime_seconds')
  final int uptimeSeconds;

  @override
  String toString() {
    return 'SystemInfo(hostname: $hostname, os: $os, kernel: $kernel, arch: $arch, cpuCores: $cpuCores, uptimeSeconds: $uptimeSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SystemInfoImpl &&
            (identical(other.hostname, hostname) ||
                other.hostname == hostname) &&
            (identical(other.os, os) || other.os == os) &&
            (identical(other.kernel, kernel) || other.kernel == kernel) &&
            (identical(other.arch, arch) || other.arch == arch) &&
            (identical(other.cpuCores, cpuCores) ||
                other.cpuCores == cpuCores) &&
            (identical(other.uptimeSeconds, uptimeSeconds) ||
                other.uptimeSeconds == uptimeSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, hostname, os, kernel, arch, cpuCores, uptimeSeconds);

  /// Create a copy of SystemInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SystemInfoImplCopyWith<_$SystemInfoImpl> get copyWith =>
      __$$SystemInfoImplCopyWithImpl<_$SystemInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SystemInfoImplToJson(
      this,
    );
  }
}

abstract class _SystemInfo implements SystemInfo {
  const factory _SystemInfo(
          {required final String hostname,
          required final String os,
          required final String kernel,
          required final String arch,
          @JsonKey(name: 'cpu_cores') required final int cpuCores,
          @JsonKey(name: 'uptime_seconds') required final int uptimeSeconds}) =
      _$SystemInfoImpl;

  factory _SystemInfo.fromJson(Map<String, dynamic> json) =
      _$SystemInfoImpl.fromJson;

  @override
  String get hostname;
  @override
  String get os;
  @override
  String get kernel;
  @override
  String get arch;
  @override
  @JsonKey(name: 'cpu_cores')
  int get cpuCores;
  @override
  @JsonKey(name: 'uptime_seconds')
  int get uptimeSeconds;

  /// Create a copy of SystemInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SystemInfoImplCopyWith<_$SystemInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MonitorSnapshot _$MonitorSnapshotFromJson(Map<String, dynamic> json) {
  return _MonitorSnapshot.fromJson(json);
}

/// @nodoc
mixin _$MonitorSnapshot {
  CpuInfo get cpu => throw _privateConstructorUsedError;
  MemoryInfo get memory => throw _privateConstructorUsedError;
  List<DiskInfo> get disk => throw _privateConstructorUsedError;
  NetworkInfo get network => throw _privateConstructorUsedError;
  SystemInfo? get system => throw _privateConstructorUsedError;
  @JsonKey(name: 'top_process')
  List<ProcessInfo>? get topProcess => throw _privateConstructorUsedError;
  String get timestamp => throw _privateConstructorUsedError;

  /// Serializes this MonitorSnapshot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MonitorSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonitorSnapshotCopyWith<MonitorSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonitorSnapshotCopyWith<$Res> {
  factory $MonitorSnapshotCopyWith(
          MonitorSnapshot value, $Res Function(MonitorSnapshot) then) =
      _$MonitorSnapshotCopyWithImpl<$Res, MonitorSnapshot>;
  @useResult
  $Res call(
      {CpuInfo cpu,
      MemoryInfo memory,
      List<DiskInfo> disk,
      NetworkInfo network,
      SystemInfo? system,
      @JsonKey(name: 'top_process') List<ProcessInfo>? topProcess,
      String timestamp});

  $CpuInfoCopyWith<$Res> get cpu;
  $MemoryInfoCopyWith<$Res> get memory;
  $NetworkInfoCopyWith<$Res> get network;
  $SystemInfoCopyWith<$Res>? get system;
}

/// @nodoc
class _$MonitorSnapshotCopyWithImpl<$Res, $Val extends MonitorSnapshot>
    implements $MonitorSnapshotCopyWith<$Res> {
  _$MonitorSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonitorSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cpu = null,
    Object? memory = null,
    Object? disk = null,
    Object? network = null,
    Object? system = freezed,
    Object? topProcess = freezed,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      cpu: null == cpu
          ? _value.cpu
          : cpu // ignore: cast_nullable_to_non_nullable
              as CpuInfo,
      memory: null == memory
          ? _value.memory
          : memory // ignore: cast_nullable_to_non_nullable
              as MemoryInfo,
      disk: null == disk
          ? _value.disk
          : disk // ignore: cast_nullable_to_non_nullable
              as List<DiskInfo>,
      network: null == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as NetworkInfo,
      system: freezed == system
          ? _value.system
          : system // ignore: cast_nullable_to_non_nullable
              as SystemInfo?,
      topProcess: freezed == topProcess
          ? _value.topProcess
          : topProcess // ignore: cast_nullable_to_non_nullable
              as List<ProcessInfo>?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of MonitorSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CpuInfoCopyWith<$Res> get cpu {
    return $CpuInfoCopyWith<$Res>(_value.cpu, (value) {
      return _then(_value.copyWith(cpu: value) as $Val);
    });
  }

  /// Create a copy of MonitorSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MemoryInfoCopyWith<$Res> get memory {
    return $MemoryInfoCopyWith<$Res>(_value.memory, (value) {
      return _then(_value.copyWith(memory: value) as $Val);
    });
  }

  /// Create a copy of MonitorSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NetworkInfoCopyWith<$Res> get network {
    return $NetworkInfoCopyWith<$Res>(_value.network, (value) {
      return _then(_value.copyWith(network: value) as $Val);
    });
  }

  /// Create a copy of MonitorSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SystemInfoCopyWith<$Res>? get system {
    if (_value.system == null) {
      return null;
    }

    return $SystemInfoCopyWith<$Res>(_value.system!, (value) {
      return _then(_value.copyWith(system: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MonitorSnapshotImplCopyWith<$Res>
    implements $MonitorSnapshotCopyWith<$Res> {
  factory _$$MonitorSnapshotImplCopyWith(_$MonitorSnapshotImpl value,
          $Res Function(_$MonitorSnapshotImpl) then) =
      __$$MonitorSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {CpuInfo cpu,
      MemoryInfo memory,
      List<DiskInfo> disk,
      NetworkInfo network,
      SystemInfo? system,
      @JsonKey(name: 'top_process') List<ProcessInfo>? topProcess,
      String timestamp});

  @override
  $CpuInfoCopyWith<$Res> get cpu;
  @override
  $MemoryInfoCopyWith<$Res> get memory;
  @override
  $NetworkInfoCopyWith<$Res> get network;
  @override
  $SystemInfoCopyWith<$Res>? get system;
}

/// @nodoc
class __$$MonitorSnapshotImplCopyWithImpl<$Res>
    extends _$MonitorSnapshotCopyWithImpl<$Res, _$MonitorSnapshotImpl>
    implements _$$MonitorSnapshotImplCopyWith<$Res> {
  __$$MonitorSnapshotImplCopyWithImpl(
      _$MonitorSnapshotImpl _value, $Res Function(_$MonitorSnapshotImpl) _then)
      : super(_value, _then);

  /// Create a copy of MonitorSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cpu = null,
    Object? memory = null,
    Object? disk = null,
    Object? network = null,
    Object? system = freezed,
    Object? topProcess = freezed,
    Object? timestamp = null,
  }) {
    return _then(_$MonitorSnapshotImpl(
      cpu: null == cpu
          ? _value.cpu
          : cpu // ignore: cast_nullable_to_non_nullable
              as CpuInfo,
      memory: null == memory
          ? _value.memory
          : memory // ignore: cast_nullable_to_non_nullable
              as MemoryInfo,
      disk: null == disk
          ? _value._disk
          : disk // ignore: cast_nullable_to_non_nullable
              as List<DiskInfo>,
      network: null == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as NetworkInfo,
      system: freezed == system
          ? _value.system
          : system // ignore: cast_nullable_to_non_nullable
              as SystemInfo?,
      topProcess: freezed == topProcess
          ? _value._topProcess
          : topProcess // ignore: cast_nullable_to_non_nullable
              as List<ProcessInfo>?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MonitorSnapshotImpl implements _MonitorSnapshot {
  const _$MonitorSnapshotImpl(
      {required this.cpu,
      required this.memory,
      required final List<DiskInfo> disk,
      required this.network,
      this.system,
      @JsonKey(name: 'top_process') final List<ProcessInfo>? topProcess,
      required this.timestamp})
      : _disk = disk,
        _topProcess = topProcess;

  factory _$MonitorSnapshotImpl.fromJson(Map<String, dynamic> json) =>
      _$$MonitorSnapshotImplFromJson(json);

  @override
  final CpuInfo cpu;
  @override
  final MemoryInfo memory;
  final List<DiskInfo> _disk;
  @override
  List<DiskInfo> get disk {
    if (_disk is EqualUnmodifiableListView) return _disk;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_disk);
  }

  @override
  final NetworkInfo network;
  @override
  final SystemInfo? system;
  final List<ProcessInfo>? _topProcess;
  @override
  @JsonKey(name: 'top_process')
  List<ProcessInfo>? get topProcess {
    final value = _topProcess;
    if (value == null) return null;
    if (_topProcess is EqualUnmodifiableListView) return _topProcess;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String timestamp;

  @override
  String toString() {
    return 'MonitorSnapshot(cpu: $cpu, memory: $memory, disk: $disk, network: $network, system: $system, topProcess: $topProcess, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonitorSnapshotImpl &&
            (identical(other.cpu, cpu) || other.cpu == cpu) &&
            (identical(other.memory, memory) || other.memory == memory) &&
            const DeepCollectionEquality().equals(other._disk, _disk) &&
            (identical(other.network, network) || other.network == network) &&
            (identical(other.system, system) || other.system == system) &&
            const DeepCollectionEquality()
                .equals(other._topProcess, _topProcess) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      cpu,
      memory,
      const DeepCollectionEquality().hash(_disk),
      network,
      system,
      const DeepCollectionEquality().hash(_topProcess),
      timestamp);

  /// Create a copy of MonitorSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonitorSnapshotImplCopyWith<_$MonitorSnapshotImpl> get copyWith =>
      __$$MonitorSnapshotImplCopyWithImpl<_$MonitorSnapshotImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MonitorSnapshotImplToJson(
      this,
    );
  }
}

abstract class _MonitorSnapshot implements MonitorSnapshot {
  const factory _MonitorSnapshot(
      {required final CpuInfo cpu,
      required final MemoryInfo memory,
      required final List<DiskInfo> disk,
      required final NetworkInfo network,
      final SystemInfo? system,
      @JsonKey(name: 'top_process') final List<ProcessInfo>? topProcess,
      required final String timestamp}) = _$MonitorSnapshotImpl;

  factory _MonitorSnapshot.fromJson(Map<String, dynamic> json) =
      _$MonitorSnapshotImpl.fromJson;

  @override
  CpuInfo get cpu;
  @override
  MemoryInfo get memory;
  @override
  List<DiskInfo> get disk;
  @override
  NetworkInfo get network;
  @override
  SystemInfo? get system;
  @override
  @JsonKey(name: 'top_process')
  List<ProcessInfo>? get topProcess;
  @override
  String get timestamp;

  /// Create a copy of MonitorSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonitorSnapshotImplCopyWith<_$MonitorSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
