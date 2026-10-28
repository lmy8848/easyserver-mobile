import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_toast.dart';
import '../../../core/nav_once.dart';
import '../../../domain/entities/web_server.dart';
import '../../providers/web_provider.dart';

/// 网站管理：Web 服务器列表（状态/启停/重启），点进已安装的服务器管理网站
class WebServersScreen extends ConsumerWidget {
  const WebServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final serversAsync = ref.watch(webServersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('网站管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.read(webActionsProvider).refreshServers(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(webServersProvider.future),
        child: serversAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Center(child: Text('加载失败', style: theme.textTheme.titleMedium)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text('$e',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.tonal(
                  onPressed: () => ref.invalidate(webServersProvider),
                  child: const Text('重试'),
                ),
              ),
            ],
          ),
          data: (servers) {
            if (servers.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 140),
                  Icon(Icons.dns_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('没有可管理的 Web 服务器',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey)),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: servers.length,
              itemBuilder: (context, i) => _ServerCard(
                server: servers[i],
                onAction: (action) => _serverAction(context, ref, servers[i], action),
                onOpen: () => pushOnce(
                    context, '/web/${servers[i].id}/${Uri.encodeComponent(servers[i].displayName)}'),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _serverAction(BuildContext context, WidgetRef ref,
      WebServer server, String action) async {
    // WebActions 内部经 ActionGuard 去重，连点只发一次
    final ok =
        await ref.read(webActionsProvider).serverAction(action, server);
    if (!ok) return;
    final label = const {
      'start': '启动',
      'stop': '停止',
      'restart': '重启',
      'reload': '重载配置',
    }[action]!;
    AppToast.show('$label ${server.displayName} 指令已下发');
  }
}

class _ServerCard extends StatelessWidget {
  final WebServer server;
  final ValueChanged<String> onAction;
  final VoidCallback onOpen;

  const _ServerCard({
    required this.server,
    required this.onAction,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final installed = server.status != 'not_installed';
    final running = server.status == 'running';
    final statusColor = running
        ? Colors.green.shade600
        : installed
            ? Colors.orange.shade700
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: installed ? onOpen : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.dns_outlined, color: statusColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      server.displayName,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      running
                          ? '运行中'
                          : installed
                              ? '已停止'
                              : '未安装',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (server.version.isNotEmpty) 'v${server.version}',
                  if (running) ...[
                    '运行 ${server.uptime.isEmpty ? '-' : server.uptime}',
                    _mem(server.memoryBytes),
                  ],
                  if (installed && !server.configOk) '配置异常',
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: installed && !server.configOk
                        ? Colors.red.shade400
                        : Colors.grey),
              ),
              if (installed) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: running ? () => onAction('reload') : null,
                      icon: const Icon(Icons.bolt, size: 16),
                      label: const Text('重载'),
                    ),
                    TextButton.icon(
                      onPressed: () => onAction('restart'),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('重启'),
                    ),
                    TextButton.icon(
                      onPressed: running
                          ? () => onAction('stop')
                          : () => onAction('start'),
                      icon: Icon(
                        running ? Icons.stop : Icons.play_arrow,
                        size: 16,
                        color: running ? Colors.red : Colors.green,
                      ),
                      label: Text(running ? '停止' : '启动'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _mem(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
