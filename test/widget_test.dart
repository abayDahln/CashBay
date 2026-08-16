import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cashbay/app.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('CashBay app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CashBayApp());
    // Wait for staggered animations + async data load
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Total Saldo'), findsOneWidget);
  });
}