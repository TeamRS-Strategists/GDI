import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/gesture_card.dart';
import '../widgets/add_gesture_dialog.dart';
import '../widgets/retraining_overlay.dart';
import '../main.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isTraining = false;
  bool _showTrainBanner = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gesture Library',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage and customize gesture controls',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddGestureDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Gesture'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      backgroundColor: AppColors.cyan,
                      foregroundColor: AppColors.bg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Train Model Banner
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: _showTrainBanner
                    ? Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.cyan.withOpacity(0.1), AppColors.magenta.withOpacity(0.06)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.cyan, size: 18),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Library changed — retrain to apply new gestures.',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showTrainBanner = false;
                                  _isTraining = true;
                                });
                              },
                              child: const Text(
                                'Train Model',
                                style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Grid
              Expanded(
                child: Consumer<GestureProvider>(
                  builder: (context, provider, child) {
                    if (provider.gestures.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_motion_rounded, size: 48, color: AppColors.textSecondary.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            const Text('No gestures configured', style: TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Tap "Add Gesture" to get started', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 12)),
                          ],
                        ),
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = (constraints.maxWidth / 220).floor().clamp(2, 6);
                        final totalItems = provider.gestures.length + 1; // +1 for "Create New"
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: totalItems,
                          itemBuilder: (context, index) {
                            // Last item = "Create New" card
                            if (index == provider.gestures.length) {
                              return _buildCreateNewCard(context);
                            }
                            final gesture = provider.gestures[index];
                            return GestureCard(
                              gesture: gesture,
                              onDelete: () {
                                provider.removeGesture(gesture.name);
                                setState(() => _showTrainBanner = true);
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Retraining Overlay
        if (_isTraining)
          Positioned.fill(
            child: RetrainingOverlay(
              onComplete: () {
                setState(() => _isTraining = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Model retrained successfully!'),
                    backgroundColor: AppColors.neonGreen.withOpacity(0.8),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCreateNewCard(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showAddGestureDialog(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.cyan.withOpacity(0.25),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            color: AppColors.cyan.withOpacity(0.03),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan.withOpacity(0.08),
                  border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.cyan, size: 24),
              ),
              const SizedBox(height: 12),
              const Text(
                'Create New',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add a gesture',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGestureDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) => AddGestureDialog(
        onSave: (config) async {
          final provider = Provider.of<GestureProvider>(context, listen: false);
          await provider.addGesture(config);
          setState(() => _showTrainBanner = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gesture "${config.name}" added — Model Retrained Successfully'),
              backgroundColor: AppColors.neonGreen.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        },
      ),
    );
  }
}
