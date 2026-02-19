import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';

/// Maps action names to display info (icon + color).
class _ActionInfo {
  final IconData icon;
  final Color color;
  const _ActionInfo(this.icon, this.color);
}

const Map<String, _ActionInfo> _actionMap = {
  'Volume Up': _ActionInfo(Icons.volume_up_rounded, AppColors.neonGreen),
  'Volume Down': _ActionInfo(Icons.volume_down_rounded, AppColors.amber),
  'Volume Mute': _ActionInfo(Icons.volume_off_rounded, AppColors.magenta),
  'Play/Pause': _ActionInfo(Icons.play_arrow_rounded, AppColors.cyan),
  'Next Track': _ActionInfo(Icons.skip_next_rounded, AppColors.cyan),
  'Previous Track': _ActionInfo(Icons.skip_previous_rounded, AppColors.cyan),
  'Screenshot': _ActionInfo(Icons.screenshot_rounded, AppColors.neonGreen),
  'Scroll Up': _ActionInfo(Icons.arrow_upward_rounded, AppColors.cyan),
  'Scroll Down': _ActionInfo(Icons.arrow_downward_rounded, AppColors.cyan),
  'Next Tab': _ActionInfo(Icons.tab_rounded, AppColors.cyan),
  'Previous Tab': _ActionInfo(Icons.tab_unselected_rounded, AppColors.cyan),
};

/// HUD-style overlay that shows which action was triggered.
/// Uses [actionVersion] (a counter) to detect new triggers, even if the
/// same action fires repeatedly (e.g. multiple "Volume Up" in a row).
class ActionFeedbackOverlay extends StatefulWidget {
  final String? action;
  final int actionVersion;

  const ActionFeedbackOverlay({
    super.key,
    this.action,
    required this.actionVersion,
  });

  @override
  State<ActionFeedbackOverlay> createState() => _ActionFeedbackOverlayState();
}

class _ActionFeedbackOverlayState extends State<ActionFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  String? _displayAction;
  Timer? _hideTimer;
  int _lastVersion = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(covariant ActionFeedbackOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger whenever the version counter changes (new action fired)
    if (widget.actionVersion != _lastVersion && widget.action != null) {
      _lastVersion = widget.actionVersion;
      _showAction(widget.action!);
    }
  }

  void _showAction(String action) {
    _hideTimer?.cancel();
    setState(() => _displayAction = action);
    _ctrl.forward(from: 0);

    _hideTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayAction == null) return const SizedBox.shrink();

    final info = _actionMap[_displayAction] ??
        const _ActionInfo(Icons.touch_app_rounded, AppColors.cyan);

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: info.color.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: info.color.withOpacity(0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: info.color.withOpacity(0.15),
                  border: Border.all(color: info.color.withOpacity(0.3)),
                ),
                child: Icon(info.icon, color: info.color, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _displayAction!,
                    style: TextStyle(
                      color: info.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Action Triggered',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
