import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../di/providers.dart';

final terminalProvider =
    StateNotifierProvider<TerminalNotifier, TerminalState>((ref) {
  return TerminalNotifier(ref);
});

class TerminalState {
  final bool connected;
  final bool loading;
  final List<String> lines;
  final String? error;

  const TerminalState({
    this.connected = false,
    this.loading = false,
    this.lines = const ['Web 终端', '---', '点击"连接"按钮开始'],
    this.error,
  });

  TerminalState copyWith(
      {bool? connected, bool? loading, List<String>? lines, String? error}) {
    return TerminalState(
      connected: connected ?? this.connected,
      loading: loading ?? this.loading,
      lines: lines ?? this.lines,
      error: error,
    );
  }
}

class TerminalNotifier extends StateNotifier<TerminalState> {
  final Ref _ref;
  StreamSubscription? _subscription;

  TerminalNotifier(this._ref) : super(const TerminalState());

  Future<void> connect() async {
    final config = _ref.read(serverConfigProvider);
    if (config == null) {
      state = state.copyWith(error: '请先配置服务器');
      return;
    }
    state = state.copyWith(loading: true, error: null);

    try {
      final token = await _ref.read(secureStorageProvider).getToken();
      if (token == null) {
        state = state.copyWith(loading: false, error: '未登录，请先登录');
        return;
      }

      // 后端路由为 /ws/terminal（无路径参数），会话由服务端连接时自动创建
      final wsUrl = '${config.wsUrl}/ws/terminal';
      final wsClient = _ref.read(wsClientProvider);

      wsClient.connect(wsUrl, token);

      _subscription = wsClient.stream.listen(
        (msg) {
          final type = msg['type'] as String?;
          if (type == 'output') {
            final data = msg['data'] as String? ?? '';
            // PTY 原始输出含 ANSI 转义序列，行式展示前剥离（色彩/光标控制等）
            final clean = _stripAnsi(data);
            if (clean.isEmpty) return;
            final merged = state.lines.toList();
            if (merged.isNotEmpty) {
              merged.last = merged.last + clean;
            } else {
              merged.add(clean);
            }
            // 换行符切分新行
            final parts = merged.last.split('\n');
            if (parts.length > 1) {
              merged.removeLast();
              merged.addAll(parts);
            }
            state = state.copyWith(lines: merged);
          } else if (type == 'exit') {
            state = state.copyWith(
                connected: false, lines: [...state.lines, '', '--- 会话已结束 ---']);
          }
        },
        onError: (e) {
          state = state.copyWith(loading: false, error: '连接错误: $e');
        },
      );

      state =
          state.copyWith(connected: true, loading: false, lines: ['终端已连接', '']);
    } catch (e) {
      state = state.copyWith(loading: false, error: '连接失败: $e');
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _ref.read(wsClientProvider).disconnect();
    state =
        state.copyWith(connected: false, lines: [...state.lines, '', '已断开连接']);
  }

  void sendCommand(String cmd) {
    if (!state.connected) return;
    state = state.copyWith(lines: [...state.lines, '\$ $cmd']);
    _ref.read(wsClientProvider).send({'type': 'input', 'data': '$cmd\r'});
  }

  void clear() {
    state = state.copyWith(lines: []);
  }

  // 剥离 ANSI/VT 转义序列（CSI/OSC 等），行式终端仅展示纯文本
  static final _ansiRe =
      RegExp(r'\[[0-9;?]*[ -/]*[@-~]|\][^]*(|\)|[@-Z\-_]');
  String _stripAnsi(String s) => s.replaceAll(_ansiRe, '');

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
