import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:http/http.dart' as http;

class SocketService {
  static final SocketService instance = SocketService._internal();
  factory SocketService() => instance;
  SocketService._internal();

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

  // ── Voice Assistant API Methods ─────────────────────────────────────────

  String get _baseUrl {
    // Extract base URL from WebSocket URL
    if (_url == null) return 'http://localhost:8000';
    final uri = Uri.parse(_url!);
    return 'http://${uri.host}:${uri.port}';
  }

  /// Get voice assistant status
  Future<Map<String, dynamic>> getVoiceStatus() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/voice/status'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get voice status: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error getting voice status: $e');
      rethrow;
    }
  }

  /// Start voice assistant
  Future<Map<String, dynamic>> startVoiceAssistant() async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/api/voice/start'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to start voice assistant: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error starting voice assistant: $e');
      rethrow;
    }
  }

  /// Stop voice assistant
  Future<Map<String, dynamic>> stopVoiceAssistant() async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/api/voice/stop'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to stop voice assistant: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error stopping voice assistant: $e');
      rethrow;
    }
  }

  /// Get pending voice commands
  Future<List<Map<String, dynamic>>> getVoiceCommands() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/voice/commands'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['commands'] ?? []);
      }
      throw Exception('Failed to get voice commands: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error getting voice commands: $e');
      rethrow;
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    disconnect();
    _streamController.close();
  }
}
