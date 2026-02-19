import 'package:flutter/material.dart';
import '../models/response_models.dart';
import '../main.dart';

class GestureCard extends StatefulWidget {
  final GestureConfig gesture;
  final VoidCallback onDelete;

  const GestureCard({
    super.key,
    required this.gesture,
    required this.onDelete,
  });

  @override
  State<GestureCard> createState() => _GestureCardState();
}

class _GestureCardState extends State<GestureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _getColorForGesture(widget.gesture.name);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered ? color.withOpacity(0.4) : Colors.white.withOpacity(0.06),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: _isHovered
                ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 24, spreadRadius: 2)]
                : [],
          ),
          child: Stack(
            children: [
              // Glow gradient on hover
              if (_isHovered)
                Positioned(
                  top: -20,
                  left: -20,
                  right: -20,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [color.withOpacity(0.12), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Gradient icon circle
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                        ),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Icon(
                        _getIconForGesture(widget.gesture.name),
                        size: 24,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.gesture.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withOpacity(0.15)),
                      ),
                      child: Text(
                        widget.gesture.action,
                        style: TextStyle(color: color.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Delete button
              Positioned(
                top: 6,
                right: 6,
                child: AnimatedOpacity(
                  opacity: _isHovered ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: Tooltip(
                    message: 'Delete gesture',
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                      onPressed: widget.onDelete,
                      splashRadius: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForGesture(String name) {
    final n = name.toLowerCase();
    if (n.contains('fist')) return AppColors.magenta;
    if (n.contains('palm')) return AppColors.cyan;
    if (n.contains('thumb')) return AppColors.neonGreen;
    if (n.contains('peace')) return AppColors.amber;
    return AppColors.cyan;
  }

  IconData _getIconForGesture(String name) {
    final n = name.toLowerCase();
    if (n.contains('fist')) return Icons.front_hand_rounded;
    if (n.contains('palm')) return Icons.pan_tool_rounded;
    if (n.contains('thumb')) return Icons.thumb_up_rounded;
    if (n.contains('peace')) return Icons.back_hand_rounded;
    return Icons.gesture;
  }
}
