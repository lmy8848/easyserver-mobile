import 'package:freezed_annotation/freezed_annotation.dart';

part 'firewall_rule.freezed.dart';
part 'firewall_rule.g.dart';

/// 防火墙规则（后端 internal/domain/firewall.FirewallRule）
@freezed
class FirewallRule with _$FirewallRule {
  const factory FirewallRule({
    @Default(0) int id,
    @Default('INPUT') String chain,
    @Default('tcp') String protocol,
    @Default('') String port,
    @Default('ACCEPT') String action,
    @Default('') String source,
    @Default('') String target,
    @Default(true) bool enabled,
    @Default(0) int priority,
    @JsonKey(name: 'ip_version') @Default('both') String ipVersion,
    @Default('') String remark,
    @JsonKey(name: 'created_at') @Default('') String createdAt,
  }) = _FirewallRule;

  factory FirewallRule.fromJson(Map<String, dynamic> json) =>
      _$FirewallRuleFromJson(json);
}

/// 新建/更新规则的请求体。更新时后端按字段可选处理，这里统一发全量。
class FirewallRuleInput {
  final String chain;
  final String protocol;
  final String port;
  final String action;
  final String source;
  final String ipVersion;
  final String remark;

  const FirewallRuleInput({
    required this.chain,
    this.protocol = 'tcp',
    this.port = '',
    required this.action,
    this.source = '',
    this.ipVersion = 'both',
    this.remark = '',
  });

  factory FirewallRuleInput.fromRule(FirewallRule r) => FirewallRuleInput(
        chain: r.chain,
        protocol: r.protocol,
        port: r.port,
        action: r.action,
        source: r.source,
        ipVersion: r.ipVersion,
        remark: r.remark,
      );

  Map<String, dynamic> toJson() => {
        'chain': chain,
        'protocol': protocol,
        'port': port,
        'action': action,
        'source': source,
        'ip_version': ipVersion,
        'remark': remark,
      };
}
