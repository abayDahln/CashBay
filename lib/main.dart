import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/theme/locale_provider.dart';
import 'core/theme/theme_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // sqflite has no native backend on desktop; wire the FFI factory there. FFI
  // resolves a relative databases path against the current working directory,
  // which changes between desktop runs (so data appeared to reset). Pin the
  // databases directory to an absolute, per-app location instead.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await getApplicationSupportDirectory();
    await databaseFactory.setDatabasesPath(
      p.join(dir.path, 'databases'),
    );
  }
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);
  await NotificationService.instance.init();
  final preferences = await SharedPreferences.getInstance();
  final themePreferences = ThemePreferencesProvider(preferences: preferences);
  final localeProvider = LocaleProvider(preferences: preferences);
  await themePreferences.load();
  await localeProvider.load();
  runApp(
    CashBayApp(
      themePreferences: themePreferences,
      localeProvider: localeProvider,
    ),
  );
}
