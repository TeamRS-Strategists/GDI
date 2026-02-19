import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable frosted-glass panel with gradient border and optional neon glow.
/// Used throughout the Cyberpunk Glass UI.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color? glowColor;
  final double opacity;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blur = 16,
    this.borderColor,
    this.glowColor,
    this.opacity = 0.12,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              // Gradient fill
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(opacity + 0.03),
                  Colors.white.withOpacity(opacity - 0.04),
                ],
              ),
              // Gradient border: white 10% → transparent
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.1),
                width: 1,
              ),
              // Optional neon glow shadow
              boxShadow: glowColor != null
                  ? [BoxShadow(color: glowColor!.withOpacity(0.15), blurRadius: 16, spreadRadius: 1)]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
