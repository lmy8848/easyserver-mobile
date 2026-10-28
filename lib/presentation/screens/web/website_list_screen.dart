import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_toast.dart';
import '../../../domain/entities/web_server.dart';
import '../../providers/web_provider.dart';
import 'website_edit_sheet.dart';

/// 某台 Web 服务器下的网站列表：启停/删除/新建
class WebsiteListScreen extends ConsumerStatefulWidget {
  final int serverId;
  final String serverName;

  const WebsiteListScreen({
    super.key,
    required this.serverId,
    required this.serverName,
  });

  @override
  ConsumerState<WebsiteListScreen> createState() => _WebsiteListScreenState();
}

class _WebsiteListScreenState extends ConsumerState<WebsiteListScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sitesAsync = ref.watch(websitesProvider(widget.serverId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serverName),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showWebsiteEditSheet(context, ref,
            serverId: widget.serverId),
        icon: const Icon(Icons.add),
        label: const Text('新建网站'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(websitesProvider(widget.serverId).future),
        child: sitesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Center(child: Text('加载失败', style: theme.textTheme.titleMedium)),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.tonal(
                  onPressed: () =>
                      ref.invalidate(websitesProvider(widget.serverId)),
                  child: const Text('重试'),
                ),
              ),
            ],
          ),
          data: (sites) {
            if (sites.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 140),
                  Icon(Icons.language,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('还没有网站',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey)),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('点右下角「新建网站」部署第一个站点',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey)),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: sites.length,
              itemBuilder: (context, i) => _SiteCard(
                site: sites[i],
                onToggle: (enabled) =>
                    _siteAction(context, enabled ? 'enable' : 'disable', sites[i]),
                onDelete: () => _delete(context, sites[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _siteAction(
      BuildContext context, String action, Website site) async {
    // 守卫在途（连点）时返回 false，不发重复请求
    final ok = await ref
        .read(webActionsProvider)
        .websiteAction(action, widget.serverId, site);
    if (!ok) return;
    AppToast.show(action == 'enable' ? '已启用 ${site.domain}' : '已停用 ${site.domain}');
  }

  Future<void> _delete(BuildContext context, Website site) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除网站'),
        content: Text('确定删除 ${site.domain} 吗？配置将被移除，网站文件不会删除。'),
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
    final okDone = await ref
        .read(webActionsProvider)
        .websiteAction('delete', widget.serverId, site);
    if (okDone) AppToast.show('网站已删除');
  }
}

/// 单个网站卡：域名/类型/端口/SSL/状态 + 启停 + 删除
class _SiteCard extends StatelessWidget {
  final Website site;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _SiteCard({
    required this.site,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = site.status == 'active';
    final statusColor = active ? Colors.green.shade600 : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(site.sslEnabled ? Icons.lock : Icons.language,
                    size: 20,
                    color: site.sslEnabled
                        ? Colors.green.shade600
                        : Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(site.domain,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis),
                ),
                Text(active ? '运行中' : '已停用',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: statusColor)),
                const SizedBox(width: 4),
                Switch(value: active, onChanged: onToggle),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      _typeLabel(site.projectType),
                      if (site.port > 0) ':${site.port}',
                      if (_isAppType(site.projectType) && site.appPort > 0)
                        '→ 应用 ${site.appPort}',
                      if (site.proxyPass.isNotEmpty) '→ ${site.proxyPass}',
                    ].join(' '),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.shade300,
                  tooltip: '删除',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isAppType(String t) =>
      const ['nodejs', 'php', 'python', 'java'].contains(t);

  String _typeLabel(String t) =>
      const {
        'static': '静态',
        'nodejs': 'Node.js',
        'php': 'PHP',
        'python': 'Python',
        'java': 'Java',
        'proxy': '反代',
      }[t] ??
      t;
}
