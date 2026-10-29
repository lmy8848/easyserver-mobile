import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../providers/terminal_provider.dart';

/// Web 终端：xterm 全仿真视图 + 常用控制键工具条（软键盘没有 Ctrl 键）
class TerminalTab extends ConsumerStatefulWidget {
  const TerminalTab({super.key});
  @override
  ConsumerState<TerminalTab> createState() => _TerminalTabState();
}

class _TerminalTabState extends ConsumerState<TerminalTab> {
  /// 控制键/方向键：软键盘没有 Ctrl 键，经 Terminal.keyInput 生成
  /// 正确的转义序列走 onOutput → WS → PTY
  static const _ctrlKeys = <(String, TerminalKey, bool)>[
    ('Ctrl+C', TerminalKey.keyC, true),
    ('Ctrl+D', TerminalKey.keyD, true),
    ('Ctrl+Z', TerminalKey.keyZ, true),
    ('Ctrl+L', TerminalKey.keyL, true),
    ('Esc', TerminalKey.escape, false),
    ('Tab', TerminalKey.tab, false),
    ('↑', TerminalKey.arrowUp, false),
    ('↓', TerminalKey.arrowDown, false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(terminalProvider);
    final notifier = ref.read(terminalProvider.notifier);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: state.connected ? Colors.green : Colors.orange,
                      shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(state.connected ? '已连接' : '未连接',
                  style: theme.textTheme.bodySmall),
              const Spacer(),
              IconButton(
                icon: Icon(state.connected ? Icons.link_off : Icons.link,
                    size: 18),
                onPressed: () {
                  if (state.connected) {
                    notifier.disconnect();
                  } else {
                    notifier.connect();
                  }
                },
                visualDensity: VisualDensity.compact,
                tooltip: state.connected ? '断开' : '连接',
              ),
            ],
          ),
        ),
        if (state.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.red.shade900,
            child: Text(state.error!,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        Expanded(
          child: Container(
            color: Colors.black,
            child: state.connected
                ? TerminalView(
                    notifier.terminal,
                    autofocus: true,
                    autoResize: true,
                    textStyle: const TerminalStyle(fontSize: 13),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.terminal,
                            size: 44, color: Colors.grey.shade600),
                        const SizedBox(height: 12),
                        Text('未连接服务器终端',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed:
                              state.loading ? null : () => notifier.connect(),
                          icon: state.loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.link),
                          label: const Text('连接终端'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (state.connected)
          Container(
            color: Colors.grey.shade900,
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final entry in _ctrlKeys)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ActionChip(
                      label: Text(entry.$1,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white)),
                      backgroundColor: Colors.grey.shade800,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          notifier.terminal.keyInput(entry.$2, ctrl: entry.$3),
                    ),
                  ),              ],
            ),
          ),
      ],
    );
  }
}
