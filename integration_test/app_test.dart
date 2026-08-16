import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cashbay/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('id_ID', null);
  });

  group('CashBay — Smoke Test', () {
    testWidgets('dashboard renders all cards', (tester) async {
      await tester.pumpWidget(const CashBayApp());
      await tester.pumpAndSettle();

      expect(find.text('Total Saldo'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('E-Wallet'), findsOneWidget);
      expect(find.text('Tagihan Saya'), findsOneWidget);
      expect(find.text('Tagihan Orang'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
    });

    testWidgets('dashboard shows recent transactions section', (tester) async {
      await tester.pumpWidget(const CashBayApp());
      await tester.pumpAndSettle();

      expect(find.text('Transaksi Terbaru'), findsOneWidget);
    });

    testWidgets('bottom navigation: Riwayat tab', (tester) async {
      await tester.pumpWidget(const CashBayApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Riwayat'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Riwayat Transaksi'), findsOneWidget);
    });

    testWidgets('bottom navigation: back to Dashboard', (tester) async {
      await tester.pumpWidget(const CashBayApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Riwayat'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Transaksi Terbaru'), findsOneWidget);
    });

    testWidgets('FAB opens Add Transaction screen', (tester) async {
      await tester.pumpWidget(const CashBayApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Tambah Transaksi'), findsOneWidget);
    });

    testWidgets('settings screen opens from app bar', (tester) async {
      await tester.pumpWidget(const CashBayApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Hapus Semua Data'), findsOneWidget);
    });

    testWidgets('tagihan saya card navigates to debts', (tester) async {
      await tester.pumpWidget(const CashBayApp());
      await tester.pumpAndSettle();

      // "Tagihan Saya" appears in both the card and the bottom nav;
      // use a more specific finder for the card section
      final tagihanSayaCards = find.text('Tagihan Saya');
      // There should be at least the card widget
      await tester.tap(tagihanSayaCards.last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Tagihan'), findsWidgets);
    });

    testWidgets('type selector on add screen works', (tester) async {
      await tester.pumpWidget(const CashBayApp());
      await tester.pumpAndSettle();

      // Open add transaction
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Type selector should show 4 options
      expect(find.text('Pendapatan'), findsWidgets);
      expect(find.text('Pengeluaran'), findsWidgets);
      expect(find.text('Tagihan'), findsWidgets);
      expect(find.text('Transfer'), findsWidgets);
    });
  });
}
