import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the chosen UI language and exposes it as a [Locale].
///
/// `null` means "follow the system language"; supported values are `id` and
/// `en`. Strings are resolved by [L] (generated from the .arb files).
class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';
  static const supported = <Locale>[Locale('id'), Locale('en')];

  LocaleProvider({SharedPreferences? preferences})
    : _preferences = preferences;

  SharedPreferences? _preferences;
  Locale? _locale;

  /// `null` = follow the system.
  Locale? get locale => _locale;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final code = _preferences!.getString(_key);
    _locale = code == null ? null : Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _preferences ??= await SharedPreferences.getInstance();
    _locale = locale;
    if (locale == null) {
      await _preferences!.remove(_key);
    } else {
      await _preferences!.setString(_key, locale.languageCode);
    }
    notifyListeners();
  }
}
