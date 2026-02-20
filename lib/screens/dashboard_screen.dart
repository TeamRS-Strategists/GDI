import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/camera_feed.dart';
import '../widgets/action_log.dart';
import '../widgets/action_feedback_overlay.dart';
import '../widgets/glass_container.dart';
import '../widgets/jarvis_conversation_widget.dart';
import '../providers/app_provider.dart';
import '../main.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GestureProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Real-time gesture monitoring & control',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              // Toggles
              Row(
                children: [
                  // Mouse Control toggle
                  _buildMouseToggle(provider),
                  const SizedBox(width: 12),
                  // System toggle
                  _buildSystemToggle(provider),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Live Stats Row ─────────────────────────────────────
          Row(
            children: [
              _buildMiniStat(
                'Current Gesture',
                provider.currentResponse.gesture,
                Icons.pan_tool_alt_rounded,
                AppColors.cyan,
              ),
              const SizedBox(width: 12),
              _buildMiniStat(
                'Confidence',
                '${(provider.currentResponse.confidence * 100).toInt()}%',
                Icons.speed_rounded,
                _getConfidenceColor(provider.currentResponse.confidence),
              ),
              const SizedBox(width: 12),
              _buildMiniStat(
                'Status',
                provider.isConnected ? 'Online' : 'Offline',
                Icons.wifi_rounded,
                provider.isConnected ? AppColors.neonGreen : AppColors.magenta,
              ),
              const SizedBox(width: 12),
              _buildMiniStat(
                'Events',
                '${provider.logs.length}',
                Icons.receipt_long_rounded,
                AppColors.amber,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Main Content ───────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Camera feed with action overlay
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: CameraFeed()),
                      // Action HUD overlay (top-center)
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ActionFeedbackOverlay(
                            action: provider.lastTriggeredAction,
                            actionVersion: provider.actionVersion,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right panel: stats + jarvis + log
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Stats Card
                      _buildStatsCard(provider),
                      const SizedBox(height: 16),
                      // Jarvis Voice Assistant
                      const SizedBox(
                        height: 350,
                        child: JarvisConversationWidget(),
                      ),
                      const SizedBox(height: 16),
                      // Action Log
                      const Expanded(child: ActionLog()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMouseToggle(GestureProvider provider) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      borderRadius: 12,
      borderColor: provider.mouseEnabled
          ? AppColors.cyan.withOpacity(0.2)
          : AppColors.textSecondary.withOpacity(0.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mouse_rounded,
            color: provider.mouseEnabled ? AppColors.cyan : AppColors.textSecondary,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            'Mouse',
            style: TextStyle(
              color: provider.mouseEnabled ? AppColors.cyan : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 24,
            child: Switch(
              value: provider.mouseEnabled,
              onChanged: (_) => provider.toggleMouse(),
              activeColor: AppColors.cyan,
              activeTrackColor: AppColors.cyan.withOpacity(0.3),
              inactiveThumbColor: AppColors.textSecondary,
              inactiveTrackColor: AppColors.textSecondary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemToggle(GestureProvider provider) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      borderRadius: 12,
      borderColor: provider.isSystemActive
          ? AppColors.neonGreen.withOpacity(0.2)
          : AppColors.magenta.withOpacity(0.2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: provider.isSystemActive ? AppColors.neonGreen : AppColors.magenta,
              boxShadow: [
                BoxShadow(
                  color: (provider.isSystemActive ? AppColors.neonGreen : AppColors.magenta).withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            provider.isSystemActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: provider.isSystemActive ? AppColors.neonGreen : AppColors.magenta,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 24,
            child: Switch(
              value: provider.isSystemActive,
              onChanged: (val) => provider.toggleSystem(),
              activeColor: AppColors.neonGreen,
              activeTrackColor: AppColors.neonGreen.withOpacity(0.3),
              inactiveThumbColor: AppColors.magenta,
              inactiveTrackColor: AppColors.magenta.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 12,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(GestureProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cyan.withOpacity(0.08),
                AppColors.magenta.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cyan.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.insights_rounded, color: AppColors.cyan, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SESSION OVERVIEW',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Gestures', '${provider.logs.length}', AppColors.cyan),
                  _buildStatItem('Accuracy', '95%', AppColors.neonGreen),
                  _buildStatItem('Latency', '~33ms', AppColors.amber),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return AppColors.neonGreen;
    if (confidence > 0.5) return AppColors.amber;
    return AppColors.magenta;
  }
}
