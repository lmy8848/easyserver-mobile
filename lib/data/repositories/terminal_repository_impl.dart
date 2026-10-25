import 'dart:async';
import '../../domain/repositories/terminal_repository.dart';
import '../datasources/remote/ws_client.dart';

class TerminalRepositoryImpl implements TerminalRepository {
  final WsClient _wsClient;
  final Map<String, StreamController<TerminalMessage>> _controllers = {};

  TerminalRepositoryImpl(this._wsClient);

  @override
  StreamController<TerminalMessage> connect(String sessionId, String token) {
    final controller = StreamController<TerminalMessage>.broadcast();
    _controllers[sessionId] = controller;

    _wsClient.stream.listen((msg) {
      if (msg['type'] == 'output') {
        controller.add(TerminalMessage(type: 'output', data: msg['data'] as String?));
      } else if (msg['type'] == 'exit') {
        controller.add(TerminalMessage(type: 'exit'));
      }
    });

    return controller;
  }

  @override
  void sendInput(String sessionId, String data) {
    _wsClient.send({'type': 'input', 'data': data});
  }

  @override
  void resize(String sessionId, int cols, int rows) {
    _wsClient.send({'type': 'resize', 'cols': cols, 'rows': rows});
  }

  @override
  void disconnect(String sessionId) {
    _controllers[sessionId]?.close();
    _controllers.remove(sessionId);
    _wsClient.disconnect();
  }
}
