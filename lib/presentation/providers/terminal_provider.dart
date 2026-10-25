import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../di/providers.dart';

final terminalProvider = StateNotifierProvider<TerminalNotifier, TerminalState>((ref) {
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

  TerminalState copyWith({bool? connected, bool? loading, List<String>? lines, String? error}) {
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
  String? _sessionId;

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

      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final wsUrl = '${config.wsUrl}/ws/terminal/$_sessionId';
      final wsClient = _ref.read(wsClientProvider);

      wsClient.connect(wsUrl, token);

      _subscription = wsClient.stream.listen(
        (msg) {
          final type = msg['type'] as String?;
          if (type == 'output') {
            final data = msg['data'] as String? ?? '';
            state = state.copyWith(lines: [...state.lines, data]);
          } else if (type == 'exit') {
            state = state.copyWith(connected: false, lines: [...state.lines, '', '--- 会话已结束 ---']);
          }
        },
        onError: (e) {
          state = state.copyWith(loading: false, error: '连接错误: $e');
        },
      );

      state = state.copyWith(connected: true, loading: false, lines: ['终端已连接', '']);
    } catch (e) {
      state = state.copyWith(loading: false, error: '连接失败: $e');
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _ref.read(wsClientProvider).disconnect();
    state = state.copyWith(connected: false, lines: [...state.lines, '', '已断开连接']);
  }

  void sendCommand(String cmd) {
    if (!state.connected) return;
    state = state.copyWith(lines: [...state.lines, '\$ $cmd']);
    _ref.read(wsClientProvider).send({'type': 'input', 'data': '$cmd\r'});
  }

  void clear() {
    state = state.copyWith(lines: []);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
