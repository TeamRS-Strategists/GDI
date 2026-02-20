import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';
import '../widgets/voice_command_indicator.dart';
import '../widgets/jarvis_conversation_widget.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController(text: 'ws://localhost:8000/ws');
  int _cameraIndex = 0;
  double _confidenceThreshold = 0.7;
  bool _mouseControl = true;
  bool _soundFeedback = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure backend, camera, and controls',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 28),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection section
                  _buildSectionTitle('Connection'),
                  const SizedBox(height: 12),
                  _buildTextFieldSetting(
                    'Backend WebSocket URL',
                    _urlController,
                    Icons.link_rounded,
                  ),
                  const SizedBox(height: 28),

                  // Camera section
                  _buildSectionTitle('Camera'),
                  const SizedBox(height: 12),
                  _buildDropdownSetting(
                    'Camera Index',
                    _cameraIndex.toString(),
                    ['0', '1', '2'],
                    Icons.videocam_rounded,
                    (val) => setState(() => _cameraIndex = int.parse(val!)),
                  ),
                  const SizedBox(height: 12),
                  _buildSliderSetting(
                    'Confidence Threshold',
                    _confidenceThreshold,
                    Icons.speed_rounded,
                    (val) => setState(() => _confidenceThreshold = val),
                  ),
                  const SizedBox(height: 28),

                  // Controls section
                  _buildSectionTitle('Controls'),
                  const SizedBox(height: 12),
                  _buildToggleSetting(
                    'Mouse Control',
                    'Control cursor with hand gestures',
                    _mouseControl,
                    Icons.mouse_rounded,
                    (val) => setState(() => _mouseControl = val),
                  ),
                  const SizedBox(height: 12),
                  _buildToggleSetting(
                    'Sound Feedback',
                    'Play sound on gesture detection',
                    _soundFeedback,
                    Icons.volume_up_rounded,
                    (val) => setState(() => _soundFeedback = val),
                  ),
                  const SizedBox(height: 28),

                  // Voice Assistant section
                  _buildSectionTitle('Voice Assistant'),
                  const SizedBox(height: 12),
                  const VoiceCommandIndicator(),
                  const SizedBox(height: 28),

                  // Jarvis Conversational Assistant section
                  _buildSectionTitle('Jarvis - Conversational AI'),
                  const SizedBox(height: 12),
                  const SizedBox(
                    height: 500,
                    child: JarvisConversationWidget(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.cyan,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextFieldSetting(String label, TextEditingController controller, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.cyan, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.cyan),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(String label, String value, List<String> options, IconData icon, ValueChanged<String?> onChanged) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.cyan, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: value,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.cyan),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                  ),
                  items: options.map((o) => DropdownMenuItem(value: o, child: Text('Camera $o'))).toList(),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(String label, double value, IconData icon, ValueChanged<double> onChanged) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.cyan, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text('${(value * 100).toInt()}%', style: const TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.cyan,
                    inactiveTrackColor: Colors.white.withOpacity(0.08),
                    thumbColor: AppColors.cyan,
                    overlayColor: AppColors.cyan.withOpacity(0.1),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: value,
                    min: 0.3,
                    max: 1.0,
                    divisions: 14,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSetting(String title, String subtitle, bool value, IconData icon, ValueChanged<bool> onChanged) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 12,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.cyan, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.cyan,
            activeTrackColor: AppColors.cyan.withOpacity(0.3),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: Colors.white.withOpacity(0.08),
          ),
        ],
      ),
    );
  }
}
