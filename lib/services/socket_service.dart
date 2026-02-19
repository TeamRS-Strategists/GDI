import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class SocketService {
  WebSocketChannel? _channel;
  final _streamController = StreamController<dynamic>.broadcast();
  bool _isConnected = false;
  Timer? _reconnectTimer;
  String? _url;

  Stream<dynamic> get stream => _streamController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String url) async {
    _url = url;
    if (_isConnected) return;

    try {
      debugPrint('[SocketService] Connecting to $url ...');
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Wait for the WebSocket handshake to complete
      await _channel!.ready;
      _isConnected = true;
      debugPrint('[SocketService] Connected!');

      _channel!.stream.listen(
        (message) {
          _streamController.add(message);
        },
        onDone: () {
          debugPrint('[SocketService] Connection closed');
          _isConnected = false;
          _streamController.add('{"status": "disconnected"}');
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint('[SocketService] Stream error: $error');
          _isConnected = false;
          _streamController.addError(error);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('[SocketService] Connection failed: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isConnected && _url != null) {
        debugPrint('[SocketService] Attempting reconnect...');
        connect(_url!);
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _isConnected = false;
      _channel = null;
    }
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      debugPrint('[SocketService] Not connected. Cannot send: $data');
    }
  }

  void startRecording(String label) {
    send({'command': 'start_training', 'label': label});
  }

  void stopRecording() {
    send({'command': 'stop_training'});
  }

  void saveModel() {
    send({'command': 'save_model'});
  }

  void dispose() {
    _reconnectTimer?.cancel();
    disconnect();
    _streamController.close();
  }
}
