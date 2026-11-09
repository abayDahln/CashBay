import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:cashbay/core/database/app_database.dart';
import 'package:cashbay/features/dashboard/data/repositories/wallet_repository.dart';
import 'package:cashbay/features/debts/data/models/debt.dart';
import 'package:cashbay/features/debts/data/models/debt_payment.dart';
import 'package:cashbay/features/debts/presentation/providers/debt_provider.dart';

/// Verifies the two-leg titipan money model against the live wallet balance.
/// Run with --concurrency=1: it uses the shared on-disk AppDatabase file.
void main() {
  late String path;
  final wallets = WalletRepository();
  final provider = DebtProvider();

  Future<double> balance(int id) async {
    final w = (await wallets.getAllWallets()).firstWhere((w) => w.id == id);
    return w.balance;
  }

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    path = join(await getDatabasesPath(), 'cashbay.db');
    if (File(path).existsSync()) File(path).deleteSync();
    await AppDatabase().database; // create the schema
  });

  tearDownAll(() async {
    await AppDatabase().close();
  });

  test('Titipan Saya: opening leg lowers my balance, return restores it', () async {
    final start = await balance(1);

    await provider.addDebt(
      Debt(
        type: 'debt',
        personName: 'Budi',
        amount: 100000,
        remainingAmount: 100000,
        walletId: 1,
        status: 'active',
        date: DateTime(2026, 1, 1),
      ),
    );
    expect(await balance(1), start - 100000);

    final titipan = provider.debts.first;
    await provider.addPayment(
      DebtPayment(
        debtId: titipan.id!,
        amount: 100000,
        walletId: 1,
        date: DateTime(2026, 1, 2),
      ),
    );
    expect(await balance(1), start);
    expect(await provider.deleteDebt(titipan.id!), isTrue);
    expect(await balance(1), start);
  });

  test('Titipan Orang: opening leg raises my balance, return lowers it', () async {
    final start = await balance(2);

    await provider.addDebt(
      Debt(
        type: 'receivable',
        personName: 'Ani',
        amount: 40000,
        remainingAmount: 40000,
        walletId: 2,
        status: 'active',
        date: DateTime(2026, 1, 1),
      ),
    );
    expect(await balance(2), start + 40000);

    final titipan = provider.receivables.first;
    await provider.addPayment(
      DebtPayment(
        debtId: titipan.id!,
        amount: 40000,
        walletId: 2,
        date: DateTime(2026, 1, 2),
      ),
    );
    expect(await balance(2), start);
    expect(await provider.deleteDebt(titipan.id!), isTrue);
    expect(await balance(2), start);
  });

  test('partial repayment keeps an active remainder', () async {
    final start = await balance(1);
    await provider.addDebt(
      Debt(
        type: 'debt',
        personName: 'Cici',
        amount: 50000,
        remainingAmount: 50000,
        walletId: 1,
        status: 'active',
        date: DateTime(2026, 1, 1),
      ),
    );
    final titipan = provider.debts.first;
    await provider.addPayment(
      DebtPayment(
        debtId: titipan.id!,
        amount: 20000,
        walletId: 1,
        date: DateTime(2026, 1, 2),
      ),
    );
    final updated = provider.debts.firstWhere((d) => d.id == titipan.id);
    expect(updated.remainingAmount, 30000);
    expect(updated.status, 'active');
    expect(await balance(1), start - 30000);
  });
}
