import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/response_models.dart';
import '../services/socket_service.dart';

/// Base URL for the backend REST API.
const String _apiBase = 'http://localhost:8000';

class GestureProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();
  
  // State
  GestureResponse _currentResponse = GestureResponse.empty();
  bool _isSystemActive = true;
  bool _isTrainingComplete = false;
  bool _mouseEnabled = false;
  List<String> _logs = [];
  List<GestureConfig> _gestures = [];

  // Action feedback tracking
  String? _lastTriggeredAction;
  int _actionVersion = 0;

  // Getters
  GestureResponse get currentResponse => _currentResponse;
  bool get isSystemActive => _isSystemActive;
  bool get isConnected => _socketService.isConnected;
  bool get isTrainingComplete => _isTrainingComplete;
  bool get mouseEnabled => _mouseEnabled;
  List<String> get logs => _logs;
  List<GestureConfig> get gestures => _gestures;
  String? get lastTriggeredAction => _lastTriggeredAction;
  int get actionVersion => _actionVersion;

  GestureProvider() {
    connectToBackend();
  }

  void connectToBackend() async {
    // Default FastAPI port
    await _socketService.connect('ws://localhost:8000/ws');
    notifyListeners(); // Update UI with connection status change

    // Fetch gesture configs from backend
    await fetchGestures();
    
    _socketService.stream.listen((data) {
      if (data is String) {
        try {
          final jsonMap = jsonDecode(data);
          
          // Check for disconnection signal
          if (jsonMap['status'] == 'disconnected') {
             _currentResponse = GestureResponse.empty();
             notifyListeners();
             return;
          }

          // Check for training_complete acknowledgment
          if (jsonMap['status'] == 'training_complete') {
            _isTrainingComplete = true;
            _addLog('Model retrained successfully');
            notifyListeners();
            return;
          }

          // Check for model_saved acknowledgment
          if (jsonMap['status'] == 'model_saved') {
            _addLog('Model saved to disk');
            notifyListeners();
            return;
          }

          final response = GestureResponse.fromJson(jsonMap);
          _currentResponse = response;

          // Track action events (increment counter so UI detects every trigger)
          if (response.action != null) {
            _lastTriggeredAction = response.action;
            _actionVersion++;
          }
          
          // Log significant events
          if (response.gesture != 'None' && response.gesture != 'Unknown' && response.confidence > 0.7) {
            _addLog('Detected: ${response.gesture} (${(response.confidence * 100).toStringAsFixed(1)}%)');
          }
          
          notifyListeners();
        } catch (e) {
          debugPrint('Error parsing WebSocket data: $e');
        }
      }
    }, onError: (error) {
      debugPrint('WebSocket stream error: $error');
      _currentResponse = GestureResponse.empty();
      notifyListeners();
    });
  }

  // ── REST API methods ─────────────────────────────────────────────────

  /// Fetch all gesture configs from the backend.
  Future<void> fetchGestures() async {
    try {
      final response = await http.get(Uri.parse('$_apiBase/api/gestures'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['gestures'] as List)
            .map((e) => GestureConfig.fromJson(e as Map<String, dynamic>))
            .toList();
        _gestures = list;
        _addLog('Loaded ${list.length} gestures from backend');
        notifyListeners();
      } else {
        debugPrint('[GestureProvider] Failed to fetch gestures: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[GestureProvider] Error fetching gestures: $e');
      // Fall back to empty list — configs live on the backend
    }
  }

  /// Add or update a gesture config on the backend.
  Future<bool> addGesture(GestureConfig gesture) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/api/gestures'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': gesture.name,
          'action_type': gesture.actionType,
          'action': gesture.action,
          'keys': gesture.keys,
        }),
      );
      if (response.statusCode == 200) {
        _addLog('Gesture saved: ${gesture.name} → ${gesture.displayAction}');
        await fetchGestures(); // refresh list from backend
        return true;
      }
    } catch (e) {
      debugPrint('[GestureProvider] Error saving gesture: $e');
    }
    return false;
  }

  /// Remove a gesture config from the backend.
  Future<bool> removeGesture(String name) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiBase/api/gestures/${Uri.encodeComponent(name)}'),
      );
      if (response.statusCode == 200) {
        _addLog('Gesture removed: $name');
        await fetchGestures(); // refresh list from backend
        return true;
      }
    } catch (e) {
      debugPrint('[GestureProvider] Error removing gesture: $e');
    }
    return false;
  }

  // ── Other methods ────────────────────────────────────────────────────

  void toggleSystem() {
    _isSystemActive = !_isSystemActive;
    notifyListeners();
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    _logs.insert(0, '[$timestamp] $message');
    if (_logs.length > 50) _logs.removeLast();
  }

  void startTraining(String label, {int targetFrames = 200}) {
    _isTrainingComplete = false;
    _socketService.send({
      'command': 'start_training',
      'label': label,
      'target_frames': targetFrames,
    });
    _addLog('Training started for: $label ($targetFrames frames)');
    notifyListeners();
  }

  void stopTraining() {
    _socketService.stopRecording();
  }

  void saveModel() {
    _socketService.saveModel();
  }

  void updateMapping(String gesture, String action, {String actionType = 'preset', String keys = ''}) {
    _socketService.send({
      'command': 'update_mapping',
      'gesture': gesture,
      'action': action,
      'action_type': actionType,
      'keys': keys,
    });
    _addLog('Mapping updated: $gesture → $action');
  }

  void toggleMouse() {
    _mouseEnabled = !_mouseEnabled;
    _socketService.send({
      'command': 'toggle_mouse',
      'value': _mouseEnabled,
    });
    _addLog('Mouse control ${_mouseEnabled ? "enabled" : "disabled"}');
    notifyListeners();
  }

  void resetTrainingState() {
    _isTrainingComplete = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}
