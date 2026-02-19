import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/app_provider.dart';
import 'screens/layout/main_layout.dart';

// ── Cyberpunk Glass Palette ──────────────────────────────────────────────────
class AppColors {
  AppColors._();
  // Core backgrounds
  static const Color bg           = Color(0xFF050510);  // Deep Space Black
  static const Color bgLight      = Color(0xFF0A0E1A);
  static const Color surface      = Color(0xFF161B2E);
  static const Color surfaceLight = Color(0xFF1E2440);
  // Glass
  static Color glassSurface       = const Color(0xFF191933).withOpacity(0.7);
  // Accent colors
  static const Color primary      = Color(0xFF1313EC);  // Neon Blue (brand)
  static const Color cyan         = Color(0xFF00D4FF);   // Highlight cyan
  static const Color magenta      = Color(0xFFFF006E);
  static const Color neonGreen    = Color(0xFF22C55E);
  static const Color neonRed      = Color(0xFFEF4444);
  static const Color amber        = Color(0xFFFFB300);
  // Text
  static const Color textPrimary  = Color(0xFFEAECF0);
  static const Color textSecondary= Color(0xFF8B8FA3);
  // Border
  static const Color border       = Color(0xFF1E2440);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Frameless Window Setup ────────────────────────────────────────────────
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(960, 600),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'GestureFlow',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const GestureFlowApp());
}

class GestureFlowApp extends StatelessWidget {
  const GestureFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GestureProvider()),
      ],
      child: MaterialApp(
        title: 'GestureFlow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.bg,
          textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme).apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.cyan,
            secondary: AppColors.magenta,
            surface: AppColors.surface,
          ),
        ),
        home: const MainLayout(),
      ),
    );
  }
}
