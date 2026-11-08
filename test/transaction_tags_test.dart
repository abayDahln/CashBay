import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:cashbay/core/database/app_database.dart';
import 'package:cashbay/features/transactions/data/models/transaction.dart';
import 'package:cashbay/features/transactions/data/repositories/transaction_repository.dart';

/// Exercises the v4 multi-tag work end to end, in one process so the
/// AppDatabase singleton and its on-disk file are never shared across
/// parallel test files (run this file with --concurrency=1).
void main() {
  late String path;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    path = join(await getDatabasesPath(), 'cashbay.db');
    if (File(path).existsSync()) File(path).deleteSync();

    // Seed a v3-shaped database: transactions carry a single category_id.
    // AppDatabase (version 4) will upgrade this on first access below.
    final db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, _) async {
        await db.execute('''CREATE TABLE wallets (
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
          type TEXT NOT NULL, balance REAL NOT NULL DEFAULT 0)''');
        await db.execute('''CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
          type TEXT NOT NULL, icon TEXT,
          is_default INTEGER NOT NULL DEFAULT 0)''');
        await db.execute('''CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL,
          amount REAL NOT NULL, wallet_id INTEGER NOT NULL,
          to_wallet_id INTEGER, category_id INTEGER, note TEXT,
          date TEXT NOT NULL, created_at TEXT NOT NULL, description TEXT,
          payment_method TEXT NOT NULL DEFAULT 'cash', attachment_path TEXT,
          is_deleted INTEGER NOT NULL DEFAULT 0)''');
        await db.insert('wallets', {'name': 'Cash', 'type': 'cash', 'balance': 0.0});
        await db.insert('categories', {'name': 'Makan', 'type': 'expense'});
        await db.insert('transactions', {
          'type': 'expense', 'amount': 25000, 'wallet_id': 1,
          'category_id': 1, 'date': '2026-01-01T00:00:00.000',
          'created_at': '2026-01-01T00:00:00.000',
        });
      },
    );
    await db.close();
  });

  tearDownAll(() async {
    await AppDatabase().close();
    if (File(path).existsSync()) File(path).deleteSync();
  });

  test('v3 data upgrades: category_id becomes a pivot tag', () async {
    final db = await AppDatabase().database;

    final cols = await db.rawQuery('PRAGMA table_info(transactions)');
    expect(cols.any((c) => c['name'] == 'category_id'), isFalse);

    final tags = await db.query('transaction_tags');
    expect(tags, hasLength(1));
    expect(tags.first['transaction_id'], 1);
    expect(tags.first['category_id'], 1);

    final tx = await db.query('transactions');
    expect(tx, hasLength(1));
    expect(tx.first['amount'], 25000);
  });

  test('round-trips multiple tags and filters by a tag', () async {
    final repo = TransactionRepository();

    final id = await repo.insertTransaction(
      Transaction(
        type: 'expense',
        amount: 50000,
        walletId: 1,
        categoryIds: const [1, 2],
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    final id2 = await repo.insertTransaction(
      Transaction(
        type: 'expense',
        amount: 10000,
        walletId: 1,
        categoryIds: const [2],
        date: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 2),
      ),
    );

    final first = (await repo.getAllTransactions()).firstWhere((t) => t.id == id);
    expect(first.categoryIds.toSet(), {1, 2});

    final byTag = await repo.getAllTransactions(categoryId: 2);
    expect(byTag.map((t) => t.id).toSet(), {id, id2});

    final single = await repo.getTransactionById(id2);
    expect(single!.categoryIds, [2]);

    // Replacing tags on update drops the old ones.
    await repo.updateTransaction(first.copyWith(categoryIds: const [3]));
    final updated = await repo.getTransactionById(id);
    expect(updated!.categoryIds, [3]);
  });
}
