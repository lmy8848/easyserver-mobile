import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  Timer? _pingTimer;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void connect(String url, String token) {
    disconnect();

    try {
      final wsUrl = Uri.parse(url);
      _channel = WebSocketChannel.connect(wsUrl, protocols: ['token', token]);
      _isConnected = true;

      _subscription = _channel!.stream.listen(
        (data) {
          if (data is! String || data.isEmpty) return;
          // JSON 消息原样下发；非 JSON 文本（如终端 PTY 的原始输出帧）包装为
          // {type:'output'} —— 后端终端输出是裸文本帧，不是 JSON 包装。
          try {
            final decoded = jsonDecode(data);
            if (decoded is Map<String, dynamic>) {
              _controller.add(decoded);
              return;
            }
          } catch (_) {}
          _controller.add({'type': 'output', 'data': data});
        },
        onError: (error) {
          _isConnected = false;
          _controller.addError(error);
        },
        onDone: () {
          _isConnected = false;
          _pingTimer?.cancel();
        },
      );
      // 保活交给 WebSocket 协议层 ping/pong（后端周期性发协议 ping）；
      // 不再发 JSON ping —— 后端 HandleInput 会拒绝未知 type。
    } catch (e) {
      _isConnected = false;
      _controller.addError(e);
    }
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
