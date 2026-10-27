import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_toast.dart';
import '../../../domain/entities/cron_task.dart';
import '../../providers/cron_provider.dart';
import 'cron_format.dart';

/// 任务详情 + 执行历史。日志来自 journald，按需展开。
class CronDetailScreen extends ConsumerWidget {
  final CronTask task;

  const CronDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final runsAsync = ref.watch(cronRunsProvider(task.name));

    return Scaffold(
      appBar: AppBar(
        title: Text(task.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: '立即运行',
            onPressed: () async {
              try {
                await ref.read(cronActionsProvider).run(task);
                AppToast.show('已触发 ${task.name}');
                // 任务在 systemd 侧异步执行，2 秒后再拉一次执行记录
                Future.delayed(const Duration(seconds: 2), () {
                  if (context.mounted) {
                    ref.invalidate(cronRunsProvider(task.name));
                  }
                });
              } catch (e) {
                AppToast.show('触发失败: $e', error: true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.invalidate(cronRunsProvider(task.name)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _infoCard(theme),
          const SizedBox(height: 16),
          Text('执行历史', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...runsAsync.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('加载失败: $e',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey)),
              ),
            ],
            data: (runs) {
              if (runs.isEmpty) {
                return [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('还没有执行记录',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey)),
                  ),
                ];
              }
              return runs.map((r) => _runCard(theme, r)).toList();
            },
          ),
        ],
      ),
    );
  }

  Widget _infoCard(ThemeData theme) {
    final rows = <(String, String)>[
      ('调度', '${scheduleText(task.schedule)}（${task.schedule}）'),
      ('命令', task.command.isEmpty ? '—' : task.command),
      if (task.workDir.isNotEmpty) ('工作目录', task.workDir),
      if (task.timeout > 0) ('超时', '${task.timeout} 秒'),
      if (task.maxRetry > 0) ('失败重试', '${task.maxRetry} 次'),
      if (task.envVars.isNotEmpty) ('环境变量', task.envVars),
      if (task.lastRun.isNotEmpty)
        (
          '上次运行',
          '${shortTime(task.lastRun)} · ${runStatusText(task.lastResult)}'
        ),
      if (task.nextRun.isNotEmpty) ('下次运行', shortTime(task.nextRun)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(task.enabled ? Icons.check_circle : Icons.pause_circle,
                    size: 18, color: task.enabled ? Colors.green : Colors.grey),
                const SizedBox(width: 6),
                Text(task.enabled ? '已启用' : '已禁用',
                    style: theme.textTheme.titleSmall),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(task.description,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
            const Divider(height: 20),
            for (final (k, v) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(k,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey)),
                    ),
                    Expanded(
                      child: Text(v,
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: k == '命令' ? 'monospace' : null)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _runCard(ThemeData theme, CronRun run) {
    final failed = run.status.toLowerCase() != 'success' &&
        run.status.toLowerCase() != 'running';
    final color = failed ? Colors.red : Colors.green;
    final logs = run.logs;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Icon(failed ? Icons.error_outline : Icons.check_circle_outline,
                size: 16, color: color),
            const SizedBox(width: 6),
            Text(runStatusText(run.status),
                style: theme.textTheme.bodyMedium?.copyWith(color: color)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(shortTime(run.startedAt),
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  overflow: TextOverflow.ellipsis),
            ),
            if (logs.isNotEmpty)
              Text('${logs.length} 行',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
        children: [
          if (logs.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('没有日志输出',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            )
          else
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 260),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  logs.map((l) => l.message).join('\n'),
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12, height: 1.3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
