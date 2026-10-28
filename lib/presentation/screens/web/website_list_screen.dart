import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/action_guard.dart';
import '../../../core/app_toast.dart';
import '../../../di/providers.dart';
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
  WebConfigTest? _configTest;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runConfigTest());
  }

  /// 真实配置检测（后端执行 nginx -t 等命令）；守卫去重，连点只测一次
  Future<void> _runConfigTest() async {
    if (!mounted) return;
    setState(() => _testing = true);
    final result = await globalActionGuard.run('web:test-config:${widget.serverId}',
        () => ref.read(webRepositoryProvider).testConfig(widget.serverId));
    if (!mounted) return;
    setState(() {
      _testing = false;
      if (result != null) _configTest = result;
    });
  }

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          children: [
            _ConfigTestBanner(
              result: _configTest,
              testing: _testing,
              onRetest: _runConfigTest,
            ),
            sitesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Card(
            child: ListTile(
              leading: Icon(Icons.error_outline, color: Colors.red.shade300),
              title: const Text('网站列表加载失败'),
              subtitle: Text('$e', maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: TextButton(
                onPressed: () =>
                    ref.invalidate(websitesProvider(widget.serverId)),
                child: const Text('重试'),
              ),
            ),
          ),
          data: (sites) {
            if (sites.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.language,
                        size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('还没有网站',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('点右下角「新建网站」部署第一个站点',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey)),
                  ],
                ),
              );
            }
            return Column(
              children: [
                for (final site in sites)
                  _SiteCard(
                    site: site,
                    onToggle: (enabled) => _siteAction(
                        context, enabled ? 'enable' : 'disable', site),
                    onDelete: () => _delete(context, site),
                  ),
              ],
            );
          },
        ),
          ],
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

/// 配置检测结果横幅：进入页面自动检测，支持手动重测
class _ConfigTestBanner extends StatelessWidget {
  final WebConfigTest? result;
  final bool testing;
  final VoidCallback onRetest;

  const _ConfigTestBanner({
    required this.result,
    required this.testing,
    required this.onRetest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (testing) {
      return const Card(
        child: ListTile(
          leading: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('正在检测配置…'),
        ),
      );
    }
    if (result == null) return const SizedBox.shrink();

    final valid = result!.valid;
    final color = valid ? Colors.green.shade600 : Colors.red.shade400;
    return Card(
      child: ListTile(
        leading: Icon(valid ? Icons.verified_outlined : Icons.warning_amber,
            color: color),
        title: Text(valid ? '配置检测通过' : '配置检测未通过',
            style: theme.textTheme.titleSmall?.copyWith(color: color)),
        subtitle: result!.message.isEmpty
            ? null
            : Text(result!.message,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: '重新检测',
          onPressed: onRetest,
        ),
      ),
    );
  }
}
