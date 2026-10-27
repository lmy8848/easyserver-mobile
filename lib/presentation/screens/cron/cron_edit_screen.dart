import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_toast.dart';
import '../../../di/providers.dart';
import '../../../domain/entities/cron_task.dart';

/// 新建/编辑定时任务。调度表达式直接写 systemd OnCalendar，
/// 预设只负责填入常见值，仍可手改。
class CronEditScreen extends ConsumerStatefulWidget {
  /// null = 新建
  final CronTask? task;

  const CronEditScreen({super.key, this.task});

  @override
  ConsumerState<CronEditScreen> createState() => _CronEditScreenState();
}

class _CronEditScreenState extends ConsumerState<CronEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _schedule;
  late final TextEditingController _command;
  late final TextEditingController _workDir;
  late final TextEditingController _timeout;
  late final TextEditingController _retry;
  late final TextEditingController _env;
  late bool _persistent;
  bool _saving = false;

  static const _presets = <String, String>{
    '每分钟': '*-*-* *:*:00',
    '每小时': '*-*-* *:00:00',
    '每天 02:00': '*-*-* 02:00:00',
    '每周一 03:00': 'Mon *-*-* 03:00:00',
    '每月 1 日 04:00': '*-*-01 04:00:00',
  };

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _name = TextEditingController(text: t?.name ?? '');
    _desc = TextEditingController(text: t?.description ?? '');
    _schedule = TextEditingController(text: t?.schedule ?? '*-*-* 02:00:00');
    _command = TextEditingController(text: t?.command ?? '');
    _workDir = TextEditingController(text: t?.workDir ?? '');
    _timeout = TextEditingController(
        text: (t?.timeout ?? 0) > 0 ? '${t!.timeout}' : '');
    _retry = TextEditingController(
        text: (t?.maxRetry ?? 0) > 0 ? '${t!.maxRetry}' : '');
    _env = TextEditingController(text: t?.envVars ?? '');
    _persistent = t?.persistent ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _desc,
      _schedule,
      _command,
      _workDir,
      _timeout,
      _retry,
      _env,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑任务' : '新建任务'),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '任务名称',
                hintText: '如 backup-db，创建后作为 systemd 单元名',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
              ],
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return '请输入任务名称';
                if (RegExp(r'[^\w.@-]').hasMatch(s)) {
                  return '只能包含字母、数字、_ . @ -';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('调度', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _presets.entries
                  .map((e) => ActionChip(
                        label: Text(e.key),
                        onPressed: () => setState(() {
                          _schedule.text = e.value;
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _schedule,
              decoration: const InputDecoration(
                labelText: 'OnCalendar 表达式',
                helperText: 'systemd 日历语法，如 *-*-* 02:00:00 或 Mon *-*-* 03:00',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
              validator: (v) => (v?.trim().isEmpty ?? true) ? '请输入调度表达式' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _command,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '执行命令',
                hintText: '支持 && 组合，如 cd /srv && ./backup.sh',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
              validator: (v) => (v?.trim().isEmpty ?? true) ? '请输入执行命令' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _workDir,
              decoration: const InputDecoration(
                labelText: '工作目录（可选）',
                hintText: '/srv/app',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _timeout,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '超时（秒）',
                      hintText: '0 = 不超时',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _retry,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '失败重试',
                      hintText: '0 = 不重试',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _env,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '环境变量（可选）',
                hintText: '每行一个 KEY=VALUE',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _persistent,
              onChanged: (v) => setState(() => _persistent = v),
              title: const Text('错过执行后补跑'),
              subtitle: const Text('Persistent：系统关机期间错过的任务，开机后补执行一次'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final input = CronTaskInput(
      name: _name.text.trim(),
      description: _desc.text.trim(),
      schedule: _schedule.text.trim(),
      command: _command.text.trim(),
      persistent: _persistent,
      timeout: int.tryParse(_timeout.text.trim()) ?? 0,
      maxRetry: int.tryParse(_retry.text.trim()) ?? 0,
      envVars: _env.text.trim(),
      workDir: _workDir.text.trim(),
    );

    setState(() => _saving = true);
    final repo = ref.read(cronRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.update(widget.task!.name, input);
      } else {
        await repo.create(input);
      }
      if (!mounted) return;
      AppToast.show(_isEdit ? '已保存 ${input.name}' : '已创建 ${input.name}');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppToast.show('保存失败: $e', error: true);
      }
    }
  }
}
