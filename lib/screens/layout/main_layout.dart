import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../widgets/sidebar.dart';
import '../dashboard_screen.dart';
import '../library_screen.dart';
import '../settings_screen.dart';
import '../../main.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [
              AppColors.bg,
              AppColors.bgLight,
              AppColors.bg,
            ],
          ),
        ),
        child: Column(
          children: [
            // ── Custom Frameless Title Bar ─────────────────────────────
            _buildTitleBar(),
            // ── Main Content ──────────────────────────────────────────
            Expanded(
              child: Row(
                children: [
                  Sidebar(
                    selectedIndex: _selectedIndex,
                    onItemSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(_selectedIndex),
                        child: _screens[_selectedIndex],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 36,
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // macOS traffic lights occupy ~70px on the left, leave space
            const SizedBox(width: 70),
            // App title — centered
            const Expanded(
              child: Center(
                child: Text(
                  'GestureFlow',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            // Window controls (macOS handles natively, this is for symmetry)
            const SizedBox(width: 70),
          ],
        ),
      ),
    );
  }
}
