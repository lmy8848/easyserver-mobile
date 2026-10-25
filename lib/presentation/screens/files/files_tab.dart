import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../widgets/loading_overlay.dart';

class FilesTab extends ConsumerStatefulWidget {
  const FilesTab({super.key});
  @override
  ConsumerState<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends ConsumerState<FilesTab> {
  String _currentPath = '/';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileListProvider(_currentPath).notifier).load(_currentPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(fileListProvider(_currentPath));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.home, size: 20),
                  onPressed: () => _navigateTo('/')),
              if (_currentPath != '/') ...[
                IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    onPressed: () {
                      final parent = _getParentPath(_currentPath);
                      if (parent != null) _navigateTo(parent);
                    }),
              ],
              IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => _navigateTo(_currentPath)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(state.currentPath,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        Expanded(
          child: LoadingOverlay(
            isLoading: state.isLoading,
            child: state.error != null
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('加载失败', style: theme.textTheme.titleMedium),
                      Text(state.error!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                          onPressed: () => _navigateTo(_currentPath),
                          child: const Text('重试')),
                    ],
                  ))
                : state.result == null
                    ? const Center(child: Text('请选择一个目录'))
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _navigateTo(_currentPath);
                        },
                        child: ListView.builder(
                          itemCount: state.result!.entries.length,
                          itemBuilder: (context, index) {
                            final entry = state.result!.entries[index];
                            return ListTile(
                              leading: Icon(
                                entry.isDir
                                    ? Icons.folder
                                    : _getFileIcon(entry.name),
                                color: entry.isDir
                                    ? Colors.amber
                                    : Colors.blueGrey,
                                size: 28,
                              ),
                              title: Text(entry.name,
                                  style: theme.textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: entry.isDir
                                  ? null
                                  : Text(_formatSize(entry.sizeBytes),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.grey)),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('确认删除'),
                                        content:
                                            Text('确定删除 "${entry.name}" 吗？'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('取消')),
                                          FilledButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                ref
                                                    .read(fileListProvider(
                                                            _currentPath)
                                                        .notifier)
                                                    .delete(entry.path,
                                                        recursive: entry.isDir);
                                              },
                                              child: const Text('删除',
                                                  style: TextStyle(
                                                      color: Colors.red))),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                      value: 'rename',
                                      child: ListTile(
                                          leading: Icon(Icons.edit),
                                          title: Text('重命名'))),
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                          leading: Icon(Icons.delete,
                                              color: Colors.red),
                                          title: Text('删除',
                                              style: TextStyle(
                                                  color: Colors.red)))),
                                ],
                              ),
                              onTap: entry.isDir
                                  ? () => _navigateTo(entry.path)
                                  : null,
                            );
                          },
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateTo(String path) async {
    setState(() => _currentPath = path);
    await ref.read(fileListProvider(path).notifier).load(path);
  }

  String? _getParentPath(String path) {
    if (path == '/') return null;
    final trimmed =
        path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final lastSlash = trimmed.lastIndexOf('/');
    return lastSlash <= 0 ? '/' : trimmed.substring(0, lastSlash);
  }

  IconData _getFileIcon(String name) {
    if (name.endsWith('.dart') ||
        name.endsWith('.go') ||
        name.endsWith('.js') ||
        name.endsWith('.ts')) return Icons.code;
    if (name.endsWith('.yaml') ||
        name.endsWith('.json') ||
        name.endsWith('.xml')) return Icons.description;
    if (name.endsWith('.jpg') ||
        name.endsWith('.png') ||
        name.endsWith('.gif') ||
        name.endsWith('.svg')) return Icons.image;
    if (name.endsWith('.zip') || name.endsWith('.tar') || name.endsWith('.gz'))
      return Icons.archive;
    if (name.endsWith('.md')) return Icons.article;
    return Icons.insert_drive_file;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
