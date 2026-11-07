import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cashbay/core/theme/app_theme.dart';
import 'package:cashbay/core/theme/theme_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates light and dark Material 3 schemes from a seed', () {
    const seed = Color(0xFF2E7D32);
    final light = AppTheme.lightThemeFor(seed);
    final dark = AppTheme.darkThemeFor(seed);

    expect(light.useMaterial3, isTrue);
    expect(dark.useMaterial3, isTrue);
    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
    expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
  });

  test('persists selected seed and theme mode', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final provider = ThemePreferencesProvider(preferences: preferences);

    await provider.setSeedColor(const Color(0xFFD32F2F));
    await provider.setThemeMode(ThemeMode.dark);

    final restored = ThemePreferencesProvider(
      preferences: await SharedPreferences.getInstance(),
    );
    await restored.load();

    expect(restored.seedColor, const Color(0xFFD32F2F));
    expect(restored.themeMode, ThemeMode.dark);
  });
}
