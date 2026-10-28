// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'firewall_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FirewallStatus _$FirewallStatusFromJson(Map<String, dynamic> json) {
  return _FirewallStatus.fromJson(json);
}

/// @nodoc
mixin _$FirewallStatus {
  bool get enabled => throw _privateConstructorUsedError;
  String get tool => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  @JsonKey(name: 'rule_count')
  int get ruleCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_rule_count')
  int get customRuleCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_in')
  String get defaultIn => throw _privateConstructorUsedError;
  @JsonKey(name: 'default_out')
  String get defaultOut => throw _privateConstructorUsedError;

  /// Serializes this FirewallStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FirewallStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FirewallStatusCopyWith<FirewallStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FirewallStatusCopyWith<$Res> {
  factory $FirewallStatusCopyWith(
          FirewallStatus value, $Res Function(FirewallStatus) then) =
      _$FirewallStatusCopyWithImpl<$Res, FirewallStatus>;
  @useResult
  $Res call(
      {bool enabled,
      String tool,
      String version,
      @JsonKey(name: 'rule_count') int ruleCount,
      @JsonKey(name: 'custom_rule_count') int customRuleCount,
      @JsonKey(name: 'default_in') String defaultIn,
      @JsonKey(name: 'default_out') String defaultOut});
}

/// @nodoc
class _$FirewallStatusCopyWithImpl<$Res, $Val extends FirewallStatus>
    implements $FirewallStatusCopyWith<$Res> {
  _$FirewallStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FirewallStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? tool = null,
    Object? version = null,
    Object? ruleCount = null,
    Object? customRuleCount = null,
    Object? defaultIn = null,
    Object? defaultOut = null,
  }) {
    return _then(_value.copyWith(
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      tool: null == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      ruleCount: null == ruleCount
          ? _value.ruleCount
          : ruleCount // ignore: cast_nullable_to_non_nullable
              as int,
      customRuleCount: null == customRuleCount
          ? _value.customRuleCount
          : customRuleCount // ignore: cast_nullable_to_non_nullable
              as int,
      defaultIn: null == defaultIn
          ? _value.defaultIn
          : defaultIn // ignore: cast_nullable_to_non_nullable
              as String,
      defaultOut: null == defaultOut
          ? _value.defaultOut
          : defaultOut // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FirewallStatusImplCopyWith<$Res>
    implements $FirewallStatusCopyWith<$Res> {
  factory _$$FirewallStatusImplCopyWith(_$FirewallStatusImpl value,
          $Res Function(_$FirewallStatusImpl) then) =
      __$$FirewallStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool enabled,
      String tool,
      String version,
      @JsonKey(name: 'rule_count') int ruleCount,
      @JsonKey(name: 'custom_rule_count') int customRuleCount,
      @JsonKey(name: 'default_in') String defaultIn,
      @JsonKey(name: 'default_out') String defaultOut});
}

/// @nodoc
class __$$FirewallStatusImplCopyWithImpl<$Res>
    extends _$FirewallStatusCopyWithImpl<$Res, _$FirewallStatusImpl>
    implements _$$FirewallStatusImplCopyWith<$Res> {
  __$$FirewallStatusImplCopyWithImpl(
      _$FirewallStatusImpl _value, $Res Function(_$FirewallStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of FirewallStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? tool = null,
    Object? version = null,
    Object? ruleCount = null,
    Object? customRuleCount = null,
    Object? defaultIn = null,
    Object? defaultOut = null,
  }) {
    return _then(_$FirewallStatusImpl(
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      tool: null == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      ruleCount: null == ruleCount
          ? _value.ruleCount
          : ruleCount // ignore: cast_nullable_to_non_nullable
              as int,
      customRuleCount: null == customRuleCount
          ? _value.customRuleCount
          : customRuleCount // ignore: cast_nullable_to_non_nullable
              as int,
      defaultIn: null == defaultIn
          ? _value.defaultIn
          : defaultIn // ignore: cast_nullable_to_non_nullable
              as String,
      defaultOut: null == defaultOut
          ? _value.defaultOut
          : defaultOut // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FirewallStatusImpl implements _FirewallStatus {
  const _$FirewallStatusImpl(
      {this.enabled = false,
      this.tool = '',
      this.version = '',
      @JsonKey(name: 'rule_count') this.ruleCount = 0,
      @JsonKey(name: 'custom_rule_count') this.customRuleCount = 0,
      @JsonKey(name: 'default_in') this.defaultIn = 'ACCEPT',
      @JsonKey(name: 'default_out') this.defaultOut = 'ACCEPT'});

  factory _$FirewallStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$FirewallStatusImplFromJson(json);

  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final String tool;
  @override
  @JsonKey()
  final String version;
  @override
  @JsonKey(name: 'rule_count')
  final int ruleCount;
  @override
  @JsonKey(name: 'custom_rule_count')
  final int customRuleCount;
  @override
  @JsonKey(name: 'default_in')
  final String defaultIn;
  @override
  @JsonKey(name: 'default_out')
  final String defaultOut;

  @override
  String toString() {
    return 'FirewallStatus(enabled: $enabled, tool: $tool, version: $version, ruleCount: $ruleCount, customRuleCount: $customRuleCount, defaultIn: $defaultIn, defaultOut: $defaultOut)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FirewallStatusImpl &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.tool, tool) || other.tool == tool) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.ruleCount, ruleCount) ||
                other.ruleCount == ruleCount) &&
            (identical(other.customRuleCount, customRuleCount) ||
                other.customRuleCount == customRuleCount) &&
            (identical(other.defaultIn, defaultIn) ||
                other.defaultIn == defaultIn) &&
            (identical(other.defaultOut, defaultOut) ||
                other.defaultOut == defaultOut));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, enabled, tool, version,
      ruleCount, customRuleCount, defaultIn, defaultOut);

  /// Create a copy of FirewallStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FirewallStatusImplCopyWith<_$FirewallStatusImpl> get copyWith =>
      __$$FirewallStatusImplCopyWithImpl<_$FirewallStatusImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FirewallStatusImplToJson(
      this,
    );
  }
}

abstract class _FirewallStatus implements FirewallStatus {
  const factory _FirewallStatus(
          {final bool enabled,
          final String tool,
          final String version,
          @JsonKey(name: 'rule_count') final int ruleCount,
          @JsonKey(name: 'custom_rule_count') final int customRuleCount,
          @JsonKey(name: 'default_in') final String defaultIn,
          @JsonKey(name: 'default_out') final String defaultOut}) =
      _$FirewallStatusImpl;

  factory _FirewallStatus.fromJson(Map<String, dynamic> json) =
      _$FirewallStatusImpl.fromJson;

  @override
  bool get enabled;
  @override
  String get tool;
  @override
  String get version;
  @override
  @JsonKey(name: 'rule_count')
  int get ruleCount;
  @override
  @JsonKey(name: 'custom_rule_count')
  int get customRuleCount;
  @override
  @JsonKey(name: 'default_in')
  String get defaultIn;
  @override
  @JsonKey(name: 'default_out')
  String get defaultOut;

  /// Create a copy of FirewallStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FirewallStatusImplCopyWith<_$FirewallStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
