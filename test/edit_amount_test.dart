import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:cashbay/core/database/app_database.dart';
import 'package:cashbay/features/dashboard/data/repositories/wallet_repository.dart';
import 'package:cashbay/features/transactions/data/models/transaction.dart';
import 'package:cashbay/features/transactions/presentation/providers/transaction_provider.dart';

/// Editing a transaction's amount must move the wallet balance accordingly,
/// even when the wallet is unchanged.
void main() {
  late String path;
  final wallets = WalletRepository();

  Future<double> balance(int id) async =>
      (await wallets.getAllWallets()).firstWhere((w) => w.id == id).balance;

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

  test('raising an income amount raises the wallet balance', () async {
    final provider = TransactionProvider();
    await provider.addTransaction(
      Transaction(
        type: 'income',
        amount: 100000,
        walletId: 1,
        date: DateTime(2026, 3, 1),
        createdAt: DateTime(2026, 3, 1),
      ),
    );
    expect(await balance(1), 100000);

    final tx = provider.transactions.first;
    final ok = await provider.updateTransaction(
      tx.copyWith(amount: 250000),
    );
    expect(ok, isTrue);
    expect(await balance(1), 250000);
  });

  test('moving a transaction to another wallet shifts both balances', () async {
    final provider = TransactionProvider();
    await provider.addTransaction(
      Transaction(
        type: 'expense',
        amount: 40000,
        walletId: 1,
        date: DateTime(2026, 3, 2),
        createdAt: DateTime(2026, 3, 2),
      ),
    );
    final before1 = await balance(1);
    final before2 = await balance(2);
    expect(before1, 250000 - 40000);

    final tx = provider.transactions.first;
    final ok = await provider.updateTransaction(tx.copyWith(walletId: 2));
    expect(ok, isTrue);
    expect(await balance(1), before1 + 40000);
    expect(await balance(2), before2 - 40000);
  });
}
