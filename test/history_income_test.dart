import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:cashbay/core/database/app_database.dart';
import 'package:cashbay/features/transactions/data/models/transaction.dart';
import 'package:cashbay/features/transactions/data/repositories/transaction_repository.dart';

/// A plain income (including the "Uang Masuk" default description) must be
/// returned by the repository and NOT be treated as titipan-related, so the
/// history list shows it.
void main() {
  late String path;
  final repo = TransactionRepository();

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

  test('income with default description appears in history', () async {
    await repo.insertTransaction(
      Transaction(
        type: 'income',
        amount: 50000,
        walletId: 1,
        description: 'Uang Masuk',
        date: DateTime(2026, 11, 14),
        createdAt: DateTime(2026, 11, 14),
      ),
    );

    final all = await repo.getAllTransactions();
    final found = all.where((t) => t.description == 'Uang Masuk').toList();
    expect(found, hasLength(1));
    expect(found.single.type, 'income');
    // Not titipan-related, so it survives the history filter.
    expect(found.single.isTagihanRelated, isFalse);
  });
}
