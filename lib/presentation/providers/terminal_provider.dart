import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../di/providers.dart';

final terminalProvider =
    StateNotifierProvider<TerminalNotifier, TerminalState>((ref) {
  return TerminalNotifier(ref);
});

class TerminalState {
  final bool connected;
  final bool loading;
  final String? error;

  const TerminalState(
      {this.connected = false, this.loading = false, this.error});

  TerminalState copyWith({bool? connected, bool? loading, String? error}) {
    return TerminalState(
      connected: connected ?? this.connected,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// Web 终端：xterm.dart 全仿真渲染（top/vim 等全屏程序正常重绘），
/// PTY 原始输出直接喂给模拟器，用户键入经 onOutput 原样回传。
class TerminalNotifier extends StateNotifier<TerminalState> {
  final Ref _ref;
  StreamSubscription? _subscription;

  /// 终端实例与 notifier 同生命周期，重连复用（connect 时清屏复位）
  late final Terminal terminal = Terminal(
    onOutput: _sendRaw,
    onResize: (cols, rows, _, __) => _sendResize(cols, rows),
  );

  TerminalNotifier(this._ref) : super(const TerminalState());

  Future<void> connect() async {
    final config = _ref.read(serverConfigProvider);
    if (config == null) {
      state = state.copyWith(error: '请先配置服务器');
      return;
    }
    state = state.copyWith(loading: true, error: null);

    try {
      // WebSocket 握手不走 HTTP 拦截器，301/401 后无法自动刷新：
      // 连接前先刷新一次 access，确保握手用的是新 token。刷新失败（网络问题）
      // 时继续用现有 token，避免因直连/网络抖动直接判定未登录。
      await _ref.read(authRepositoryProvider).refreshAccess();
      final token = await _ref.read(secureStorageProvider).getToken();
      if (token == null) {
        state = state.copyWith(loading: false, error: '未登录，请先登录');
        return;
      }

      final wsClient = _ref.read(wsClientProvider);
      wsClient.connect('${config.wsUrl}/ws/terminal', token);

      _subscription = wsClient.stream.listen(
        (msg) {
          final type = msg['type'] as String?;
          if (type == 'output') {
            // PTY 原始输出（含 ANSI 序列）直接进模拟器，由 xterm 解析
            // 光标移动/清屏/颜色，top、vim 等全屏程序可正常重绘
            terminal.write(msg['data'] as String? ?? '');
          } else if (type == 'exit') {
            terminal.write('\r\n\x1b[90m--- 会话已结束 ---\x1b[0m\r\n');
            state = state.copyWith(connected: false);
          }
        },
        onError: (e) {
          state = state.copyWith(loading: false, error: '连接错误: $e');
        },
      );

      // 复位本地视图：RIS 全复位 + 清屏 + 光标归位
      terminal.write('\x1bc\x1b[2J\x1b[H');
      state = state.copyWith(connected: true, loading: false, error: null);
      // 握手后同步一次当前视图尺寸，避免 PTY 停留在默认 80x24
      _sendResize(terminal.viewWidth, terminal.viewHeight);
    } catch (e) {
      state = state.copyWith(loading: false, error: '连接失败: $e');
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _ref.read(wsClientProvider).disconnect();
    state = state.copyWith(connected: false);
  }

  void _sendRaw(String data) {
    if (!state.connected) return;
    _ref.read(wsClientProvider).send({'type': 'input', 'data': data});
  }

  void _sendResize(int cols, int rows) {
    if (!state.connected) return;
    _ref
        .read(wsClientProvider)
        .send({'type': 'resize', 'cols': cols, 'rows': rows});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
