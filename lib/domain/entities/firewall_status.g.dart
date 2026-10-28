// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firewall_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FirewallStatusImpl _$$FirewallStatusImplFromJson(Map<String, dynamic> json) =>
    _$FirewallStatusImpl(
      enabled: json['enabled'] as bool? ?? false,
      tool: json['tool'] as String? ?? '',
      version: json['version'] as String? ?? '',
      ruleCount: (json['rule_count'] as num?)?.toInt() ?? 0,
      customRuleCount: (json['custom_rule_count'] as num?)?.toInt() ?? 0,
      defaultIn: json['default_in'] as String? ?? 'ACCEPT',
      defaultOut: json['default_out'] as String? ?? 'ACCEPT',
    );

Map<String, dynamic> _$$FirewallStatusImplToJson(
        _$FirewallStatusImpl instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'tool': instance.tool,
      'version': instance.version,
      'rule_count': instance.ruleCount,
      'custom_rule_count': instance.customRuleCount,
      'default_in': instance.defaultIn,
      'default_out': instance.defaultOut,
    };
