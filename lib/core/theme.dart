import 'package:flutter/material.dart';

/// Same colors as the Web Console and the landing page.
class Brand {
  Brand._();

  static const primary = Color(0xFF004F8C);
  static const primaryContainer = Color(0xFFD6E6F5);
  static const green = Color(0xFF009E60);
  static const greenContainer = Color(0xFFD3F2E4);
  static const ink = Color(0xFF102A43);
  static const muted = Color(0xFF486581);
  static const surfaceLow = Color(0xFFF4F7FA);
  static const outline = Color(0xFFD9E2EC);
  static const error = Color(0xFFE74C3C);
  static const warning = Color(0xFFE8890C);

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      primaryContainer: primaryContainer,
      secondary: green,
      secondaryContainer: greenContainer,
      error: error,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaceLow,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
