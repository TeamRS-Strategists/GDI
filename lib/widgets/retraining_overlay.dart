import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';

/// Full-screen training overlay with animated neural network visualization,
/// progressive status text, and success checkmark.
class RetrainingOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const RetrainingOverlay({super.key, required this.onComplete});

  @override
  State<RetrainingOverlay> createState() => _RetrainingOverlayState();
}

class _RetrainingOverlayState extends State<RetrainingOverlay> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _pulse;
  int _statusIndex = 0;
  bool _isDone = false;

  static const _statusMessages = [
    'Preprocessing Data…',
    'Fitting Model…',
    'Optimizing Weights…',
    'Ready',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _progressCtrl.addListener(() {
      final newIndex = (_progressCtrl.value * (_statusMessages.length - 1)).floor().clamp(0, _statusMessages.length - 1);
      if (newIndex != _statusIndex) {
        setState(() => _statusIndex = newIndex);
      }
    });
    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isDone = true);
        Future.delayed(const Duration(milliseconds: 1200), widget.onComplete);
      }
    });
    _progressCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: AppColors.bg.withOpacity(0.88),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Neural network or success checkmark
              SizedBox(
                width: 200,
                height: 200,
                child: _isDone
                    ? TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.neonGreen.withOpacity(0.12),
                                border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(color: AppColors.neonGreen.withOpacity(0.2), blurRadius: 24),
                                ],
                              ),
                              child: const Icon(Icons.check_rounded, color: AppColors.neonGreen, size: 72),
                            ),
                          );
                        },
                      )
                    : AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _NeuralNetworkPainter(
                              pulse: _pulse.value,
                              progress: _progressCtrl.value,
                            ),
                            size: const Size(200, 200),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 36),

              // Title
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _isDone ? 'Training Complete' : 'Retraining Model',
                  key: ValueKey(_isDone),
                  style: TextStyle(
                    color: _isDone ? AppColors.neonGreen : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _statusMessages[_statusIndex],
                  key: ValueKey(_statusIndex),
                  style: TextStyle(
                    color: _isDone ? AppColors.neonGreen.withOpacity(0.7) : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Progress bar
              if (!_isDone)
                SizedBox(
                  width: 240,
                  child: AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _progressCtrl.value,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                          minHeight: 4,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws pulsing nodes and connecting lines.
class _NeuralNetworkPainter extends CustomPainter {
  final double pulse;
  final double progress;
  final Random _rng = Random(42);

  _NeuralNetworkPainter({required this.pulse, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Generate node positions in layers
    final layers = [
      _generateLayer(3, cx - 60, cy, 40),
      _generateLayer(5, cx - 20, cy, 36),
      _generateLayer(4, cx + 20, cy, 38),
      _generateLayer(2, cx + 60, cy, 30),
    ];

    // Draw connections
    final linePaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int l = 0; l < layers.length - 1; l++) {
      for (final from in layers[l]) {
        for (final to in layers[l + 1]) {
          final activeProgress = (progress * layers.length).clamp(0, layers.length);
          final opacity = (activeProgress > l) ? (0.15 + pulse * 0.1) : 0.03;
          linePaint.color = AppColors.cyan.withOpacity(opacity);
          canvas.drawLine(from, to, linePaint);
        }
      }
    }

    // Draw nodes
    for (int l = 0; l < layers.length; l++) {
      for (final pos in layers[l]) {
        final activeProgress = (progress * layers.length).clamp(0, layers.length);
        final isActive = activeProgress > l;
        final radius = 4.0 + (isActive ? pulse * 2 : 0);

        final nodePaint = Paint()
          ..color = isActive ? AppColors.cyan.withOpacity(0.6 + pulse * 0.4) : AppColors.textSecondary.withOpacity(0.2);
        canvas.drawCircle(pos, radius, nodePaint);

        if (isActive) {
          final glowPaint = Paint()
            ..color = AppColors.cyan.withOpacity(pulse * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawCircle(pos, radius + 4, glowPaint);
        }
      }
    }
  }

  List<Offset> _generateLayer(int count, double x, double cy, double spread) {
    final List<Offset> nodes = [];
    final startY = cy - (count - 1) * spread / 2;
    for (int i = 0; i < count; i++) {
      nodes.add(Offset(x, startY + i * spread));
    }
    return nodes;
  }

  @override
  bool shouldRepaint(covariant _NeuralNetworkPainter oldDelegate) => true;
}
