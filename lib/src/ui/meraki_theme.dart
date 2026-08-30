import 'package:flutter/material.dart';

abstract final class MerakiColors {
  /// Base shared by the scaffold and main player surface.
  static const Color deepPurple = Color(0xFF000000);
  static const Color sidebar = Color(0xFF0F0F0F);
  static const Color panel = Color(0xFF121212);
  static const Color softText = Color(0xFFB3B3B3);
  static const Color defaultAccent = Color(0xFF9DBF9E);
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
        onSurface: const Color(0xFFFFFFFF),
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
    appBarTheme: const AppBarTheme(
      backgroundColor: MerakiColors.deepPurple,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: MerakiColors.panel,
      indicatorColor: MerakiColors.defaultAccent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MerakiColors.panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2B2B2B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accent),
      ),
    ),
    filledButtonTheme: const FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(accent),
        foregroundColor: WidgetStatePropertyAll(MerakiColors.deepPurple),
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
