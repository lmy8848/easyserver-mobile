import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_toast.dart';
import '../../../di/providers.dart';
import '../../../domain/entities/file_share.dart';
import '../../providers/share_provider.dart';

/// 文件外链管理：查看自己生成的外链、复制链接、删除、清理过期
class SharesScreen extends ConsumerWidget {
  const SharesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sharesAsync = ref.watch(shareListProvider);
    final cfg = ref.watch(serverConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('文件外链'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: '清理过期外链',
            onPressed: () => _cleanup(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.read(shareActionsProvider).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(shareListProvider.future),
        child: sharesAsync.when(
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
                  onPressed: () => ref.invalidate(shareListProvider),
                  child: const Text('重试'),
                ),
              ),
            ],
          ),
          data: (shares) {
            if (shares.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 140),
                  Icon(Icons.share_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('还没有外链',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey)),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('在「文件管理」中点文件右侧菜单生成外链',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey)),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: shares.length,
              itemBuilder: (context, i) => _ShareCard(
                share: shares[i],
                baseUrl: cfg?.baseUrl ?? '',
                onCopy: () =>
                    _copyLink(context, ref, cfg?.baseUrl ?? '', shares[i]),
                onDelete: () => _delete(context, ref, shares[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  void _copyLink(
      BuildContext context, WidgetRef ref, String baseUrl, FileShare share) {
    if (baseUrl.isEmpty) {
      AppToast.show('服务器地址未配置', error: true);
      return;
    }
    final url = ref
        .read(shareRepositoryProvider)
        .downloadUrl(baseUrl, share.token);
    Clipboard.setData(ClipboardData(text: url));
    AppToast.show(share.hasPassword ? '链接已复制（含密码需另行告知）' : '链接已复制');
  }

  Future<void> _cleanup(BuildContext context, WidgetRef ref) async {
    // 守卫在途（连点）时返回 null，不发重复请求
    final n = await ref.read(shareActionsProvider).cleanup();
    if (n == null) return;
    AppToast.show(n > 0 ? '已清理 $n 条过期外链' : '没有过期外链');
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, FileShare share) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除外链'),
        content: Text('删除后 "${share.fileName}" 的外链立即失效，确定删除吗？'),
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
    try {
      await ref.read(shareActionsProvider).delete(share);
      AppToast.show('外链已删除');
    } catch (e) {
      AppToast.show('删除失败: $e', error: true);
    }
  }
}

class _ShareCard extends StatelessWidget {
  final FileShare share;
  final String baseUrl;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _ShareCard({
    required this.share,
    required this.baseUrl,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dead = !share.fileExists;
    final subtitleParts = <String>[
      if (share.isDir) '目录' else _size(share.currentSize),
      '已下载 ${share.downloadCount}${share.maxDownloads > 0 ? '/${share.maxDownloads}' : ' 次'}',
      share.expiresAt.isEmpty ? '永久有效' : '至 ${share.expiresAt}',
      if (share.hasPassword) '有密码',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          share.isDir ? Icons.folder_shared : Icons.link,
          color: dead ? Colors.grey : Colors.blue,
        ),
        title: Text(share.fileName,
            style: dead
                ? theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey, decoration: TextDecoration.lineThrough)
                : theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            ...subtitleParts,
            if (dead) '文件已不存在',
          ].join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
              color: dead ? Colors.grey : theme.textTheme.bodySmall?.color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'copy') onCopy();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'copy',
                child: ListTile(
                    leading: Icon(Icons.copy), title: Text('复制链接'))),
            const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('删除', style: TextStyle(color: Colors.red)))),
          ],
        ),
      ),
    );
  }

  String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
