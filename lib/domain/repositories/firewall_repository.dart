import '../entities/firewall_rule.dart';
import '../entities/firewall_status.dart';

abstract class FirewallRepository {
  Future<FirewallStatus> status();
  Future<void> enable();

  /// 禁用防火墙（后端要求显式 confirm）
  Future<void> disable();

  /// 设置链默认策略（chain: INPUT/OUTPUT，policy: ACCEPT/DROP）
  Future<void> setDefaultPolicy({required String chain, required String policy});

  /// 自定义规则列表，按优先级排序
  Future<List<FirewallRule>> listRules();

  Future<void> createRule(FirewallRuleInput input);
  Future<void> updateRule(int id, FirewallRuleInput input);
  Future<void> deleteRule(int id);
  Future<void> enableRule(int id);
  Future<void> disableRule(int id);

  /// 调整规则顺序（优先级），direction: up/down
  Future<void> moveRule(int id, {required bool up});
}
