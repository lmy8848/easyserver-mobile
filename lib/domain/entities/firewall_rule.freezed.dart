// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'firewall_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FirewallRule _$FirewallRuleFromJson(Map<String, dynamic> json) {
  return _FirewallRule.fromJson(json);
}

/// @nodoc
mixin _$FirewallRule {
  int get id => throw _privateConstructorUsedError;
  String get chain => throw _privateConstructorUsedError;
  String get protocol => throw _privateConstructorUsedError;
  String get port => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  String get target => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError;
  @JsonKey(name: 'ip_version')
  String get ipVersion => throw _privateConstructorUsedError;
  String get remark => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this FirewallRule to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FirewallRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FirewallRuleCopyWith<FirewallRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FirewallRuleCopyWith<$Res> {
  factory $FirewallRuleCopyWith(
          FirewallRule value, $Res Function(FirewallRule) then) =
      _$FirewallRuleCopyWithImpl<$Res, FirewallRule>;
  @useResult
  $Res call(
      {int id,
      String chain,
      String protocol,
      String port,
      String action,
      String source,
      String target,
      bool enabled,
      int priority,
      @JsonKey(name: 'ip_version') String ipVersion,
      String remark,
      @JsonKey(name: 'created_at') String createdAt});
}

/// @nodoc
class _$FirewallRuleCopyWithImpl<$Res, $Val extends FirewallRule>
    implements $FirewallRuleCopyWith<$Res> {
  _$FirewallRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FirewallRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? chain = null,
    Object? protocol = null,
    Object? port = null,
    Object? action = null,
    Object? source = null,
    Object? target = null,
    Object? enabled = null,
    Object? priority = null,
    Object? ipVersion = null,
    Object? remark = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      chain: null == chain
          ? _value.chain
          : chain // ignore: cast_nullable_to_non_nullable
              as String,
      protocol: null == protocol
          ? _value.protocol
          : protocol // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      ipVersion: null == ipVersion
          ? _value.ipVersion
          : ipVersion // ignore: cast_nullable_to_non_nullable
              as String,
      remark: null == remark
          ? _value.remark
          : remark // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FirewallRuleImplCopyWith<$Res>
    implements $FirewallRuleCopyWith<$Res> {
  factory _$$FirewallRuleImplCopyWith(
          _$FirewallRuleImpl value, $Res Function(_$FirewallRuleImpl) then) =
      __$$FirewallRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String chain,
      String protocol,
      String port,
      String action,
      String source,
      String target,
      bool enabled,
      int priority,
      @JsonKey(name: 'ip_version') String ipVersion,
      String remark,
      @JsonKey(name: 'created_at') String createdAt});
}

/// @nodoc
class __$$FirewallRuleImplCopyWithImpl<$Res>
    extends _$FirewallRuleCopyWithImpl<$Res, _$FirewallRuleImpl>
    implements _$$FirewallRuleImplCopyWith<$Res> {
  __$$FirewallRuleImplCopyWithImpl(
      _$FirewallRuleImpl _value, $Res Function(_$FirewallRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of FirewallRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? chain = null,
    Object? protocol = null,
    Object? port = null,
    Object? action = null,
    Object? source = null,
    Object? target = null,
    Object? enabled = null,
    Object? priority = null,
    Object? ipVersion = null,
    Object? remark = null,
    Object? createdAt = null,
  }) {
    return _then(_$FirewallRuleImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      chain: null == chain
          ? _value.chain
          : chain // ignore: cast_nullable_to_non_nullable
              as String,
      protocol: null == protocol
          ? _value.protocol
          : protocol // ignore: cast_nullable_to_non_nullable
              as String,
      port: null == port
          ? _value.port
          : port // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      ipVersion: null == ipVersion
          ? _value.ipVersion
          : ipVersion // ignore: cast_nullable_to_non_nullable
              as String,
      remark: null == remark
          ? _value.remark
          : remark // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FirewallRuleImpl implements _FirewallRule {
  const _$FirewallRuleImpl(
      {this.id = 0,
      this.chain = 'INPUT',
      this.protocol = 'tcp',
      this.port = '',
      this.action = 'ACCEPT',
      this.source = '',
      this.target = '',
      this.enabled = true,
      this.priority = 0,
      @JsonKey(name: 'ip_version') this.ipVersion = 'both',
      this.remark = '',
      @JsonKey(name: 'created_at') this.createdAt = ''});

  factory _$FirewallRuleImpl.fromJson(Map<String, dynamic> json) =>
      _$$FirewallRuleImplFromJson(json);

  @override
  @JsonKey()
  final int id;
  @override
  @JsonKey()
  final String chain;
  @override
  @JsonKey()
  final String protocol;
  @override
  @JsonKey()
  final String port;
  @override
  @JsonKey()
  final String action;
  @override
  @JsonKey()
  final String source;
  @override
  @JsonKey()
  final String target;
  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final int priority;
  @override
  @JsonKey(name: 'ip_version')
  final String ipVersion;
  @override
  @JsonKey()
  final String remark;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;

  @override
  String toString() {
    return 'FirewallRule(id: $id, chain: $chain, protocol: $protocol, port: $port, action: $action, source: $source, target: $target, enabled: $enabled, priority: $priority, ipVersion: $ipVersion, remark: $remark, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FirewallRuleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.chain, chain) || other.chain == chain) &&
            (identical(other.protocol, protocol) ||
                other.protocol == protocol) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.ipVersion, ipVersion) ||
                other.ipVersion == ipVersion) &&
            (identical(other.remark, remark) || other.remark == remark) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, chain, protocol, port,
      action, source, target, enabled, priority, ipVersion, remark, createdAt);

  /// Create a copy of FirewallRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FirewallRuleImplCopyWith<_$FirewallRuleImpl> get copyWith =>
      __$$FirewallRuleImplCopyWithImpl<_$FirewallRuleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FirewallRuleImplToJson(
      this,
    );
  }
}

abstract class _FirewallRule implements FirewallRule {
  const factory _FirewallRule(
          {final int id,
          final String chain,
          final String protocol,
          final String port,
          final String action,
          final String source,
          final String target,
          final bool enabled,
          final int priority,
          @JsonKey(name: 'ip_version') final String ipVersion,
          final String remark,
          @JsonKey(name: 'created_at') final String createdAt}) =
      _$FirewallRuleImpl;

  factory _FirewallRule.fromJson(Map<String, dynamic> json) =
      _$FirewallRuleImpl.fromJson;

  @override
  int get id;
  @override
  String get chain;
  @override
  String get protocol;
  @override
  String get port;
  @override
  String get action;
  @override
  String get source;
  @override
  String get target;
  @override
  bool get enabled;
  @override
  int get priority;
  @override
  @JsonKey(name: 'ip_version')
  String get ipVersion;
  @override
  String get remark;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;

  /// Create a copy of FirewallRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FirewallRuleImplCopyWith<_$FirewallRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
