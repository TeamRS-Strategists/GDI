import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';

/// Full-screen overlay that appears when "Jarvis" wake word is detected
/// Provides visual and haptic feedback to the user
class JarvisTriggerOverlay extends StatefulWidget {
  final VoidCallback? onDismiss;
  
  const JarvisTriggerOverlay({
    Key? key,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<JarvisTriggerOverlay> createState() => _JarvisTriggerOverlayState();
}

class _JarvisTriggerOverlayState extends State<JarvisTriggerOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  Timer? _autoCloseTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Fade in/out animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    // Pulse animation for the microphone icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Wave animation for sound waves
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeOut,
    );
    
    // Start fade in
    _fadeController.forward();
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Auto-close after 5 seconds (while listening)
    _autoCloseTimer = Timer(const Duration(seconds: 5), () {
      _dismiss();
    });
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }
  
  void _dismiss() async {
    _autoCloseTimer?.cancel();
    await _fadeController.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.blue.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated sound waves
                    AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer wave
                            _buildWave(
                              size: 200 + (_waveAnimation.value * 100),
                              opacity: 0.3 - (_waveAnimation.value * 0.3),
                            ),
                            // Middle wave
                            _buildWave(
                              size: 150 + (_waveAnimation.value * 80),
                              opacity: 0.4 - (_waveAnimation.value * 0.4),
                            ),
                            // Inner wave
                            _buildWave(
                              size: 100 + (_waveAnimation.value * 60),
                              opacity: 0.5 - (_waveAnimation.value * 0.5),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    // Pulsing microphone icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.blue,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic,
                          size: 60,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // "Jarvis Activated" text
                    Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.blue,
                              Colors.cyan,
                              Colors.blue,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'JARVIS',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Wake word detected',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Status text with animation
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: 0.5 + (_pulseAnimation.value - 1.0) * 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Listening... Speak your command',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Suggested commands
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Try saying:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...[
                            'Create a website for me',
                            'What time is it?',
                            'Open calculator',
                          ].map((cmd) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '• $cmd',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Close button
              Positioned(
                top: 40,
                right: 40,
                child: IconButton(
                  onPressed: _dismiss,
                  icon: const Icon(Icons.close, color: Colors.white),
                  iconSize: 30,
                  tooltip: 'Close (or wait 5s)',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWave({required double size, required double opacity}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.blue.withOpacity(opacity),
          width: 2,
        ),
      ),
    );
  }
}

/// Compact notification that appears when processing a command
class VoiceProcessingNotification extends StatelessWidget {
  final String command;
  final VoidCallback? onDismiss;
  
  const VoiceProcessingNotification({
    Key? key,
    required this.command,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Processing Command',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      command,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white54,
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Success notification for completed commands
class VoiceSuccessNotification extends StatefulWidget {
  final String command;
  final String response;
  final VoidCallback? onDismiss;
  
  const VoiceSuccessNotification({
    Key? key,
    required this.command,
    required this.response,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<VoiceSuccessNotification> createState() => _VoiceSuccessNotificationState();
}

class _VoiceSuccessNotificationState extends State<VoiceSuccessNotification> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Command Completed',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.command,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.response,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.white54,
                onPressed: widget.onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
