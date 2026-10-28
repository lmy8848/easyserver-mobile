import '../../domain/entities/firewall_rule.dart';
import '../../domain/entities/firewall_status.dart';
import '../../domain/repositories/firewall_repository.dart';
import '../datasources/remote/api_client.dart';

class FirewallRepositoryImpl implements FirewallRepository {
  final ApiClient _api;

  FirewallRepositoryImpl(this._api);

  @override
  Future<FirewallStatus> status() async {
    final json = await _api.get('/firewall/status');
    return FirewallStatus.fromJson(json);
  }

  @override
  Future<void> enable() async {
    await _api.post('/firewall/enable');
  }

  @override
  Future<void> disable() async {
    await _api.post('/firewall/disable', data: {'confirm': true});
  }

  @override
  Future<void> setDefaultPolicy(
      {required String chain, required String policy}) async {
    await _api
        .post('/firewall/default-policy', data: {'chain': chain, 'policy': policy});
  }

  @override
  Future<List<FirewallRule>> listRules() async {
    // 后端分页参数 page_size 上限 200，一次取全
    final data = await _api.get('/firewall/rules',
        queryParameters: {'page': 1, 'page_size': 200});
    final items = (data['items'] ?? data['_items']) as List<dynamic>? ?? [];
    return items
        .map((e) => FirewallRule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createRule(FirewallRuleInput input) async {
    await _api.post('/firewall/rules', data: input.toJson());
  }

  @override
  Future<void> updateRule(int id, FirewallRuleInput input) async {
    await _api.put('/firewall/rules/$id', data: input.toJson());
  }

  @override
  Future<void> deleteRule(int id) async {
    await _api.delete('/firewall/rules/$id');
  }

  @override
  Future<void> enableRule(int id) async {
    await _api.post('/firewall/rules/$id/enable');
  }

  @override
  Future<void> disableRule(int id) async {
    await _api.post('/firewall/rules/$id/disable');
  }

  @override
  Future<void> moveRule(int id, {required bool up}) async {
    await _api.post('/firewall/rules/$id/${up ? 'move-up' : 'move-down'}');
  }
}
