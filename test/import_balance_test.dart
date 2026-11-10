import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:cashbay/core/database/app_database.dart';
import 'package:cashbay/features/dashboard/data/repositories/wallet_repository.dart';

/// After a backup import the stored wallet balance is 0; recalculating from
/// the imported transactions must restore the correct totals.
void main() {
  late String path;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    path = join(await getDatabasesPath(), 'cashbay.db');
    if (File(path).existsSync()) File(path).deleteSync();
    await AppDatabase().database;
  });

  tearDownAll(() async {
    await AppDatabase().close();
  });

  test('recalculateAllBalances fixes a zeroed imported wallet', () async {
    final db = await AppDatabase().database;

    // Simulate an imported backup: wallets with balance 0 plus real rows.
    await db.delete('transaction_tags');
    await db.delete('debt_payments');
    await db.delete('debts');
    await db.delete('transactions');
    await db.delete('wallets');
    await db.insert('wallets', {'id': 1, 'name': 'Cash', 'type': 'cash', 'balance': 0.0});
    await db.insert('wallets', {'id': 2, 'name': 'E-Wallet', 'type': 'ewallet', 'balance': 0.0});

    Future<void> tx(String type, double amount, int walletId, {int? to, int titipan = 0}) =>
        db.insert('transactions', {
          'type': type,
          'amount': amount,
          'wallet_id': walletId,
          'to_wallet_id': to,
          'date': '2026-11-01T00:00:00.000',
          'created_at': '2026-11-01T00:00:00.000',
          'payment_method': 'cash',
          'is_deleted': 0,
          'is_titipan': titipan,
        });

    await tx('income', 1000000, 1);            // +1.000.000
    await tx('expense', 250000, 1);            // -250.000
    await tx('transfer', 100000, 1, to: 2);    // -100.000 / +100.000
    await tx('income', 50000, 2);              // +50.000
    await tx('expense', 30000, 1, titipan: 1); // titipan, still moves balance

    await WalletRepository().recalculateAllBalances();

    final balances = {
      for (final w in await WalletRepository().getAllWallets()) w.id: w.balance,
    };
    expect(balances[1], 1000000 - 250000 - 100000 - 30000);
    expect(balances[2], 100000 + 50000);
  });
}
