import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_overlay.dart';

class ServicesTab extends ConsumerStatefulWidget {
  const ServicesTab({super.key});
  @override
  ConsumerState<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends ConsumerState<ServicesTab> {
  String _filter = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final servicesAsync = ref.watch(serviceListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索服务...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _filter.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () {
                      _searchController.clear();
                      setState(() => _filter = '');
                    })
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(serviceListProvider.future),
            child: servicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('加载失败', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('$e', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 16),
                    FilledButton.tonal(onPressed: () => ref.invalidate(serviceListProvider), child: const Text('重试')),
                  ],
                ),
              ),
              data: (services) {
                final filtered = _filter.isEmpty
                    ? services
                    : services.where((s) =>
                        s.name.toLowerCase().contains(_filter.toLowerCase()) ||
                        s.displayName.toLowerCase().contains(_filter.toLowerCase())).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_filter.isEmpty ? Icons.miscellaneous_services_outlined : Icons.search_off,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(_filter.isEmpty ? '暂无服务' : '未找到匹配的服务', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final service = filtered[index];
                    return _ServiceCard(service: service);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  final dynamic service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actionState = ref.watch(serviceActionProvider(service.name));
    final isRunning = service.state == 'active' || service.state == 'running';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LoadingOverlay(
          isLoading: actionState.isLoading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isRunning ? Icons.check_circle : Icons.cancel,
                    size: 20,
                    color: isRunning ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(service.displayName ?? service.name, style: theme.textTheme.titleSmall)),
                  StatusBadge(status: service.state),
                ],
              ),
              if (service.description != null && service.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(service.description!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (service.pid != null) ...[
                    Text('PID: ${service.pid}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    const SizedBox(width: 16),
                  ],
                  if (service.memoryBytes != null)
                    Text('内存: ${_formatBytes(service.memoryBytes!)}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  if (service.cpuPercent != null) ...[
                    const SizedBox(width: 16),
                    Text('CPU: ${service.cpuPercent!.toStringAsFixed(1)}%', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                  const Spacer(),
                  if (service.enabled != null)
                    Icon(
                      service.enabled! ? Icons.toggle_on : Icons.toggle_off_outlined,
                      size: 20,
                      color: service.enabled! ? Colors.green : Colors.grey,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isRunning)
                    _actionButton(Icons.stop, '停止', Colors.red.shade400, () => ref.read(serviceActionProvider(service.name).notifier).stop())
                  else
                    _actionButton(Icons.play_arrow, '启动', Colors.green.shade400, () => ref.read(serviceActionProvider(service.name).notifier).start()),
                  const SizedBox(width: 8),
                  _actionButton(Icons.refresh, '重启', Colors.orange.shade400, () => ref.read(serviceActionProvider(service.name).notifier).restart()),
                ],
              ),
              if (actionState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(actionState.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              if (actionState.success)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('操作成功', style: TextStyle(color: Colors.green.shade600, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 28,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
