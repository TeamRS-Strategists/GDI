import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/response_models.dart';
import '../main.dart';
import 'capture_step.dart';

class AddGestureDialog extends StatefulWidget {
  /// Callback with the full GestureConfig for maximum flexibility.
  final Function(GestureConfig config) onSave;

  const AddGestureDialog({super.key, required this.onSave});

  @override
  State<AddGestureDialog> createState() => _AddGestureDialogState();
}

class _AddGestureDialogState extends State<AddGestureDialog> {
  int _currentStep = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _keysController = TextEditingController();
  String? _selectedAction;
  bool _captureComplete = false;
  bool _isCustomKeyboard = false;

  // Focus node for capturing keyboard shortcuts
  final FocusNode _keyCaptureFocus = FocusNode();
  final List<String> _capturedKeys = [];
  bool _isCapturing = false;

  static const List<String> _presetActions = [
    'Volume Up',
    'Volume Down',
    'Volume Mute',
    'Play/Pause',
    'Next Track',
    'Previous Track',
    'Screenshot',
    'Scroll Up',
    'Scroll Down',
    'Next Tab',
    'Previous Tab',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _keysController.dispose();
    _keyCaptureFocus.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cyan.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(color: AppColors.cyan.withOpacity(0.05), blurRadius: 40, spreadRadius: 4),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getTitle(),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                      splashRadius: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stepper indicator
                _buildStepperIndicator(),
                const SizedBox(height: 24),

                // Content
                _buildContent(),
                const SizedBox(height: 28),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentStep == 0)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    if (_currentStep == 2)
                      TextButton(
                        onPressed: () => setState(() => _currentStep = 0),
                        child: const Text('Start Over', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    const SizedBox(width: 12),
                    // Show Next/Save button on steps 0 and 2 (step 1 has its own "I'm Ready" button)
                    if (_currentStep != 1)
                      ElevatedButton(
                        onPressed: _canProceed() ? _onNext : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: AppColors.bg,
                          disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          _currentStep == 2 ? 'Save to Library' : 'Next',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperIndicator() {
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          _buildStepDot(i),
          if (i < 2)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: i < _currentStep ? AppColors.cyan : AppColors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStepDot(int step) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    final labels = ['Setup', 'Capture', 'Review'];

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.cyan
                : isActive
                    ? AppColors.cyan.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
            border: Border.all(
              color: isActive || isCompleted ? AppColors.cyan : AppColors.textSecondary.withOpacity(0.2),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? [BoxShadow(color: AppColors.cyan.withOpacity(0.3), blurRadius: 8)] : [],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? AppColors.cyan : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          labels[step],
          style: TextStyle(
            color: isActive || isCompleted ? AppColors.cyan : AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getTitle() {
    switch (_currentStep) {
      case 0: return 'Setup Gesture';
      case 1: return 'Capture Samples';
      case 2: return 'Review & Save';
      default: return '';
    }
  }

  bool _canProceed() {
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty) return false;
      if (_isCustomKeyboard) return _keysController.text.isNotEmpty;
      return _selectedAction != null;
    }
    if (_currentStep == 1) return _captureComplete;
    return true;
  }

  Widget _buildContent() {
    switch (_currentStep) {
      case 0:
        return _buildSetupStep();
      case 1:
        return CaptureStep(
          gestureName: _nameController.text,
          action: _isCustomKeyboard ? _keysController.text : (_selectedAction ?? ''),
          onCaptureComplete: () {
            setState(() {
              _captureComplete = true;
              _currentStep = 2;
            });
          },
        );
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSetupStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gesture name
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Gesture Name',
            labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            prefixIcon: const Icon(Icons.gesture, color: AppColors.textSecondary, size: 18),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.cyan),
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
          ),
        ),
        const SizedBox(height: 16),

        // Action type toggle
        Row(
          children: [
            _buildActionTypeChip('Preset Action', Icons.play_circle_outline_rounded, !_isCustomKeyboard),
            const SizedBox(width: 10),
            _buildActionTypeChip('Keyboard Shortcut', Icons.keyboard_rounded, _isCustomKeyboard),
          ],
        ),
        const SizedBox(height: 16),

        // Conditional content based on action type
        if (!_isCustomKeyboard) _buildPresetDropdown(),
        if (_isCustomKeyboard) _buildKeyboardShortcutInput(),
      ],
    );
  }

  Widget _buildActionTypeChip(String label, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isCustomKeyboard = label == 'Keyboard Shortcut';
            // Reset selection when switching type
            if (_isCustomKeyboard) {
              _selectedAction = null;
            } else {
              _keysController.clear();
              _capturedKeys.clear();
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.cyan.withOpacity(0.12)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.cyan.withOpacity(0.5) : Colors.white.withOpacity(0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.cyan : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.cyan : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedAction,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Map to Action',
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: const Icon(Icons.bolt_rounded, color: AppColors.textSecondary, size: 18),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.cyan),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
      ),
      items: _presetActions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
      onChanged: (val) => setState(() => _selectedAction = val),
    );
  }

  Widget _buildKeyboardShortcutInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Key capture field
        Focus(
          focusNode: _keyCaptureFocus,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && _isCapturing) {
              _handleKeyEvent(event);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isCapturing = true;
                _capturedKeys.clear();
                _keysController.clear();
              });
              _keyCaptureFocus.requestFocus();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _isCapturing
                    ? AppColors.cyan.withOpacity(0.08)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isCapturing
                      ? AppColors.cyan
                      : _keysController.text.isNotEmpty
                          ? AppColors.neonGreen.withOpacity(0.4)
                          : Colors.white.withOpacity(0.1),
                  width: _isCapturing ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCapturing ? Icons.radio_button_on_rounded : Icons.keyboard_rounded,
                    size: 18,
                    color: _isCapturing ? AppColors.cyan : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _keysController.text.isNotEmpty
                          ? _keysController.text.toUpperCase()
                          : _isCapturing
                              ? 'Press your shortcut...'
                              : 'Click to record shortcut',
                      style: TextStyle(
                        color: _keysController.text.isNotEmpty
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: _keysController.text.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (_keysController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() {
                        _keysController.clear();
                        _capturedKeys.clear();
                        _isCapturing = false;
                      }),
                      child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isCapturing
              ? 'Press a key combination (e.g. ⌘+Shift+A)'
              : 'Click the field above, then press your desired shortcut',
          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 11),
        ),
      ],
    );
  }

  void _handleKeyEvent(KeyDownEvent event) {
    final key = event.logicalKey;
    
    // Collect modifiers and the key
    final parts = <String>[];
    
    if (HardwareKeyboard.instance.isMetaPressed) parts.add('cmd');
    if (HardwareKeyboard.instance.isControlPressed) parts.add('ctrl');
    if (HardwareKeyboard.instance.isAltPressed) parts.add('alt');
    if (HardwareKeyboard.instance.isShiftPressed) parts.add('shift');
    
    // Get the actual key (skip if it's just a modifier)
    final modifierKeys = {
      LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.metaRight,
      LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.altLeft, LogicalKeyboardKey.altRight,
      LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight,
    };
    
    if (modifierKeys.contains(key)) return; // Wait for the actual key
    
    // Map the key label
    String keyLabel = key.keyLabel.toLowerCase();
    if (keyLabel.isEmpty) keyLabel = key.debugName?.toLowerCase() ?? 'unknown';
    
    // Normalize common key names
    final keyMap = {
      ' ': 'space', 'arrow up': 'up', 'arrow down': 'down',
      'arrow left': 'left', 'arrow right': 'right',
    };
    keyLabel = keyMap[keyLabel] ?? keyLabel;
    
    parts.add(keyLabel);
    
    setState(() {
      _keysController.text = parts.join('+');
      _isCapturing = false;
    });
  }

  Widget _buildReviewStep() {
    final actionDisplay = _isCustomKeyboard
        ? _keysController.text.toUpperCase()
        : (_selectedAction ?? '');
    final typeDisplay = _isCustomKeyboard ? 'Keyboard Shortcut' : 'Preset Action';

    return Column(
      children: [
        // Success icon
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonGreen.withOpacity(0.1),
          ),
          child: const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 40),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              _buildReviewRow(Icons.gesture, 'Gesture Name', _nameController.text),
              Divider(color: Colors.white.withOpacity(0.05), height: 20),
              _buildReviewRow(
                _isCustomKeyboard ? Icons.keyboard_rounded : Icons.bolt_rounded,
                'Action Type',
                typeDisplay,
              ),
              Divider(color: Colors.white.withOpacity(0.05), height: 20),
              _buildReviewRow(Icons.flash_on_rounded, 'Mapped Action', actionDisplay),
              Divider(color: Colors.white.withOpacity(0.05), height: 20),
              _buildReviewRow(Icons.check_circle_outline_rounded, 'Status', 'Model Retrained', color: AppColors.neonGreen),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? AppColors.textSecondary, size: 16),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _onNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // Step 3: Save & Close
      final provider = context.read<GestureProvider>();
      final config = GestureConfig(
        name: _nameController.text,
        action: _isCustomKeyboard ? _keysController.text : (_selectedAction ?? ''),
        actionType: _isCustomKeyboard ? 'keyboard' : 'preset',
        keys: _isCustomKeyboard ? _keysController.text : '',
      );
      widget.onSave(config);
      provider.resetTrainingState();
      Navigator.pop(context);
    }
  }
}
