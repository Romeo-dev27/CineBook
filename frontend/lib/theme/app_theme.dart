import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0C0E15);
  static const Color surface = Color(0xFF151923);
  static const Color surfaceElevated = Color(0xFF1D2330);
  static const Color border = Color(0xFF2B3243);

  static const Color gold = Color(0xFFE3AC52);
  static const Color goldLight = Color(0xFFF2D18B);
  static const Color cyan = Color(0xFF62C6D4);
  static const Color purple = Color(0xFF9A82D0);
  static const Color emerald = Color(0xFF69B99A);
  static const Color ruby = Color(0xFFDF6B73);
  static const Color amber = Color(0xFFE3AC52);
  static const Color lime = Color(0xFFB7C983);
  static const Color orange = Color(0xFFD69364);

  static const Color textPrimary = Color(0xFFF4F1EA);
  static const Color textSecondary = Color(0xFFAAB2C0);
  static const Color textMuted = Color(0xFF768193);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: gold,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: cyan,
        surface: surface,
        error: ruby,
        onPrimary: Color(0xFF171006),
        onSecondary: Color(0xFF071316),
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: gold,
        inactiveTrackColor: surfaceElevated,
        thumbColor: goldLight,
        overlayColor: gold.withValues(alpha: 0.12),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: const Color(0xFF171006),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldLight,
          side: BorderSide(color: gold.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated.withValues(alpha: 0.72),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        prefixIconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: gold,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
