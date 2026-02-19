import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../main.dart';
import 'native_camera_view.dart';
import 'hand_skeleton_painter.dart';

class CameraFeed extends StatelessWidget {
  const CameraFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GestureProvider>(
      builder: (context, provider, child) {
        final response = provider.currentResponse;
        final isActive = provider.isSystemActive;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.cyan.withOpacity(0.25) : AppColors.textSecondary.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(color: AppColors.cyan.withOpacity(0.08), blurRadius: 24, spreadRadius: 2),
                    BoxShadow(color: AppColors.magenta.withOpacity(0.04), blurRadius: 32, offset: const Offset(8, 8)),
                  ]
                : [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Native camera preview ─────────────────────────────
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.grey,
                    isActive ? BlendMode.dst : BlendMode.saturation,
                  ),
                  child: const NativeCameraView(),
                ),

                // ── Hand skeleton overlay ─────────────────────────────
                if (isActive && response.hasHand)
                  CustomPaint(
                    painter: HandSkeletonPainter(landmarks: response.landmarks),
                    size: Size.infinite,
                  ),

                // ── Scanline overlay (cyberpunk) ──────────────────────
                if (isActive)
                  const _ScanlineOverlay(),

                // ── Glassmorphic confidence bar ───────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.black.withOpacity(0.35),
                            ],
                          ),
                          border: Border(
                            top: BorderSide(color: Colors.white.withOpacity(0.08)),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getConfidenceColor(response.confidence),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getConfidenceColor(response.confidence).withOpacity(0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      response.gesture,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getConfidenceColor(response.confidence).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _getConfidenceColor(response.confidence).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${(response.confidence * 100).toInt()}%',
                                    style: TextStyle(
                                      color: _getConfidenceColor(response.confidence),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                child: LinearProgressIndicator(
                                  value: response.confidence,
                                  backgroundColor: Colors.white.withOpacity(0.08),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getConfidenceColor(response.confidence),
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── System Inactive overlay ──────────────────────────
                if (!isActive)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        color: AppColors.bg.withOpacity(0.7),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pause_circle_outline_rounded, size: 48, color: AppColors.textSecondary.withOpacity(0.6)),
                              const SizedBox(height: 12),
                              const Text(
                                'SYSTEM PAUSED',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3.0,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Top-left REC • LIVE badge ─────────────────────────
                if (isActive && provider.isConnected)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.neonRed.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: AppColors.neonRed.withOpacity(0.4), blurRadius: 10, spreadRadius: 1),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 4),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'REC • LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Bottom-left large gesture label ───────────────────
                if (isActive && response.hasHand && response.gesture != 'None')
                  Positioned(
                    bottom: 80,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          response.gesture,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 12),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(response.confidence * 100).toInt()}% confidence',
                          style: TextStyle(
                            color: _getConfidenceColor(response.confidence),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return AppColors.neonGreen;
    if (confidence > 0.5) return AppColors.amber;
    if (confidence > 0.2) return AppColors.magenta;
    return AppColors.textSecondary;
  }
}

/// Subtle cyberpunk scanline overlay.
class _ScanlineOverlay extends StatefulWidget {
  const _ScanlineOverlay();

  @override
  State<_ScanlineOverlay> createState() => _ScanlineOverlayState();
}

class _ScanlineOverlayState extends State<_ScanlineOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.cyan.withOpacity(0.03),
                    Colors.transparent,
                  ],
                  stops: [
                    (_ctrl.value - 0.1).clamp(0.0, 1.0),
                    _ctrl.value,
                    (_ctrl.value + 0.1).clamp(0.0, 1.0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
