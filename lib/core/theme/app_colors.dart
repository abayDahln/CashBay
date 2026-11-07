import 'package:flutter/material.dart';

/// Design tokens shared by every screen. Dark values are taken verbatim from
/// the UI mockups in `ui/`; light values are the closest iOS-style counterpart.
class AppColors {
  // Semantic — expense / income
  static const Color expense = Color(0xFFFF5447);
  static const Color income = Color(0xFF34C759);
  static const Color transfer = Color(0xFF3E90FF);

  final Color background;
  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceBright;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color tertiaryContainer;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceBright,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.error,
    required this.errorContainer,
    required this.onErrorContainer,
  });

  /// Palette from the `ui/*.html` mockups.
  static const AppColors dark = AppColors(
    background: Color(0xFF121317),
    surface: Color(0xFF121317),
    surfaceContainerLowest: Color(0xFF0D0E12),
    surfaceContainerLow: Color(0xFF1A1B1F),
    surfaceContainer: Color(0xFF1E1F23),
    surfaceContainerHigh: Color(0xFF292A2E),
    surfaceContainerHighest: Color(0xFF343539),
    surfaceBright: Color(0xFF38393D),
    onSurface: Color(0xFFE3E2E7),
    onSurfaceVariant: Color(0xFFC0C6D6),
    outline: Color(0xFF8B91A0),
    outlineVariant: Color(0xFF414754),
    primary: Color(0xFFAAC7FF),
    primaryContainer: Color(0xFF3E90FF),
    onPrimaryContainer: Color(0xFF002957),
    secondary: Color(0xFF47E266),
    secondaryContainer: Color(0xFF09BF49),
    onSecondaryContainer: Color(0xFF004615),
    tertiary: Color(0xFFFFB4AA),
    tertiaryContainer: Color(0xFFFF5447),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
  );

  /// Light counterpart keeping the same roles / iOS feel.
  static const AppColors light = AppColors(
    background: Color(0xFFF7F8FA),
    surface: Color(0xFFF7F8FA),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHigh: Color(0xFFF0F1F4),
    surfaceContainerHighest: Color(0xFFE7E8EC),
    surfaceBright: Color(0xFFF0F1F4),
    onSurface: Color(0xFF1A1B1F),
    onSurfaceVariant: Color(0xFF5A5F6B),
    outline: Color(0xFF8B91A0),
    outlineVariant: Color(0xFFD9DBE1),
    primary: Color(0xFF2E6BD6),
    primaryContainer: Color(0xFF2E6BD6),
    onPrimaryContainer: Color(0xFFD6E3FF),
    secondary: Color(0xFF14913C),
    secondaryContainer: Color(0xFF47E266),
    onSecondaryContainer: Color(0xFF002106),
    tertiary: Color(0xFFD33F36),
    tertiaryContainer: Color(0xFFFF5447),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// iOS-flavoured type scale from the mockups (headline / body / caption …).
class AppTypography {
  const AppTypography._();

  static const String family = 'SF Pro Display';

  static const TextStyle largeTitle = TextStyle(
    fontFamily: family,
    fontSize: 34,
    height: 41 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const TextStyle headlineLargeMobile = TextStyle(
    fontFamily: family,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  static const TextStyle title1 = TextStyle(
    fontFamily: family,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const TextStyle title2 = TextStyle(
    fontFamily: family,
    fontSize: 20,
    height: 25 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const TextStyle headline = TextStyle(
    fontFamily: family,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle callout = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 21 / 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle subheadline = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle footnote = TextStyle(
    fontFamily: family,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption1 = TextStyle(
    fontFamily: family,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption2 = TextStyle(
    fontFamily: family,
    fontSize: 11,
    height: 13 / 11,
    fontWeight: FontWeight.w500,
  );
}
