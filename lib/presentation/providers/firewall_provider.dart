import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/action_guard.dart';
import '../../di/providers.dart';
import '../../domain/entities/firewall_rule.dart';
import '../../domain/entities/firewall_status.dart';

/// 防火墙状态：开关/默认策略变更后 invalidate 刷新
final firewallStatusProvider =
    FutureProvider.autoDispose<FirewallStatus>((ref) {
  return ref.read(firewallRepositoryProvider).status();
});

/// 自定义规则列表：增删改后 invalidate 刷新
final firewallRulesProvider =
    FutureProvider.autoDispose<List<FirewallRule>>((ref) {
  return ref.read(firewallRepositoryProvider).listRules();
});

/// 防火墙操作：统一走这里，成功后由调用方刷新。
/// 写操作经 ActionGuard 去重，连点同键只发一次请求。
class FirewallActions {
  final Ref _ref;
  FirewallActions(this._ref);

  Future<void> setEnabled(bool enabled) async {
    await globalActionGuard.run('firewall:${enabled ? 'enable' : 'disable'}',
        () async {
      final repo = _ref.read(firewallRepositoryProvider);
      if (enabled) {
        await repo.enable();
      } else {
        await repo.disable();
      }
    });
  }

  Future<void> setDefaultPolicy(
      {required String chain, required String policy}) async {
    await globalActionGuard.run(
        'firewall:policy:$chain:$policy',
        () => _ref
            .read(firewallRepositoryProvider)
            .setDefaultPolicy(chain: chain, policy: policy));
  }

  Future<void> deleteRule(FirewallRule rule) async {
    await globalActionGuard.run('firewall:delete:${rule.id}',
        () => _ref.read(firewallRepositoryProvider).deleteRule(rule.id));
  }

  Future<void> setRuleEnabled(FirewallRule rule, bool enabled) async {
    await globalActionGuard.run(
        'firewall:rule:${enabled ? 'enable' : 'disable'}:${rule.id}', () async {
      final repo = _ref.read(firewallRepositoryProvider);
      if (enabled) {
        await repo.enableRule(rule.id);
      } else {
        await repo.disableRule(rule.id);
      }
    });
  }

  Future<void> moveRule(FirewallRule rule, {required bool up}) async {
    await globalActionGuard.run(
        'firewall:move:${up ? 'up' : 'down'}:${rule.id}',
        () => _ref.read(firewallRepositoryProvider).moveRule(rule.id, up: up));
  }

  void refresh() {
    _ref.invalidate(firewallStatusProvider);
    _ref.invalidate(firewallRulesProvider);
  }
}

final firewallActionsProvider =
    Provider<FirewallActions>((ref) => FirewallActions(ref));
