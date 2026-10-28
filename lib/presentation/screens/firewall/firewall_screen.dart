import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_toast.dart';
import '../../../domain/entities/firewall_rule.dart';
import '../../../domain/entities/firewall_status.dart';
import '../../providers/firewall_provider.dart';
import 'firewall_edit_screen.dart';

/// 防火墙：状态总览（总开关/默认策略）+ 自定义规则管理（启停/排序/编辑/删除）
class FirewallScreen extends ConsumerWidget {
  const FirewallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(firewallStatusProvider);
    final rulesAsync = ref.watch(firewallRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('防火墙'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.read(firewallActionsProvider).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.rule),
        label: const Text('新建规则'),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.refresh(firewallStatusProvider.future),
          ref.refresh(firewallRulesProvider.future),
        ]),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          children: [
            statusAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                child: ListTile(
                  leading: Icon(Icons.error_outline, color: Colors.red.shade300),
                  title: const Text('状态加载失败'),
                  subtitle: Text('$e', maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ),
              data: (status) => _StatusCard(status: status),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
              child: Text('自定义规则',
                  style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
            ),
            rulesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Card(
                child: ListTile(
                  leading: Icon(Icons.error_outline, color: Colors.red.shade300),
                  title: const Text('规则加载失败'),
                  subtitle: Text('$e', maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: TextButton(
                    onPressed: () => ref.invalidate(firewallRulesProvider),
                    child: const Text('重试'),
                  ),
                ),
              ),
              data: (rules) {
                if (rules.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.rule, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('还没有自定义规则',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('点右下角「新建规则」放行需要的端口',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final rule in rules)
                      _RuleCard(
                        rule: rule,
                        onToggle: (v) => _toggleRule(context, ref, rule, v),
                        onEdit: () => _openEditor(context, ref, rule: rule),
                        onMoveUp: () => _move(context, ref, rule, up: true),
                        onMoveDown: () => _move(context, ref, rule, up: false),
                        onDelete: () => _delete(context, ref, rule),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRule(BuildContext context, WidgetRef ref,
      FirewallRule rule, bool enabled) async {
    try {
      await ref.read(firewallActionsProvider).setRuleEnabled(rule, enabled);
      AppToast.show(enabled ? '规则已启用' : '规则已禁用');
    } catch (e) {
      AppToast.show('操作失败: $e', error: true);
    }
    if (context.mounted) ref.invalidate(firewallRulesProvider);
  }

  Future<void> _move(BuildContext context, WidgetRef ref, FirewallRule rule,
      {required bool up}) async {
    try {
      await ref.read(firewallActionsProvider).moveRule(rule, up: up);
    } catch (e) {
      AppToast.show('操作失败: $e', error: true);
    }
    if (context.mounted) ref.invalidate(firewallRulesProvider);
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, FirewallRule rule) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除规则'),
        content: Text('确定删除 ${rule.chain} ${rule.protocol.toUpperCase()} '
            '${rule.port.isEmpty ? '全部端口' : rule.port} 的规则吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(firewallActionsProvider).deleteRule(rule);
      AppToast.show('规则已删除');
    } catch (e) {
      AppToast.show('删除失败: $e', error: true);
    }
    if (context.mounted) ref.invalidate(firewallRulesProvider);
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref,
      {FirewallRule? rule}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FirewallEditScreen(rule: rule)),
    );
    if (changed == true) ref.read(firewallActionsProvider).refresh();
  }
}

/// 状态总览卡：总开关 + 默认策略 + 规则计数
class _StatusCard extends ConsumerWidget {
  final FirewallStatus status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enabledColor =
        status.enabled ? Colors.green.shade600 : Colors.orange.shade700;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: enabledColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('防火墙已${status.enabled ? '开启' : '关闭'}',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        status.tool.isEmpty
                            ? '未检测到防火墙工具'
                            : '${status.tool}${status.version.isEmpty ? '' : ' · $status.version'}'
                                ' · 规则 ${status.ruleCount} 条（自定义 ${status.customRuleCount}）',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: status.enabled,
                  onChanged: (v) => _confirmToggle(context, ref, v),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _PolicyTile(
                    label: '入站默认策略',
                    value: status.defaultIn,
                    onChanged: (p) => _setPolicy(context, ref, 'INPUT', p),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PolicyTile(
                    label: '出站默认策略',
                    value: status.defaultOut,
                    onChanged: (p) => _setPolicy(context, ref, 'OUTPUT', p),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmToggle(
      BuildContext context, WidgetRef ref, bool enable) async {
    if (enable) {
      // 开启防火墙直接执行；但先提示默认策略，避免 DROP 锁死自己
      try {
        await ref.read(firewallActionsProvider).setEnabled(true);
        AppToast.show('防火墙已开启');
      } catch (e) {
        AppToast.show('操作失败: $e', error: true);
      }
      if (context.mounted) ref.invalidate(firewallStatusProvider);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('关闭防火墙'),
        content: const Text('关闭后所有端口将失去防护，服务器会直接暴露在公网。确定要关闭吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
    if (ok != true) {
      if (context.mounted) ref.invalidate(firewallStatusProvider);
      return;
    }
    try {
      await ref.read(firewallActionsProvider).setEnabled(false);
      AppToast.show('防火墙已关闭');
    } catch (e) {
      AppToast.show('操作失败: $e', error: true);
    }
    if (context.mounted) ref.invalidate(firewallStatusProvider);
  }

  Future<void> _setPolicy(
      BuildContext context, WidgetRef ref, String chain, String policy) async {
    try {
      await ref
          .read(firewallActionsProvider)
          .setDefaultPolicy(chain: chain, policy: policy);
      AppToast.show('已设置 ${chain == 'INPUT' ? '入站' : '出站'}默认策略为 $policy');
    } catch (e) {
      AppToast.show('设置失败: $e', error: true);
    }
    if (context.mounted) ref.invalidate(firewallStatusProvider);
  }
}

/// 单个默认策略展示 + 点击修改
class _PolicyTile extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _PolicyTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _pick(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(value,
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: value == 'DROP'
                            ? Colors.red.shade400
                            : Colors.green.shade600)),
                const SizedBox(width: 4),
                Icon(Icons.edit_outlined,
                    size: 14, color: Colors.grey.shade500),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('$label（$value）'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'ACCEPT'),
            child: const Text('ACCEPT · 默认放行'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'DROP'),
            child: const Text('DROP · 默认丢弃（未放行的端口全部不通）'),
          ),
        ],
      ),
    );
    if (picked != null && picked != value) onChanged(picked);
  }
}

/// 单条规则卡
class _RuleCard extends StatelessWidget {
  final FirewallRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;

  const _RuleCard({
    required this.rule,
    required this.onToggle,
    required this.onEdit,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAccept = rule.action == 'ACCEPT';
    final actionColor = isAccept ? Colors.green.shade600 : Colors.red.shade400;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(rule.action,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: actionColor)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${rule.chain} · ${rule.protocol.toUpperCase()} ${rule.port.isEmpty ? '-' : rule.port}',
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: rule.enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      '来源: ${rule.source.isEmpty ? '任意' : rule.source}',
                      'IP: ${rule.ipVersion}',
                      if (rule.remark.isNotEmpty) rule.remark,
                    ].join(' · '),
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        onEdit();
                      case 'up':
                        onMoveUp();
                      case 'down':
                        onMoveDown();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('编辑')),
                    PopupMenuItem(value: 'up', child: Text('上移（提高优先级）')),
                    PopupMenuItem(value: 'down', child: Text('下移（降低优先级）')),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('删除', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
