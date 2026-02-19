import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../main.dart';

class ActionLog extends StatelessWidget {
  const ActionLog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GestureProvider>(
      builder: (context, provider, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: AppColors.cyan, size: 14),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ACTION LOG',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${provider.logs.length} events',
                          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                  // Log entries
                  Expanded(
                    child: provider.logs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hourglass_empty_rounded, size: 28, color: AppColors.textSecondary.withOpacity(0.3)),
                                const SizedBox(height: 8),
                                Text(
                                  'No events yet',
                                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.4), fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: provider.logs.length,
                            itemBuilder: (context, index) {
                              final log = provider.logs[index];
                              final isDetected = log.contains('Detected');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isDetected
                                        ? AppColors.neonGreen.withOpacity(0.04)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDetected ? AppColors.neonGreen : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          log,
                                          style: TextStyle(
                                            color: isDetected ? AppColors.neonGreen.withOpacity(0.9) : AppColors.textSecondary,
                                            fontSize: 11,
                                            fontFamily: 'JetBrains Mono',
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
