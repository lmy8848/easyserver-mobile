// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firewall_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FirewallRuleImpl _$$FirewallRuleImplFromJson(Map<String, dynamic> json) =>
    _$FirewallRuleImpl(
      id: (json['id'] as num?)?.toInt() ?? 0,
      chain: json['chain'] as String? ?? 'INPUT',
      protocol: json['protocol'] as String? ?? 'tcp',
      port: json['port'] as String? ?? '',
      action: json['action'] as String? ?? 'ACCEPT',
      source: json['source'] as String? ?? '',
      target: json['target'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      ipVersion: json['ip_version'] as String? ?? 'both',
      remark: json['remark'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );

Map<String, dynamic> _$$FirewallRuleImplToJson(_$FirewallRuleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chain': instance.chain,
      'protocol': instance.protocol,
      'port': instance.port,
      'action': instance.action,
      'source': instance.source,
      'target': instance.target,
      'enabled': instance.enabled,
      'priority': instance.priority,
      'ip_version': instance.ipVersion,
      'remark': instance.remark,
      'created_at': instance.createdAt,
    };
