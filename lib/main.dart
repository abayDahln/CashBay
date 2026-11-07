import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/theme/theme_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  final preferences = await SharedPreferences.getInstance();
  final themePreferences = ThemePreferencesProvider(preferences: preferences);
  await themePreferences.load();
  runApp(CashBayApp(themePreferences: themePreferences));
}
