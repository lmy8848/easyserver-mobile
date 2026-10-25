import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logger/app_logger.dart';

/// 运行日志：全局异常与埋点的环形缓冲视图（最近 500 条）。
/// 支持等级图标区分、清空与复制，便于现场排障。
class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});
  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  late List<LogEntry> _entries;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _entries = AppLogger.instance.entries;
    AppLogger.instance.updates.listen((_) {
      if (mounted) setState(() => _entries = AppLogger.instance.entries);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _levelColor(LogLevel level) => switch (level) {
        LogLevel.debug => Colors.grey,
        LogLevel.info => Colors.blue,
        LogLevel.warn => Colors.orange,
        LogLevel.error => Colors.red,
      };

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  Future<void> _copyAll() async {
    final text = _entries
        .map(
            (e) => '${e.time.toIso8601String()} [${e.levelLabel}] ${e.message}')
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('已复制全部日志'), duration: Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('运行日志（${_entries.length}）'),
        actions: [
          IconButton(
              icon: const Icon(Icons.copy),
              tooltip: '复制全部',
              onPressed: _copyAll),
          IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: '清空',
              onPressed: () => setState(AppLogger.instance.clear)),
        ],
      ),
      body: _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('暂无日志', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text('全局异常与运行事件会记录在此',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _entries.length,
              itemBuilder: (context, i) {
                final e = _entries[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fmt(e.time),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontFeatures: [
                                const FontFeature.tabularFigures()
                              ])),
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                            color: _levelColor(e.level),
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.message,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: e.level == LogLevel.error
                                  ? Colors.red.shade700
                                  : null,
                            )),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
