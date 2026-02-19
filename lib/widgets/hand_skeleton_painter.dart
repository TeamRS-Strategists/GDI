import 'package:flutter/material.dart';
import '../main.dart';

/// MediaPipe hand connections — 21 landmarks connected as a skeleton.
/// Each pair [from, to] defines a bone to draw.
const List<List<int>> _handConnections = [
  // Thumb
  [0, 1], [1, 2], [2, 3], [3, 4],
  // Index
  [0, 5], [5, 6], [6, 7], [7, 8],
  // Middle
  [5, 9], [9, 10], [10, 11], [11, 12],
  // Ring
  [9, 13], [13, 14], [14, 15], [15, 16],
  // Pinky
  [13, 17], [17, 18], [18, 19], [19, 20],
  // Palm base
  [0, 17],
];

/// Draws a hand skeleton overlay using 21 normalized landmark coordinates.
///
/// Landmarks from MediaPipe are normalized (0–1) relative to the backend camera
/// frame (640×480, 4:3). The native Flutter camera preview may have a different
/// aspect ratio and uses BoxFit.cover, so we must compensate for the crop.
class HandSkeletonPainter extends CustomPainter {
  final List<List<double>>? landmarks;

  /// Aspect ratio of the backend camera frame (width / height).
  static const double _backendCameraAR = 640.0 / 480.0; // 4:3

  HandSkeletonPainter({this.landmarks});

  /// Convert a normalized landmark [x, y] to screen coordinates,
  /// accounting for BoxFit.cover crop differences.
  Offset _toScreen(List<double> pt, Size size) {
    final widgetAR = size.width / size.height;

    double screenX, screenY;

    if (widgetAR > _backendCameraAR) {
      // Widget is wider than backend frame → height is scaled to fill,
      // so extra width on left/right in widget (but backend frame maps
      // directly in X).
      // Actually for BoxFit.cover: scale by width, top/bottom cropped
      final displayedHeight = size.width / _backendCameraAR;
      final cropY = (displayedHeight - size.height) / 2;
      screenX = pt[0] * size.width;
      screenY = pt[1] * displayedHeight - cropY;
    } else {
      // Widget is taller than backend frame → width is scaled to fill,
      // left/right cropped
      final displayedWidth = size.height * _backendCameraAR;
      final cropX = (displayedWidth - size.width) / 2;
      screenX = pt[0] * displayedWidth - cropX;
      screenY = pt[1] * size.height;
    }

    return Offset(screenX, screenY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks == null || landmarks!.length < 21) return;

    final lms = landmarks!;

    // ── Bone lines (green) ─────────────────────────────────────────────
    final bonePaint = Paint()
      ..color = AppColors.neonGreen.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final conn in _handConnections) {
      canvas.drawLine(
        _toScreen(lms[conn[0]], size),
        _toScreen(lms[conn[1]], size),
        bonePaint,
      );
    }

    // ── Joint dots (cyan)
    final jointPaint = Paint()
      ..color = AppColors.cyan
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = AppColors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (final pt in lms) {
      final offset = _toScreen(pt, size);
      // Glow
      canvas.drawCircle(offset, 5, glowPaint);
      // Dot
      canvas.drawCircle(offset, 3, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HandSkeletonPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks;
  }
}
