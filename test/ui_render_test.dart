import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cashbay/app.dart';
import 'package:cashbay/core/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('app renders all four navigation tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CashBayApp());
    await tester.pump(const Duration(seconds: 2));

    // Locale-independent: four destinations in the navigation bar.
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    // Switch to each tab and make sure it renders without throwing.
    final destinations = find.byType(NavigationDestination);
    for (var i = 1; i < 4; i++) {
      await tester.tap(destinations.at(i));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    }
  });

  test('both themes use SF Pro Display', () {
    expect(AppTheme.darkTheme.appBarTheme.titleTextStyle?.fontFamily,
        'SF Pro Display');
    expect(AppTheme.lightTheme.appBarTheme.titleTextStyle?.fontFamily,
        'SF Pro Display');
    expect(AppTheme.darkTheme.textTheme.bodyMedium?.fontFamily,
        'SF Pro Display');
    expect(AppTheme.lightTheme.textTheme.headlineMedium?.fontFamily,
        'SF Pro Display');
  });

  test('add-transaction form no longer asks for a category', () {
    // Sanity: the field was removed from the form source.
    final source = File(
      'lib/features/transactions/presentation/screens/add_transaction_screen.dart',
    ).readAsStringSync();
    expect(source.contains("labelText: 'Kategori'"), isFalse);
    expect(source.contains('_categoryController'), isFalse);
  });
}
