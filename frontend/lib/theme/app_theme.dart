import 'package:flutter/material.dart';

class CineBookColors extends ThemeExtension<CineBookColors> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color accent;
  final Color onAccent;
  final Color gold;
  final Color goldLight;
  final Color cyan;
  final Color purple;
  final Color emerald;
  final Color ruby;
  final Color amber;
  final Color lime;
  final Color orange;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color posterPlaceholder;

  const CineBookColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.gold,
    required this.goldLight,
    required this.cyan,
    required this.purple,
    required this.emerald,
    required this.ruby,
    required this.amber,
    required this.lime,
    required this.orange,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.posterPlaceholder,
  });

  static const dark = CineBookColors(
    background: Color(0xFF101214),
    surface: Color(0xFF17191C),
    surfaceElevated: Color(0xFF222529),
    border: Color(0xFF35393D),
    accent: Color(0xFFD8B36D),
    onAccent: Color(0xFF1B1509),
    gold: Color(0xFFD8B36D),
    goldLight: Color(0xFFF0D8A4),
    cyan: Color(0xFF79B7BD),
    purple: Color(0xFFAAA0CA),
    emerald: Color(0xFF7DB79C),
    ruby: Color(0xFFDB7C80),
    amber: Color(0xFFD8B36D),
    lime: Color(0xFFADBD8B),
    orange: Color(0xFFD09870),
    textPrimary: Color(0xFFF2EFE8),
    textSecondary: Color(0xFFB9B7B0),
    textMuted: Color(0xFF858781),
    posterPlaceholder: Color(0xFF2B2F33),
  );

  static const light = CineBookColors(
    background: Color(0xFFF2EFE8),
    surface: Color(0xFFFCFAF5),
    surfaceElevated: Color(0xFFE8E3D9),
    border: Color(0xFFD3CCC0),
    accent: Color(0xFF8E3038),
    onAccent: Color(0xFFFFFFFF),
    gold: Color(0xFF986A27),
    goldLight: Color(0xFF744C18),
    cyan: Color(0xFF2B6C73),
    purple: Color(0xFF6B5C91),
    emerald: Color(0xFF356B55),
    ruby: Color(0xFFA13C43),
    amber: Color(0xFF986A27),
    lime: Color(0xFF65713B),
    orange: Color(0xFFA35E34),
    textPrimary: Color(0xFF1D1D1B),
    textSecondary: Color(0xFF575750),
    textMuted: Color(0xFF78776F),
    posterPlaceholder: Color(0xFFDDD7CB),
  );

  @override
  CineBookColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? accent,
    Color? onAccent,
    Color? gold,
    Color? goldLight,
    Color? cyan,
    Color? purple,
    Color? emerald,
    Color? ruby,
    Color? amber,
    Color? lime,
    Color? orange,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? posterPlaceholder,
  }) {
    return CineBookColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      gold: gold ?? this.gold,
      goldLight: goldLight ?? this.goldLight,
      cyan: cyan ?? this.cyan,
      purple: purple ?? this.purple,
      emerald: emerald ?? this.emerald,
      ruby: ruby ?? this.ruby,
      amber: amber ?? this.amber,
      lime: lime ?? this.lime,
      orange: orange ?? this.orange,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      posterPlaceholder: posterPlaceholder ?? this.posterPlaceholder,
    );
  }

  @override
  CineBookColors lerp(ThemeExtension<CineBookColors>? other, double t) {
    if (other is! CineBookColors) return this;
    return CineBookColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldLight: Color.lerp(goldLight, other.goldLight, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      emerald: Color.lerp(emerald, other.emerald, t)!,
      ruby: Color.lerp(ruby, other.ruby, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      lime: Color.lerp(lime, other.lime, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      posterPlaceholder:
          Color.lerp(posterPlaceholder, other.posterPlaceholder, t)!,
    );
  }
}

extension CineBookThemeContext on BuildContext {
  CineBookColors get cineColors =>
      Theme.of(this).extension<CineBookColors>() ?? CineBookColors.dark;
}

class AppTheme {
  static const String displayFont = 'Bodoni Moda';
  static const String bodyFont = 'DM Sans';

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        colors: CineBookColors.light,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        colors: CineBookColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required CineBookColors colors,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      secondary: colors.cyan,
      onSecondary: brightness == Brightness.dark
          ? const Color(0xFF102024)
          : const Color(0xFFFFFFFF),
      surface: colors.surface,
      onSurface: colors.textPrimary,
      surfaceContainerHighest: colors.surfaceElevated,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.border,
      error: colors.ruby,
      onError: brightness == Brightness.dark
          ? const Color(0xFF251013)
          : const Color(0xFFFFFFFF),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: bodyFont,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      primaryColor: colors.accent,
      visualDensity: VisualDensity.standard,
      extensions: [colors],
    );
    final textTheme = base.textTheme.copyWith(
      displayLarge: TextStyle(
        fontFamily: displayFont,
        fontSize: 52,
        fontWeight: FontWeight.w600,
        height: 1.02,
        letterSpacing: -1.4,
        color: colors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: displayFont,
        fontSize: 40,
        fontWeight: FontWeight.w600,
        height: 1.05,
        letterSpacing: -1,
        color: colors.textPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: displayFont,
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.1,
        letterSpacing: -0.6,
        color: colors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: displayFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.15,
        color: colors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: colors.textSecondary,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        height: 1.5,
        color: colors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 11,
        height: 1.45,
        color: colors.textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: colors.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: colors.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: colors.textMuted,
      ),
    );
    const compactShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    );
    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colors.textSecondary, size: 22),
        actionsIconTheme: IconThemeData(color: colors.textSecondary, size: 22),
        shape: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.border),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        scrimColor: Colors.black.withValues(alpha: 0.45),
        shape: const RoundedRectangleBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceElevated,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        labelStyle: textTheme.bodySmall?.copyWith(color: colors.textMuted),
        prefixIconColor: colors.textMuted,
        suffixIconColor: colors.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.accent, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.ruby),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          disabledBackgroundColor: colors.surfaceElevated,
          disabledForegroundColor: colors.textMuted,
          elevation: 0,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: compactShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          disabledForegroundColor: colors.textMuted,
          side: BorderSide(color: colors.border),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: compactShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          disabledForegroundColor: colors.textMuted,
          shape: compactShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.textSecondary,
          minimumSize: const Size(40, 40),
          shape: compactShape,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceElevated,
        selectedColor: colors.accent,
        disabledColor: colors.surfaceElevated,
        side: BorderSide(color: colors.border),
        shape: compactShape,
        labelStyle: textTheme.bodySmall?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          color: colors.onAccent,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.accent,
        inactiveTrackColor: colors.surfaceElevated,
        thumbColor: colors.accent,
        overlayColor: colors.accent.withValues(alpha: 0.12),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textMuted,
        textColor: colors.textPrimary,
        subtitleTextStyle: textTheme.bodySmall,
        titleTextStyle: textTheme.titleSmall,
        shape: compactShape,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: colors.accent,
        collapsedIconColor: colors.textMuted,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.surfaceElevated,
        circularTrackColor: colors.surfaceElevated,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
        ),
        actionTextColor: colors.goldLight,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.border),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.textPrimary,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(
          fontFamily: bodyFont,
          fontSize: 11,
          color: brightness == Brightness.dark
              ? colors.background
              : colors.surface,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(colors.border),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(5),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.border),
        ),
        textStyle: textTheme.bodyMedium,
      ),
    );
  }
}
