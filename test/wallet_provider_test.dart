import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:cashbay/core/database/app_database.dart';
import 'package:cashbay/features/dashboard/presentation/providers/wallet_provider.dart';

/// The default-wallet guard must not create duplicates when called while the
/// in-memory list is still empty, and must clean up duplicates already there.
void main() {
  late String path;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    path = join(await getDatabasesPath(), 'cashbay.db');
    if (File(path).existsSync()) File(path).deleteSync();
  });

  tearDownAll(() async {
    await AppDatabase().close();
  });

  test('ensureDefaultWallets does not duplicate existing wallets', () async {
    final provider = WalletProvider();
    await provider.ensureDefaultWallets();
    await provider.ensureDefaultWallets();

    expect(provider.wallets.where((w) => w.type == 'cash'), hasLength(1));
    expect(provider.wallets.where((w) => w.type == 'ewallet'), hasLength(1));
  });

  test('ensureDefaultWallets removes duplicates', () async {
    final db = await AppDatabase().database;
    await db.insert('wallets', {'name': 'Cash', 'type': 'cash', 'balance': 0.0});
    await db.insert('wallets', {'name': 'Cash', 'type': 'cash', 'balance': 0.0});

    final provider = WalletProvider();
    await provider.ensureDefaultWallets();

    expect(provider.wallets.where((w) => w.type == 'cash'), hasLength(1));
    expect(provider.wallets.where((w) => w.type == 'ewallet'), hasLength(1));
  });
}
