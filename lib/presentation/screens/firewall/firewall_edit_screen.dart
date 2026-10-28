import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_toast.dart';
import '../../../di/providers.dart';
import '../../../domain/entities/firewall_rule.dart';
import '../../providers/firewall_provider.dart';
import 'firewall_validate.dart';

/// 新建/编辑防火墙规则
class FirewallEditScreen extends ConsumerStatefulWidget {
  /// null = 新建
  final FirewallRule? rule;

  const FirewallEditScreen({super.key, this.rule});

  @override
  ConsumerState<FirewallEditScreen> createState() => _FirewallEditScreenState();
}

class _FirewallEditScreenState extends ConsumerState<FirewallEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _port;
  late final TextEditingController _source;
  late final TextEditingController _remark;
  late String _chain;
  late String _protocol;
  late String _action;
  late String _ipVersion;
  bool _saving = false;

  bool get _isEdit => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _port = TextEditingController(text: r?.port ?? '');
    _source = TextEditingController(text: r?.source ?? '');
    _remark = TextEditingController(text: r?.remark ?? '');
    _chain = r?.chain ?? 'INPUT';
    _protocol = r?.protocol ?? 'tcp';
    _action = r?.action ?? 'ACCEPT';
    _ipVersion = r?.ipVersion ?? 'both';
  }

  @override
  void dispose() {
    _port.dispose();
    _source.dispose();
    _remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑规则' : '新建规则'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionLabel('链'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'INPUT', label: Text('入站')),
                ButtonSegment(value: 'OUTPUT', label: Text('出站')),
                ButtonSegment(value: 'FORWARD', label: Text('转发')),
              ],
              selected: {_chain},
              onSelectionChanged: (s) => setState(() => _chain = s.first),
            ),
            const SizedBox(height: 16),
            _sectionLabel('动作'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ACCEPT', label: Text('放行')),
                ButtonSegment(value: 'DROP', label: Text('丢弃')),
                ButtonSegment(value: 'REJECT', label: Text('拒绝')),
              ],
              selected: {_action},
              onSelectionChanged: (s) => setState(() => _action = s.first),
            ),
            const SizedBox(height: 16),
            _sectionLabel('协议'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'tcp', label: Text('TCP')),
                ButtonSegment(value: 'udp', label: Text('UDP')),
                ButtonSegment(value: 'all', label: Text('全部')),
              ],
              selected: {_protocol},
              onSelectionChanged: (s) => setState(() => _protocol = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _port,
              decoration: const InputDecoration(
                labelText: '端口',
                hintText: '如 80 或 8000-9000，留空表示全部端口',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d-]'))],
              validator: _validatePort,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _source,
              decoration: const InputDecoration(
                labelText: '来源 IP/CIDR（可选）',
                hintText: '如 192.168.1.0/24，留空表示任意来源',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: _validateSource,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _ipVersion,
              decoration: const InputDecoration(
                labelText: 'IP 版本',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'both', child: Text('IPv4 + IPv6')),
                DropdownMenuItem(value: 'ipv4', child: Text('仅 IPv4')),
                DropdownMenuItem(value: 'ipv6', child: Text('仅 IPv6')),
              ],
              onChanged: (v) => setState(() => _ipVersion = v ?? 'both'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remark,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '这条规则是干什么的',
                border: OutlineInputBorder(),
              ),
              maxLength: 60,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey)),
      );

  String? _validatePort(String? v) => validateFirewallPort(v);

  String? _validateSource(String? v) => validateFirewallSource(v);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final input = FirewallRuleInput(
      chain: _chain,
      protocol: _protocol,
      port: _port.text.trim(),
      action: _action,
      source: _source.text.trim(),
      ipVersion: _ipVersion,
      remark: _remark.text.trim(),
    );
    try {
      final actions = ref.read(firewallActionsProvider);
      if (_isEdit) {
        await ref
            .read(firewallRepositoryProvider)
            .updateRule(widget.rule!.id, input);
      } else {
        await ref.read(firewallRepositoryProvider).createRule(input);
      }
      actions.refresh();
      if (mounted) {
        AppToast.show(_isEdit ? '规则已更新' : '规则已创建');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) AppToast.show('保存失败: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
