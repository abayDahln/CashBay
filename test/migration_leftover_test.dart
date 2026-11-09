import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:cashbay/core/database/app_database.dart';

/// Recovers a database left half-migrated: `transactions` was renamed to
/// `transactions_old` but the rebuild never completed (version still 3).
/// Own file so the AppDatabase singleton starts fresh.
void main() {
  late String path;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    path = join(await getDatabasesPath(), 'cashbay.db');
    if (File(path).existsSync()) File(path).deleteSync();

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
        // Half-migrated shape: live table already renamed, still has the column.
        await db.execute('''CREATE TABLE transactions_old (
          id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL,
          amount REAL NOT NULL, wallet_id INTEGER NOT NULL,
          to_wallet_id INTEGER, category_id INTEGER, note TEXT,
          date TEXT NOT NULL, created_at TEXT NOT NULL, description TEXT,
          payment_method TEXT NOT NULL DEFAULT 'cash', attachment_path TEXT,
          is_deleted INTEGER NOT NULL DEFAULT 0)''');
        await db.insert('wallets', {'name': 'Cash', 'type': 'cash', 'balance': 0.0});
        await db.insert('categories', {'name': 'Makan', 'type': 'expense'});
        await db.insert('transactions_old', {
          'type': 'expense', 'amount': 7500, 'wallet_id': 1, 'category_id': 1,
          'date': '2026-02-01T00:00:00.000',
          'created_at': '2026-02-01T00:00:00.000',
        });
      },
    );
    await db.close();
  });

  tearDownAll(() async {
    await AppDatabase().close();
  });

  test('half-migrated rename is recovered into transactions + tags', () async {
    final db = await AppDatabase().database;

    final tx = await db.query('transactions');
    expect(tx, hasLength(1));
    expect(tx.first['amount'], 7500);

    final tags = await db.query('transaction_tags');
    expect(tags, hasLength(1));
    expect(tags.first['category_id'], 1);

    final leftovers = await db.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type='table' AND name='transactions_old'",
    );
    expect(leftovers, isEmpty);
  });
}
