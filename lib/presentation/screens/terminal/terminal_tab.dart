import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/terminal_provider.dart';

class TerminalTab extends ConsumerStatefulWidget {
  const TerminalTab({super.key});
  @override
  ConsumerState<TerminalTab> createState() => _TerminalTabState();
}

class _TerminalTabState extends ConsumerState<TerminalTab> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _executeCommand() {
    final cmd = _inputController.text.trim();
    if (cmd.isEmpty) return;
    ref.read(terminalProvider.notifier).sendCommand(cmd);
    _inputController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final terminal = ref.watch(terminalProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: terminal.connected ? Colors.green : Colors.orange, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(terminal.connected ? '已连接' : '未连接', style: theme.textTheme.bodySmall),
              const Spacer(),
              IconButton(
                icon: Icon(terminal.connected ? Icons.link_off : Icons.link, size: 18),
                onPressed: () {
                  if (terminal.connected) {
                    ref.read(terminalProvider.notifier).disconnect();
                  } else {
                    ref.read(terminalProvider.notifier).connect();
                  }
                },
                visualDensity: VisualDensity.compact,
                tooltip: terminal.connected ? '断开' : '连接',
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep, size: 18),
                onPressed: () => ref.read(terminalProvider.notifier).clear(),
                visualDensity: VisualDensity.compact,
                tooltip: '清屏',
              ),
            ],
          ),
        ),
        if (terminal.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.red.shade900,
            child: Text(terminal.error!, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        Expanded(
          child: Container(
            color: Colors.black,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: terminal.lines.length,
              itemBuilder: (context, index) {
                final line = terminal.lines[index];
                final isPrompt = line.startsWith('\$ ');
                return Text(
                  line,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: isPrompt ? Colors.greenAccent : Colors.grey.shade300,
                    height: 1.5,
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          color: Colors.grey.shade900,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              const Text('\$ ', style: TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 14)),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  enabled: terminal.connected,
                  onSubmitted: (_) => _executeCommand(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, size: 18, color: Colors.greenAccent),
                onPressed: terminal.connected ? _executeCommand : null,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
