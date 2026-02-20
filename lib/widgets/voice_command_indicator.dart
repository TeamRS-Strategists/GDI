import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../services/socket_service.dart';
import 'jarvis_trigger_overlay.dart';

/// Voice command indicator widget that shows the current state of voice assistant
class VoiceCommandIndicator extends StatefulWidget {
  const VoiceCommandIndicator({Key? key}) : super(key: key);

  @override
  State<VoiceCommandIndicator> createState() => _VoiceCommandIndicatorState();
}

class _VoiceCommandIndicatorState extends State<VoiceCommandIndicator>
    with SingleTickerProviderStateMixin {
  bool _isEnabled = false;
  String _state = 'disabled';
  bool _openclawConnected = false;
  String? _wakeWord;
  String? _currentCommand;
  String? _lastResponse;
  Timer? _statusTimer;
  StreamSubscription? _socketSubscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Overlay state
  OverlayEntry? _jarvisOverlay;
  OverlayEntry? _processingNotification;
  OverlayEntry? _successNotification;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for listening state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fetchVoiceStatus();
    _startStatusPolling();
    _listenForVoiceEvents();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _pulseController.dispose();
    _removeOverlays();
    super.dispose();
  }
  
  void _listenForVoiceEvents() {
    // Listen to WebSocket for voice events
    _socketSubscription = SocketService.instance.stream.listen((message) {
      try {
        final data = jsonDecode(message);
        
        // Check for voice wake detection
        if (data['type'] == 'voice_wake_detected' || 
            data['event'] == 'wake_word_detected') {
          _showJarvisOverlay();
        }
        
        // Check for command transcription
        else if (data['type'] == 'voice_command' || 
                 data['event'] == 'command_received') {
          final command = data['command'] ?? data['text'];
          if (command != null) {
            setState(() {
              _currentCommand = command;
            });
            _showProcessingNotification(command);
          }
        }
        
        // Check for command completion
        else if (data['type'] == 'voice_response' || 
                 data['event'] == 'command_completed') {
          final response = data['response'] ?? data['message'];
          if (response != null && _currentCommand != null) {
            _showSuccessNotification(_currentCommand!, response);
            setState(() {
              _lastResponse = response;
            });
          }
        }
        
        // Update state from WebSocket
        if (data['voice_state'] != null) {
          setState(() {
            _state = data['voice_state'];
          });
        }
      } catch (e) {
        debugPrint('Error parsing voice event: $e');
      }
    });
  }
  
  void _removeOverlays() {
    _jarvisOverlay?.remove();
    _jarvisOverlay = null;
    _processingNotification?.remove();
    _processingNotification = null;
    _successNotification?.remove();
    _successNotification = null;
  }
  
  void _showJarvisOverlay() {
    if (_jarvisOverlay != null) return;
    
    _jarvisOverlay = OverlayEntry(
      builder: (context) => JarvisTriggerOverlay(
        onDismiss: () {
          _jarvisOverlay?.remove();
          _jarvisOverlay = null;
        },
      ),
    );
    
    Overlay.of(context).insert(_jarvisOverlay!);
  }
  
  void _showProcessingNotification(String command) {
    // Remove any existing notifications
    _processingNotification?.remove();
    _successNotification?.remove();
    
    _processingNotification = OverlayEntry(
      builder: (context) => VoiceProcessingNotification(
        command: command,
        onDismiss: () {
          _processingNotification?.remove();
          _processingNotification = null;
        },
      ),
    );
    
    Overlay.of(context).insert(_processingNotification!);
  }
  
  void _showSuccessNotification(String command, String response) {
    // Remove processing notification
    _processingNotification?.remove();
    _processingNotification = null;
    
    // Remove any existing success notification
    _successNotification?.remove();
    
    _successNotification = OverlayEntry(
      builder: (context) => VoiceSuccessNotification(
        command: command,
        response: response,
        onDismiss: () {
          _successNotification?.remove();
          _successNotification = null;
        },
      ),
    );
    
    _successNotification?.dispose();
    super.dispose();
  }

  void _startStatusPolling() {
    // Poll voice status every 2 seconds
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchVoiceStatus();
    });
  }

  Future<void> _fetchVoiceStatus() async {
    try {
      final status = await SocketService.instance.getVoiceStatus();
      if (mounted) {
        setState(() {
          _isEnabled = status['enabled'] ?? false;
          _state = status['state'] ?? 'disabled';
          _openclawConnected = status['openclaw_connected'] ?? false;
          _wakeWord = status['wake_word'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching voice status: $e');
    }
  }

  Future<void> _toggleVoiceAssistant() async {
    try {
      if (_isEnabled) {
        await SocketService.instance.stopVoiceAssistant();
      } else {
        await SocketService.instance.startVoiceAssistant();
      }
      await _fetchVoiceStatus();
    } catch (e) {
      debugPrint('Error toggling voice assistant: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle voice assistant: $e')),
        );
      }
    }
  }

  Color _getStateColor() {
    switch (_state) {
      case 'idle':
        return Colors.blue;
      case 'listening':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'speaking':
        return Colors.purple;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon() {
    switch (_state) {
      case 'idle':
        return Icons.mic_none;
      case 'listening':
        return Icons.mic;
      case 'processing':
        return Icons.psychology;
      case 'speaking':
        return Icons.volume_up;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.mic_off;
    }
  }

  String _getStateLabel() {
    if (!_isEnabled) return 'Voice Disabled';
    
    switch (_state) {
      case 'idle':
        return 'Say "$_wakeWord"';
      case 'listening':
        return 'Listening...';
      case 'processing':
        return 'Processing...';
      case 'speaking':
        return 'Speaking...';
      case 'error':
        return 'Error';
      default:
        return 'Disabled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = _getStateColor();
    final stateIcon = _getStateIcon();
    final stateLabel = _getStateLabel();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEnabled ? stateColor.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.record_voice_over, color: stateColor),
              const SizedBox(width: 8),
              const Text(
                'Voice Assistant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: _isEnabled,
                onChanged: (_) => _toggleVoiceAssistant(),
                activeColor: Colors.green,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Status Indicator
          if (_isEnabled) ...[
            ScaleTransition(
              scale: _state == 'listening' ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stateColor.withOpacity(0.2),
                  border: Border.all(color: stateColor, width: 3),
                ),
                child: Icon(
                  stateIcon,
                  size: 40,
                  color: stateColor,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              stateLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: stateColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // OpenClaw Connection Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _openclawConnected ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _openclawConnected 
                    ? 'OpenClaw Connected' 
                    : 'Basic Mode',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Disabled state
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.1),
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: Icon(
                Icons.mic_off,
                size: 40,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Voice assistant is disabled',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Info
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isEnabled
                        ? 'Say "${_wakeWord ?? "jarvis"}" followed by your command'
                        : 'Enable voice control to use AI commands',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact voice status badge for app bar
class VoiceStatusBadge extends StatefulWidget {
  const VoiceStatusBadge({Key? key}) : super(key: key);

  @override
  State<VoiceStatusBadge> createState() => _VoiceStatusBadgeState();
}

class _VoiceStatusBadgeState extends State<VoiceStatusBadge> {
  bool _isEnabled = false;
  String _state = 'disabled';
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _fetchVoiceStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchVoiceStatus();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchVoiceStatus() async {
    try {
      final status = await SocketService.instance.getVoiceStatus();
      if (mounted) {
        setState(() {
          _isEnabled = status['enabled'] ?? false;
          _state = status['state'] ?? 'disabled';
        });
      }
    } catch (e) {
      debugPrint('Error fetching voice status: $e');
    }
  }

  Color _getStateColor() {
    if (!_isEnabled) return Colors.grey;
    
    switch (_state) {
      case 'idle':
        return Colors.blue;
      case 'listening':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStateColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStateColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _state == 'listening' ? Icons.mic : Icons.mic_none,
            size: 16,
            color: _getStateColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _state == 'listening' ? 'Listening' : 'Voice',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getStateColor(),
            ),
          ),
        ],
      ),
    );
  }
}
