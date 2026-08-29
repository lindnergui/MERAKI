import 'package:flutter/material.dart';

abstract final class MerakiColors {
  /// Base shared by the scaffold, desktop sidebar and content panels.
  static const Color deepPurple = Color(0xFF341539);
  static const Color sidebar = Color(0xFF341539);
  static const Color panel = Color(0xFF341539);
  static const Color softText = Color(0xFFBEB6CC);
  static const Color defaultAccent = Color(0xFFCBC3E3);
}

ThemeData buildMerakiTheme() {
  const accent = MerakiColors.defaultAccent;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: accent,
        primaryContainer: accent,
        secondary: accent,
        secondaryContainer: accent,
        tertiary: accent,
        tertiaryContainer: accent,
        onPrimary: MerakiColors.deepPurple,
        onPrimaryContainer: MerakiColors.deepPurple,
        onSecondary: MerakiColors.deepPurple,
        onSecondaryContainer: MerakiColors.deepPurple,
        onTertiary: MerakiColors.deepPurple,
        onTertiaryContainer: MerakiColors.deepPurple,
        surface: MerakiColors.deepPurple,
        surfaceContainer: MerakiColors.panel,
        surfaceContainerHigh: MerakiColors.panel,
        onSurface: const Color(0xFFF6F1FA),
        onSurfaceVariant: MerakiColors.softText,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: MerakiColors.deepPurple,
    fontFamily: 'sans-serif',
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    dividerColor: Colors.white.withValues(alpha: 0.08),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accent.withValues(alpha: 0.85)),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accent,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
      thumbColor: accent,
      overlayColor: accent.withValues(alpha: 0.16),
    ),
  );
}
