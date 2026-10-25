import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<Map<String, dynamic>> _controller = StreamController<Map<String, dynamic>>.broadcast();
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
          try {
            if (data is String) {
              final msg = jsonDecode(data) as Map<String, dynamic>;
              _controller.add(msg);
            }
          } catch (_) {}
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

      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        send({'type': 'ping'});
      });
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
