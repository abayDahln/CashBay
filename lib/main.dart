import 'dart:io' show Platform, File, Directory;
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
    final newDir = p.join(dir.path, 'databases');
    await databaseFactory.setDatabasesPath(newDir);

    // One-time migration: an older build stored the database under the project
    // `.dart_tool` folder. If the new location has no database yet, move the
    // old one over so existing data is not lost.
    final newDb = File(p.join(newDir, 'cashbay.db'));
    final oldDb = File(
      p.join(
        Directory.current.path,
        '.dart_tool',
        'sqflite_common_ffi',
        'databases',
        'cashbay.db',
      ),
    );
    if (!newDb.existsSync() && oldDb.existsSync()) {
      newDb.parent.createSync(recursive: true);
      oldDb.copySync(newDb.path);
    }
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
