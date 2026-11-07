import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferencesProvider extends ChangeNotifier {
  static const _seedKey = 'theme_seed_color';
  static const _modeKey = 'theme_mode';

  ThemePreferencesProvider({SharedPreferences? preferences})
    : _preferences = preferences;

  SharedPreferences? _preferences;
  Color _seedColor = const Color(0xFF2196F3);
  ThemeMode _themeMode = ThemeMode.system;

  Color get seedColor => _seedColor;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final seed = _preferences!.getInt(_seedKey);
    final mode = _preferences!.getString(_modeKey);
    _seedColor = seed == null ? _seedColor : Color(seed);
    _themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setSeedColor(Color color) async {
    _preferences ??= await SharedPreferences.getInstance();
    _seedColor = color;
    await _preferences!.setInt(_seedKey, color.toARGB32());
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _preferences ??= await SharedPreferences.getInstance();
    _themeMode = mode;
    await _preferences!.setString(_modeKey, mode.name);
    notifyListeners();
  }
}
