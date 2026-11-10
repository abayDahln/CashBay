import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:cashbay/core/database/app_database.dart';
import 'package:cashbay/features/dashboard/data/repositories/wallet_repository.dart';
import 'package:cashbay/features/transactions/data/models/transaction.dart';
import 'package:cashbay/features/transactions/presentation/providers/transaction_provider.dart';

/// A transfer must move money: source wallet down, destination wallet up.
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

  test('transfer takes from source and gives to destination', () async {
    final provider = TransactionProvider();

    // Fund the source wallet so we can see it drop.
    await provider.addTransaction(
      Transaction(
        type: 'income',
        amount: 100000,
        walletId: 1,
        date: DateTime(2026, 5, 1),
        createdAt: DateTime(2026, 5, 1),
      ),
    );

    final cashBefore = await balance(1);
    final ewalletBefore = await balance(2);

    final ok = await provider.addTransaction(
      Transaction(
        type: 'transfer',
        amount: 40000,
        walletId: 1,
        toWalletId: 2,
        date: DateTime(2026, 5, 2),
        createdAt: DateTime(2026, 5, 2),
      ),
    );
    expect(ok, isTrue);

    expect(await balance(1), cashBefore - 40000);
    expect(await balance(2), ewalletBefore + 40000);
  });
}
