import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_toast.dart';
import '../../../domain/entities/cron_task.dart';
import '../../providers/cron_provider.dart';
import 'cron_detail_screen.dart';
import 'cron_edit_screen.dart';
import 'cron_format.dart';

/// 计划任务：systemd timer 管理的定时任务列表/启停/手动触发/编辑/删除
class CronScreen extends ConsumerWidget {
  const CronScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(cronListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('计划任务'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.invalidate(cronListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add_alarm),
        label: const Text('新建任务'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(cronListProvider.future),
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Center(
                child: Text('加载失败',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text('$e',
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.tonal(
                  onPressed: () => ref.invalidate(cronListProvider),
                  child: const Text('重试'),
                ),
              ),
            ],
          ),
          data: (tasks) {
            if (tasks.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 140),
                  Icon(Icons.schedule, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('还没有定时任务',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey)),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('点右下角「新建任务」创建',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey)),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: tasks.length,
              itemBuilder: (context, i) => _CronCard(
                task: tasks[i],
                onToggle: (v) => _toggle(context, ref, tasks[i], v),
                onRun: () => _run(context, ref, tasks[i]),
                onEdit: () => _openEditor(context, ref, task: tasks[i]),
                onDetail: () => _openDetail(context, tasks[i]),
                onDelete: () => _delete(context, ref, tasks[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _toggle(
      BuildContext context, WidgetRef ref, CronTask task, bool enabled) async {
    try {
      await ref.read(cronActionsProvider).setEnabled(task, enabled);
      AppToast.show(enabled ? '已启用 ${task.name}' : '已禁用 ${task.name}');
    } catch (e) {
      AppToast.show('操作失败: $e', error: true);
    }
    if (context.mounted) ref.invalidate(cronListProvider);
  }

  Future<void> _run(BuildContext context, WidgetRef ref, CronTask task) async {
    try {
      await ref.read(cronActionsProvider).run(task);
      AppToast.show('已触发 ${task.name}，稍后可在详情查看结果');
      // 触发是异步的，稍等再刷新让状态回到列表
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) ref.invalidate(cronListProvider);
      });
    } catch (e) {
      AppToast.show('触发失败: $e', error: true);
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, CronTask task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定删除「${task.name}」？该操作不可撤销。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
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
      await ref.read(cronActionsProvider).delete(task);
      AppToast.show('已删除 ${task.name}');
    } catch (e) {
      AppToast.show('删除失败: $e', error: true);
    }
    if (context.mounted) ref.invalidate(cronListProvider);
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref,
      {CronTask? task}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CronEditScreen(task: task)),
    );
    if (saved == true) ref.invalidate(cronListProvider);
  }

  void _openDetail(BuildContext context, CronTask task) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CronDetailScreen(task: task)),
    );
  }
}

class _CronCard extends StatelessWidget {
  final CronTask task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRun;
  final VoidCallback onEdit;
  final VoidCallback onDetail;
  final VoidCallback onDelete;

  const _CronCard({
    required this.task,
    required this.onToggle,
    required this.onRun,
    required this.onEdit,
    required this.onDetail,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = task.lastResult.toLowerCase() == 'failed';
    final color =
        task.enabled ? (failed ? Colors.orange : Colors.green) : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onDetail,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, size: 20, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(task.name,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Switch(
                    value: task.enabled,
                    onChanged: onToggle,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (v) {
                      switch (v) {
                        case 'run':
                          onRun();
                        case 'detail':
                          onDetail();
                        case 'edit':
                          onEdit();
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'run',
                          child: ListTile(
                              dense: true,
                              leading: Icon(Icons.play_arrow),
                              title: Text('立即运行'))),
                      PopupMenuItem(
                          value: 'detail',
                          child: ListTile(
                              dense: true,
                              leading: Icon(Icons.history),
                              title: Text('执行历史'))),
                      PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                              dense: true,
                              leading: Icon(Icons.edit),
                              title: Text('编辑'))),
                      PopupMenuDivider(),
                      PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                              dense: true,
                              leading: Icon(Icons.delete_outline),
                              title: Text('删除'))),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28, right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.description.isNotEmpty) ...[
                      Text(task.description,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.repeat, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(scheduleText(task.schedule),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey)),
                        if (task.nextRun.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text('下次 ${shortTime(task.nextRun)}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                    if (task.lastRun.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                              failed
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              size: 13,
                              color: failed ? Colors.orange : Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                                '上次 ${shortTime(task.lastRun)}'
                                '${task.lastResult.isNotEmpty ? ' · ${runStatusText(task.lastResult)}' : ''}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
