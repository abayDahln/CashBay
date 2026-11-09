import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:cashbay/core/database/app_database.dart';

/// Reproduces the emulator/Windows failure: a database left at version 3 whose
/// `transactions` table already dropped `category_id` (e.g. a version bump was
/// never persisted, or a prior migration half-ran). The v4 migration must not
/// crash on `SELECT category_id FROM transactions_old`.
void main() {
  late String path;

  Future<void> seedV3WithoutCategoryId() async {
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
        // No category_id column here — this is the already-tagged shape.
        await db.execute('''CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL,
          amount REAL NOT NULL, wallet_id INTEGER NOT NULL,
          to_wallet_id INTEGER, note TEXT,
          date TEXT NOT NULL, created_at TEXT NOT NULL, description TEXT,
          payment_method TEXT NOT NULL DEFAULT 'cash', attachment_path TEXT,
          is_deleted INTEGER NOT NULL DEFAULT 0)''');
        await db.insert('wallets', {'name': 'Cash', 'type': 'cash', 'balance': 0.0});
        await db.insert('transactions', {
          'type': 'expense', 'amount': 7500, 'wallet_id': 1,
          'date': '2026-02-01T00:00:00.000',
          'created_at': '2026-02-01T00:00:00.000',
        });
      },
    );
    await db.close();
  }

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    path = join(await getDatabasesPath(), 'cashbay.db');
  });

  tearDown(() async {
    await AppDatabase().close();
    if (File(path).existsSync()) File(path).deleteSync();
  });

  test('v3 db without category_id upgrades without error', () async {
    if (File(path).existsSync()) File(path).deleteSync();
    await seedV3WithoutCategoryId();

    final db = await AppDatabase().database;
    final tx = await db.query('transactions');
    expect(tx, hasLength(1));
    expect(tx.first['amount'], 7500);
    // No tags were possible, and no crash occurred.
    expect(await db.query('transaction_tags'), isEmpty);
  });
}
