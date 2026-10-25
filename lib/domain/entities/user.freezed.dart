// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  int get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  @JsonKey(name: 'must_change_pass')
  bool get mustChangePass => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_login_at')
  String? get lastLoginAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_locked')
  bool get isLocked => throw _privateConstructorUsedError;
  @JsonKey(name: 'ip_whitelist')
  String? get ipWhitelist => throw _privateConstructorUsedError;
  @JsonKey(name: 'totp_enabled')
  bool get totpEnabled => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call(
      {int id,
      String username,
      String role,
      @JsonKey(name: 'must_change_pass') bool mustChangePass,
      @JsonKey(name: 'last_login_at') String? lastLoginAt,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'is_locked') bool isLocked,
      @JsonKey(name: 'ip_whitelist') String? ipWhitelist,
      @JsonKey(name: 'totp_enabled') bool totpEnabled});
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? role = null,
    Object? mustChangePass = null,
    Object? lastLoginAt = freezed,
    Object? createdAt = freezed,
    Object? isLocked = null,
    Object? ipWhitelist = freezed,
    Object? totpEnabled = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      mustChangePass: null == mustChangePass
          ? _value.mustChangePass
          : mustChangePass // ignore: cast_nullable_to_non_nullable
              as bool,
      lastLoginAt: freezed == lastLoginAt
          ? _value.lastLoginAt
          : lastLoginAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      isLocked: null == isLocked
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      ipWhitelist: freezed == ipWhitelist
          ? _value.ipWhitelist
          : ipWhitelist // ignore: cast_nullable_to_non_nullable
              as String?,
      totpEnabled: null == totpEnabled
          ? _value.totpEnabled
          : totpEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
          _$UserImpl value, $Res Function(_$UserImpl) then) =
      __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String username,
      String role,
      @JsonKey(name: 'must_change_pass') bool mustChangePass,
      @JsonKey(name: 'last_login_at') String? lastLoginAt,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'is_locked') bool isLocked,
      @JsonKey(name: 'ip_whitelist') String? ipWhitelist,
      @JsonKey(name: 'totp_enabled') bool totpEnabled});
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
      : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? role = null,
    Object? mustChangePass = null,
    Object? lastLoginAt = freezed,
    Object? createdAt = freezed,
    Object? isLocked = null,
    Object? ipWhitelist = freezed,
    Object? totpEnabled = null,
  }) {
    return _then(_$UserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      mustChangePass: null == mustChangePass
          ? _value.mustChangePass
          : mustChangePass // ignore: cast_nullable_to_non_nullable
              as bool,
      lastLoginAt: freezed == lastLoginAt
          ? _value.lastLoginAt
          : lastLoginAt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      isLocked: null == isLocked
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      ipWhitelist: freezed == ipWhitelist
          ? _value.ipWhitelist
          : ipWhitelist // ignore: cast_nullable_to_non_nullable
              as String?,
      totpEnabled: null == totpEnabled
          ? _value.totpEnabled
          : totpEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl(
      {required this.id,
      required this.username,
      required this.role,
      @JsonKey(name: 'must_change_pass') this.mustChangePass = false,
      @JsonKey(name: 'last_login_at') this.lastLoginAt,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'is_locked') this.isLocked = false,
      @JsonKey(name: 'ip_whitelist') this.ipWhitelist,
      @JsonKey(name: 'totp_enabled') this.totpEnabled = false});

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  final int id;
  @override
  final String username;
  @override
  final String role;
  @override
  @JsonKey(name: 'must_change_pass')
  final bool mustChangePass;
  @override
  @JsonKey(name: 'last_login_at')
  final String? lastLoginAt;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'is_locked')
  final bool isLocked;
  @override
  @JsonKey(name: 'ip_whitelist')
  final String? ipWhitelist;
  @override
  @JsonKey(name: 'totp_enabled')
  final bool totpEnabled;

  @override
  String toString() {
    return 'User(id: $id, username: $username, role: $role, mustChangePass: $mustChangePass, lastLoginAt: $lastLoginAt, createdAt: $createdAt, isLocked: $isLocked, ipWhitelist: $ipWhitelist, totpEnabled: $totpEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.mustChangePass, mustChangePass) ||
                other.mustChangePass == mustChangePass) &&
            (identical(other.lastLoginAt, lastLoginAt) ||
                other.lastLoginAt == lastLoginAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isLocked, isLocked) ||
                other.isLocked == isLocked) &&
            (identical(other.ipWhitelist, ipWhitelist) ||
                other.ipWhitelist == ipWhitelist) &&
            (identical(other.totpEnabled, totpEnabled) ||
                other.totpEnabled == totpEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      username,
      role,
      mustChangePass,
      lastLoginAt,
      createdAt,
      isLocked,
      ipWhitelist,
      totpEnabled);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(
      this,
    );
  }
}

abstract class _User implements User {
  const factory _User(
      {required final int id,
      required final String username,
      required final String role,
      @JsonKey(name: 'must_change_pass') final bool mustChangePass,
      @JsonKey(name: 'last_login_at') final String? lastLoginAt,
      @JsonKey(name: 'created_at') final String? createdAt,
      @JsonKey(name: 'is_locked') final bool isLocked,
      @JsonKey(name: 'ip_whitelist') final String? ipWhitelist,
      @JsonKey(name: 'totp_enabled') final bool totpEnabled}) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  int get id;
  @override
  String get username;
  @override
  String get role;
  @override
  @JsonKey(name: 'must_change_pass')
  bool get mustChangePass;
  @override
  @JsonKey(name: 'last_login_at')
  String? get lastLoginAt;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'is_locked')
  bool get isLocked;
  @override
  @JsonKey(name: 'ip_whitelist')
  String? get ipWhitelist;
  @override
  @JsonKey(name: 'totp_enabled')
  bool get totpEnabled;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
