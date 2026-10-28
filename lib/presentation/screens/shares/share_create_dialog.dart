import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_toast.dart';
import '../../../di/providers.dart';
import '../../../domain/entities/file_share.dart';
import '../../providers/share_provider.dart';

/// 生成文件外链对话框：有效期/下载次数/密码，成功后展示链接并支持复制。
Future<void> showCreateShareDialog(BuildContext context, WidgetRef ref,
    {required String filePath, required String fileName}) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CreateShareSheet(filePath: filePath, fileName: fileName),
  );
  if (created == true && context.mounted) {
    await _showShareLinkDialog(context, ref, fileName);
  }
}

/// 创建成功后展示完整外链，一键复制
Future<void> _showShareLinkDialog(
    BuildContext context, WidgetRef ref, String fileName) async {
  // 创建后列表已刷新，取最新一条同名外链拼链接
  final shares =
      await ref.read(shareListProvider.future).catchError((_) => <FileShare>[]);
  final latest = shares
      .where((s) => s.fileName == fileName)
      .fold<FileShare?>(null, (a, b) => a == null || b.id > a.id ? b : a);
  if (latest == null || !context.mounted) return;

  final cfg = ref.watch(serverConfigProvider);
  final url =
      ref.read(shareRepositoryProvider).downloadUrl(cfg?.baseUrl ?? '', latest.token);

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('外链已生成'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fileName, style: Theme.of(ctx).textTheme.bodyMedium),
          const SizedBox(height: 8),
          if (latest.hasPassword)
            Text('已设置提取密码，需把密码一并告知对方',
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.orange)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(url, style: Theme.of(ctx).textTheme.bodySmall),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            AppToast.show('链接已复制');
          },
          child: const Text('复制链接'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('完成'),
        ),
      ],
    ),
  );
}

class _CreateShareSheet extends ConsumerStatefulWidget {
  final String filePath;
  final String fileName;

  const _CreateShareSheet({required this.filePath, required this.fileName});

  @override
  ConsumerState<_CreateShareSheet> createState() => _CreateShareSheetState();
}

class _CreateShareSheetState extends ConsumerState<_CreateShareSheet> {
  static const _expiryOptions = <String, String>{
    '1h': '1 小时',
    '24h': '24 小时',
    '7d': '7 天',
    '': '永久有效',
  };
  String _expiry = '24h';
  final _password = TextEditingController();
  final _maxDownloads = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _password.dispose();
    _maxDownloads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('生成外链 · ${widget.fileName}',
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          Text('有效期',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: _expiryOptions.entries
                .map((e) => ChoiceChip(
                      label: Text(e.value),
                      selected: _expiry == e.key,
                      onSelected: (_) => setState(() => _expiry = e.key),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxDownloads,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '下载次数上限（可选）',
              hintText: '留空不限次数',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '提取密码（可选）',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _creating ? null : _create,
              icon: _creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.link),
              label: const Text('生成外链'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      final max = int.tryParse(_maxDownloads.text.trim()) ?? 0;
      await ref.read(shareActionsProvider).create(CreateShareInput(
            filePath: widget.filePath,
            password: _password.text.trim(),
            expiresAt: _expiry,
            maxDownloads: max,
          ));
      if (mounted) {
        AppToast.show('外链已生成');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) AppToast.show('生成失败: $e', error: true);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }
}
