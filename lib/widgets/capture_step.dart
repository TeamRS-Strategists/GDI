import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../main.dart';
import 'hand_skeleton_painter.dart';

class CaptureStep extends StatefulWidget {
  final String gestureName;
  final String action;
  final VoidCallback onCaptureComplete;

  const CaptureStep({
    super.key,
    required this.gestureName,
    required this.action,
    required this.onCaptureComplete,
  });

  @override
  State<CaptureStep> createState() => _CaptureStepState();
}

class _CaptureStepState extends State<CaptureStep> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GestureProvider>(
      builder: (context, provider, child) {
        final isComplete = provider.isTrainingComplete;
        final logs = provider.logs;
        // Simple heuristic to show progress based on logs or specific state if available
        // Since provider doesn't expose precise progress % yet, we'll rely on state
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppColors.cyan,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getInstructionText(isComplete),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Preview / Skeleton
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRecording 
                        ? AppColors.neonRed 
                        : isComplete 
                            ? AppColors.neonGreen 
                            : Colors.white.withOpacity(0.1),
                    width: _isRecording ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Skeleton visualization
                    if (provider.currentResponse.hasHand)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomPaint(
                          painter: HandSkeletonPainter(
                            landmarks: provider.currentResponse.landmarks
                          ),
                          size: Size.infinite,
                        ),
                      ),

                    // Center Status Text
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!provider.currentResponse.hasHand)
                            Column(
                              children: [
                                Icon(Icons.front_hand_rounded, 
                                  size: 48, 
                                  color: Colors.white.withOpacity(0.2)
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Place hand in view',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          
                          if (_isRecording && provider.currentResponse.hasHand)
                             AnimatedBuilder(
                               animation: _pulseCtrl,
                               builder: (context, _) => Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                 decoration: BoxDecoration(
                                   color: AppColors.neonRed.withOpacity(0.2 + (_pulseCtrl.value * 0.2)),
                                   borderRadius: BorderRadius.circular(20),
                                   border: Border.all(color: AppColors.neonRed),
                                 ),
                                 child: const Text(
                                   'RECORDING...',
                                   style: TextStyle(
                                     color: Colors.white,
                                     fontWeight: FontWeight.w700,
                                     letterSpacing: 1.2,
                                   ),
                                 ),
                               ),
                             ),

                          if (isComplete)
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                               decoration: BoxDecoration(
                                 color: AppColors.neonGreen.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(20),
                                 border: Border.all(color: AppColors.neonGreen),
                               ),
                               child: const Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Icon(Icons.check_rounded, color: AppColors.neonGreen, size: 16),
                                   SizedBox(width: 8),
                                   Text(
                                     'CAPTURE COMPLETE',
                                     style: TextStyle(
                                       color: Colors.white,
                                       fontWeight: FontWeight.w700,
                                       letterSpacing: 1.2,
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _getButtonAction(provider, isComplete),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonColor(isComplete),
                  foregroundColor: isComplete ? AppColors.bg : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: _isRecording ? 0 : 4,
                ),
                child: _isRecording
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : Text(
                      _getButtonLabel(isComplete),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getInstructionText(bool isComplete) {
    if (isComplete) return 'Great! Samples collected successfully. Click Next to review and save.';
    if (_isRecording) return 'Move your hand slightly to capture variance. Keep performing "${widget.gestureName}".';
    return 'Get ready to perform "${widget.gestureName}". Press Start when you are ready.';
  }

  String _getButtonLabel(bool isComplete) {
    if (isComplete) return 'Next Step';
    if (_isRecording) return '';
    return 'Start Capture';
  }

  Color _getButtonColor(bool isComplete) {
    if (isComplete) return AppColors.neonGreen;
    if (_isRecording) return Colors.grey.withOpacity(0.2);
    return AppColors.cyan;
  }

  VoidCallback? _getButtonAction(GestureProvider provider, bool isComplete) {
    if (isComplete) return widget.onCaptureComplete;
    if (_isRecording) return null;
    return () {
      setState(() => _isRecording = true);
      provider.startTraining(widget.gestureName);
    };
  }
}
