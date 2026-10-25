// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AuthResult _$AuthResultFromJson(Map<String, dynamic> json) {
  return _AuthResult.fromJson(json);
}

/// @nodoc
mixin _$AuthResult {
  String get token => throw _privateConstructorUsedError;
  User get user => throw _privateConstructorUsedError;
  @JsonKey(name: 'must_change_pass')
  bool get mustChangePass => throw _privateConstructorUsedError;
  @JsonKey(name: 'requires_totp')
  bool get requiresTotp => throw _privateConstructorUsedError;
  @JsonKey(name: 'temp_token')
  String? get tempToken => throw _privateConstructorUsedError;

  /// Serializes this AuthResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthResultCopyWith<AuthResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthResultCopyWith<$Res> {
  factory $AuthResultCopyWith(
          AuthResult value, $Res Function(AuthResult) then) =
      _$AuthResultCopyWithImpl<$Res, AuthResult>;
  @useResult
  $Res call(
      {String token,
      User user,
      @JsonKey(name: 'must_change_pass') bool mustChangePass,
      @JsonKey(name: 'requires_totp') bool requiresTotp,
      @JsonKey(name: 'temp_token') String? tempToken});

  $UserCopyWith<$Res> get user;
}

/// @nodoc
class _$AuthResultCopyWithImpl<$Res, $Val extends AuthResult>
    implements $AuthResultCopyWith<$Res> {
  _$AuthResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? user = null,
    Object? mustChangePass = null,
    Object? requiresTotp = null,
    Object? tempToken = freezed,
  }) {
    return _then(_value.copyWith(
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User,
      mustChangePass: null == mustChangePass
          ? _value.mustChangePass
          : mustChangePass // ignore: cast_nullable_to_non_nullable
              as bool,
      requiresTotp: null == requiresTotp
          ? _value.requiresTotp
          : requiresTotp // ignore: cast_nullable_to_non_nullable
              as bool,
      tempToken: freezed == tempToken
          ? _value.tempToken
          : tempToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get user {
    return $UserCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AuthResultImplCopyWith<$Res>
    implements $AuthResultCopyWith<$Res> {
  factory _$$AuthResultImplCopyWith(
          _$AuthResultImpl value, $Res Function(_$AuthResultImpl) then) =
      __$$AuthResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String token,
      User user,
      @JsonKey(name: 'must_change_pass') bool mustChangePass,
      @JsonKey(name: 'requires_totp') bool requiresTotp,
      @JsonKey(name: 'temp_token') String? tempToken});

  @override
  $UserCopyWith<$Res> get user;
}

/// @nodoc
class __$$AuthResultImplCopyWithImpl<$Res>
    extends _$AuthResultCopyWithImpl<$Res, _$AuthResultImpl>
    implements _$$AuthResultImplCopyWith<$Res> {
  __$$AuthResultImplCopyWithImpl(
      _$AuthResultImpl _value, $Res Function(_$AuthResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? user = null,
    Object? mustChangePass = null,
    Object? requiresTotp = null,
    Object? tempToken = freezed,
  }) {
    return _then(_$AuthResultImpl(
      token: null == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User,
      mustChangePass: null == mustChangePass
          ? _value.mustChangePass
          : mustChangePass // ignore: cast_nullable_to_non_nullable
              as bool,
      requiresTotp: null == requiresTotp
          ? _value.requiresTotp
          : requiresTotp // ignore: cast_nullable_to_non_nullable
              as bool,
      tempToken: freezed == tempToken
          ? _value.tempToken
          : tempToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthResultImpl implements _AuthResult {
  const _$AuthResultImpl(
      {required this.token,
      required this.user,
      @JsonKey(name: 'must_change_pass') required this.mustChangePass,
      @JsonKey(name: 'requires_totp') this.requiresTotp = false,
      @JsonKey(name: 'temp_token') this.tempToken});

  factory _$AuthResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthResultImplFromJson(json);

  @override
  final String token;
  @override
  final User user;
  @override
  @JsonKey(name: 'must_change_pass')
  final bool mustChangePass;
  @override
  @JsonKey(name: 'requires_totp')
  final bool requiresTotp;
  @override
  @JsonKey(name: 'temp_token')
  final String? tempToken;

  @override
  String toString() {
    return 'AuthResult(token: $token, user: $user, mustChangePass: $mustChangePass, requiresTotp: $requiresTotp, tempToken: $tempToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResultImpl &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.mustChangePass, mustChangePass) ||
                other.mustChangePass == mustChangePass) &&
            (identical(other.requiresTotp, requiresTotp) ||
                other.requiresTotp == requiresTotp) &&
            (identical(other.tempToken, tempToken) ||
                other.tempToken == tempToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, token, user, mustChangePass, requiresTotp, tempToken);

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResultImplCopyWith<_$AuthResultImpl> get copyWith =>
      __$$AuthResultImplCopyWithImpl<_$AuthResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthResultImplToJson(
      this,
    );
  }
}

abstract class _AuthResult implements AuthResult {
  const factory _AuthResult(
      {required final String token,
      required final User user,
      @JsonKey(name: 'must_change_pass') required final bool mustChangePass,
      @JsonKey(name: 'requires_totp') final bool requiresTotp,
      @JsonKey(name: 'temp_token') final String? tempToken}) = _$AuthResultImpl;

  factory _AuthResult.fromJson(Map<String, dynamic> json) =
      _$AuthResultImpl.fromJson;

  @override
  String get token;
  @override
  User get user;
  @override
  @JsonKey(name: 'must_change_pass')
  bool get mustChangePass;
  @override
  @JsonKey(name: 'requires_totp')
  bool get requiresTotp;
  @override
  @JsonKey(name: 'temp_token')
  String? get tempToken;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthResultImplCopyWith<_$AuthResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
