import 'package:freezed_annotation/freezed_annotation.dart';

part 'firewall_status.freezed.dart';
part 'firewall_status.g.dart';

/// 防火墙状态（后端 internal/domain/firewall.FirewallStatus）
@freezed
class FirewallStatus with _$FirewallStatus {
  const factory FirewallStatus({
    @Default(false) bool enabled,
    @Default('') String tool,
    @Default('') String version,
    @JsonKey(name: 'rule_count') @Default(0) int ruleCount,
    @JsonKey(name: 'custom_rule_count') @Default(0) int customRuleCount,
    @JsonKey(name: 'default_in') @Default('ACCEPT') String defaultIn,
    @JsonKey(name: 'default_out') @Default('ACCEPT') String defaultOut,
  }) = _FirewallStatus;

  factory FirewallStatus.fromJson(Map<String, dynamic> json) =>
      _$FirewallStatusFromJson(json);
}
