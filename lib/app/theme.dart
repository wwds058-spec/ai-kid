import 'package:flutter/material.dart';

/// AI Explorer design tokens.
/// Brand palette: friendly, high-contrast, accessible for young children.
abstract class AIExplorerTheme {
  // ── Brand colours ──────────────────────────────────────────────────────────
  static const purple   = Color(0xFF7C3AED);
  static const purpleSoft = Color(0xFFEDE9FE);
  static const teal     = Color(0xFF0D9488);
  static const tealSoft = Color(0xFFCCFBF1);
  static const yellow   = Color(0xFFFBBF24);
  static const pinkSoft = Color(0xFFFCE7F3);
  static const white    = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF9FAFB);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: offWhite,
        // Large, round, child-friendly buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: purple,
            foregroundColor: white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
          titleLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
          bodyLarge: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
          bodyMedium: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF6B7280)),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.dark,
        ),
      );
}
