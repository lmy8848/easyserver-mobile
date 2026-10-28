import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_toast.dart';
import '../../../domain/entities/web_server.dart';
import '../../providers/web_provider.dart';

const _projectTypes = <String, String>{
  'static': '静态站点',
  'nodejs': 'Node.js',
  'php': 'PHP',
  'python': 'Python',
  'java': 'Java',
  'proxy': '反向代理',
};

/// 新建网站表单：动态应用类项目需要应用端口/启动命令，反代需要转发目标
Future<void> showWebsiteEditSheet(BuildContext context, WidgetRef ref,
    {required int serverId}) async {
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _WebsiteEditSheet(serverId: serverId),
  );
}

class _WebsiteEditSheet extends ConsumerStatefulWidget {
  final int serverId;

  const _WebsiteEditSheet({required this.serverId});

  @override
  ConsumerState<_WebsiteEditSheet> createState() => _WebsiteEditSheetState();
}

class _WebsiteEditSheetState extends ConsumerState<_WebsiteEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _domain;
  late final TextEditingController _rootPath;
  late final TextEditingController _port;
  late final TextEditingController _appPort;
  late final TextEditingController _proxyPass;
  late final TextEditingController _startCommand;
  String _projectType = 'static';
  bool _saving = false;

  bool get _isProxy => _projectType == 'proxy';
  bool get _isApp => ['nodejs', 'php', 'python', 'java'].contains(_projectType);

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _domain = TextEditingController();
    _rootPath = TextEditingController();
    _port = TextEditingController();
    _appPort = TextEditingController();
    _proxyPass = TextEditingController();
    _startCommand = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in [_name, _domain, _rootPath, _port, _appPort, _proxyPass, _startCommand]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text('新建网站',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '站点名称 *',
                hintText: '字母/数字/连字符，如 my-site',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '必填' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _domain,
              decoration: const InputDecoration(
                labelText: '域名 *',
                hintText: '如 demo.example.com',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.url,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '必填' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rootPath,
              decoration: const InputDecoration(
                labelText: '站点根目录 *',
                hintText: '服务器上的绝对路径，如 /opt/www/demo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '必填' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _projectType,
              decoration: const InputDecoration(
                labelText: '项目类型',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _projectTypes.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _projectType = v ?? 'static'),
            ),
            if (!_isProxy) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _port,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: const InputDecoration(
                  labelText: '监听端口（可选）',
                  hintText: '留空用服务器默认端口',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            if (_isApp) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _appPort,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: InputDecoration(
                  labelText: '应用端口（可选）',
                  hintText: _isProxy ? '' : '如 Node.js 监听 3000',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startCommand,
                decoration: const InputDecoration(
                  labelText: '启动命令（可选）',
                  hintText: '如 npm run start',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            if (_isProxy) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _proxyPass,
                decoration: const InputDecoration(
                  labelText: '转发目标',
                  hintText: '如 http://127.0.0.1:8080',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.url,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                label: const Text('创建网站'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final input = CreateWebsiteInput(
        name: _name.text.trim(),
        domain: _domain.text.trim(),
        rootPath: _rootPath.text.trim(),
        port: int.tryParse(_port.text.trim()) ?? 0,
        projectType: _projectType,
        appPort: int.tryParse(_appPort.text.trim()) ?? 0,
        proxyPass: _proxyPass.text.trim(),
        startCommand: _startCommand.text.trim(),
      );
      // 守卫去重：连点只发一次创建请求
      final ok = await ref
          .read(webActionsProvider)
          .createWebsite(widget.serverId, input);
      if (!ok) {
        if (mounted) AppToast.show('正在创建中，请勿重复提交', error: true);
        return;
      }
      if (mounted) {
        AppToast.show('网站已创建');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) AppToast.show('创建失败: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
