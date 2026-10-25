import 'dart:async';

abstract class TerminalRepository {
  StreamController<TerminalMessage> connect(String sessionId, String token);
  void sendInput(String sessionId, String data);
  void resize(String sessionId, int cols, int rows);
  void disconnect(String sessionId);
}

class TerminalMessage {
  final String type;
  final String? data;
  TerminalMessage({required this.type, this.data});
}
