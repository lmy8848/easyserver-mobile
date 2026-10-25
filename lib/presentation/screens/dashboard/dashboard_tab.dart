import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/monitor_provider.dart';
import '../../widgets/metric_card.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});
  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monitorProvider.notifier).fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monitorState = ref.watch(monitorProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(monitorProvider.notifier).fetchStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: monitorState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('加载失败', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('$e',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 16),
              FilledButton.tonal(
                  onPressed: () =>
                      ref.read(monitorProvider.notifier).fetchStats(),
                  child: const Text('重试')),
            ],
          )),
          data: (snapshot) {
            if (snapshot == null) {
              return const Center(child: Text('暂无数据'));
            }

            final cpu = snapshot.cpu;
            final mem = snapshot.memory;
            final disk = snapshot.disk;
            final net = snapshot.network;
            final processes = snapshot.topProcess ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CPU + Memory + Disk row
                Row(
                  children: [
                    Expanded(
                        child: MetricCard(
                      title: 'CPU',
                      value: '${cpu.usagePercent.toStringAsFixed(1)}%',
                      subtitle: '1m: ${cpu.load1m.toStringAsFixed(1)}',
                      icon: Icons.memory,
                      color: cpu.usagePercent > 80
                          ? Colors.red
                          : (cpu.usagePercent > 50
                              ? Colors.orange
                              : Colors.green),
                      progress: cpu.usagePercent / 100,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: MetricCard(
                      title: '内存',
                      value: '${mem.usagePercent.toStringAsFixed(1)}%',
                      subtitle: _formatBytes(mem.usedBytes) +
                          ' / ' +
                          _formatBytes(mem.totalBytes),
                      icon: Icons.storage,
                      color: mem.usagePercent > 80
                          ? Colors.red
                          : (mem.usagePercent > 50
                              ? Colors.orange
                              : Colors.green),
                      progress: mem.usagePercent / 100,
                    )),
                  ],
                ),
                const SizedBox(height: 12),

                // Disk
                if (disk.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.disc_full,
                                size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('磁盘', style: theme.textTheme.titleSmall)
                          ]),
                          const SizedBox(height: 12),
                          ...disk.take(3).map((d) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(d.mountPoint,
                                              style: theme.textTheme.bodySmall),
                                          Text(
                                              '${d.usagePercent.toStringAsFixed(1)}%',
                                              style: theme.textTheme.bodySmall),
                                        ]),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (d.usagePercent / 100)
                                            .clamp(0.0, 1.0),
                                        backgroundColor: Colors.grey.shade200,
                                        color: d.usagePercent > 80
                                            ? Colors.red
                                            : Colors.blue,
                                        minHeight: 6,
                                      ),
                                    ),
                                    Text(
                                        '${_formatBytes(d.usedBytes)} / ${_formatBytes(d.totalBytes)}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: Colors.grey,
                                                fontSize: 11)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Network
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.wifi,
                              size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('网络流量', style: theme.textTheme.titleSmall)
                        ]),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _networkTile(
                                    '↑ 发送',
                                    _formatBytes(net.bytesSent),
                                    Icons.arrow_upward,
                                    Colors.blue)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _networkTile(
                                    '↓ 接收',
                                    _formatBytes(net.bytesRecv),
                                    Icons.arrow_downward,
                                    Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Top Processes
                if (processes.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.list,
                                size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Top 进程', style: theme.textTheme.titleSmall)
                          ]),
                          const SizedBox(height: 8),
                          ...processes.take(5).map((p) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    SizedBox(
                                        width: 40,
                                        child: Text('${p.pid}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: Colors.grey))),
                                    Expanded(
                                        child: Text(p.name,
                                            style: theme.textTheme.bodyMedium,
                                            overflow: TextOverflow.ellipsis)),
                                    Text('${p.cpuPercent.toStringAsFixed(1)}%',
                                        style: theme.textTheme.bodySmall),
                                    const SizedBox(width: 12),
                                    Text(_formatBytes(p.memBytes),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: Colors.grey)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _networkTile(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
