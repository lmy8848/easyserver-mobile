import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/container_info.dart';
import '../../providers/container_provider.dart';
import '../../providers/home_state.dart';

class ContainersTab extends ConsumerStatefulWidget {
  const ContainersTab({super.key});
  @override
  ConsumerState<ContainersTab> createState() => _ContainersTabState();
}

class _ContainersTabState extends ConsumerState<ContainersTab> {
  String _filter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 懒加载：仅当本 tab 可见时首拉；切回时通过 listener 刷新
      if (ref.read(homeTabProvider) == 1) {
        ref.read(containerProvider.notifier).load();
      }
    });
  }

  void _openLogs(ContainerInfo c) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ContainerLogsPage(container: c),
    ));
  }

  Future<void> _confirmRemove(ContainerInfo c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除容器'),
        content: Text('确定删除 ${c.name}？该操作不可恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) ref.read(containerProvider.notifier).remove(c.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(containerProvider);
    // IndexedStack 常驻：切到本 tab 时懒加载
    ref.listen(homeTabProvider, (prev, next) {
      if (next == 1 && (prev ?? 0) != 1) {
        ref.read(containerProvider.notifier).load();
      }
    });

    final filtered = _filter.isEmpty
        ? state.items
        : state.items
            .where((c) =>
                c.name.toLowerCase().contains(_filter) ||
                c.image.toLowerCase().contains(_filter))
            .toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(containerProvider.notifier).load(force: true),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索容器 / 镜像...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) =>
                  setState(() => _filter = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: state.loading && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : !state.engineReady
                    ? _EngineMissing(
                        onRetry: () => ref
                            .read(containerProvider.notifier)
                            .load(force: true))
                    : state.error != null && state.items.isEmpty
                        ? _ErrorView(
                            message: state.error!,
                            onRetry: () => ref
                                .read(containerProvider.notifier)
                                .load(force: true))
                        : filtered.isEmpty
                            ? ListView(children: [
                                Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(children: [
                                    Icon(Icons.inventory_2_outlined,
                                        size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text('暂无容器',
                                        style: theme.textTheme.bodyMedium),
                                  ]),
                                ),
                              ])
                            : ListView.separated(
                                padding: const EdgeInsets.only(bottom: 16),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final c = filtered[i];
                                  return _ContainerTile(
                                    container: c,
                                    onLogs: () => _openLogs(c),
                                    onStart: () => ref
                                        .read(containerProvider.notifier)
                                        .start(c.id),
                                    onStop: () => ref
                                        .read(containerProvider.notifier)
                                        .stop(c.id),
                                    onRestart: () => ref
                                        .read(containerProvider.notifier)
                                        .restart(c.id),
                                    onRemove: () => _confirmRemove(c),
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}

class _ContainerTile extends StatelessWidget {
  final ContainerInfo container;
  final VoidCallback onLogs;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;
  final VoidCallback onRemove;

  const _ContainerTile({
    required this.container,
    required this.onLogs,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running = container.isRunning;
    final ports = container.ports
        .take(2)
        .map((p) => '${p.hostPort ?? '?'}→${p.containerPort ?? '?'}')
        .join('  ');

    return ListTile(
      leading: Icon(
        running ? Icons.check_circle : Icons.cancel,
        size: 22,
        color: running ? Colors.green : Colors.grey,
      ),
      title: Text(container.name,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(container.image,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          if (ports.isNotEmpty)
            Text('端口: $ports',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) {
          switch (action) {
            case 'logs':
              onLogs();
            case 'start':
              onStart();
            case 'stop':
              onStop();
            case 'restart':
              onRestart();
            case 'remove':
              onRemove();
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'logs', child: Text('日志')),
          if (!running) const PopupMenuItem(value: 'start', child: Text('启动')),
          if (running) ...[
            const PopupMenuItem(value: 'stop', child: Text('停止')),
            const PopupMenuItem(value: 'restart', child: Text('重启')),
          ],
          const PopupMenuDivider(),
          PopupMenuItem(
              value: 'remove',
              child: Text('删除', style: TextStyle(color: Colors.red.shade700))),
        ],
      ),
    );
  }
}

class _EngineMissing extends StatelessWidget {
  final VoidCallback onRetry;
  const _EngineMissing({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.view_in_ar_outlined,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('容器引擎未就绪', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('请先在面板 Web 端安装并启动 Docker',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('重新检测')),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('加载失败', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _ContainerLogsPage extends ConsumerStatefulWidget {
  final ContainerInfo container;
  const _ContainerLogsPage({required this.container});
  @override
  ConsumerState<_ContainerLogsPage> createState() => _ContainerLogsPageState();
}

class _ContainerLogsPageState extends ConsumerState<_ContainerLogsPage> {
  String _logs = '';
  bool _loading = false;
  String? _error;
  int _tail = 200;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final logs = await ref
          .read(containerRepositoryProvider)
          .logs(widget.container.id, tail: _tail);
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.container.name} 日志'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.format_list_numbered),
            tooltip: '行数',
            onSelected: (t) {
              _tail = t;
              _fetch();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 100, child: Text('最近 100 行')),
              PopupMenuItem(value: 200, child: Text('最近 200 行')),
              PopupMenuItem(value: 500, child: Text('最近 500 行')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            ),
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  _logs.isEmpty && !_loading ? '（无日志）' : _logs,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey,
                      height: 1.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
