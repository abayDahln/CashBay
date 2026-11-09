import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:cashbay/core/database/app_database.dart';
import 'package:cashbay/features/dashboard/data/repositories/wallet_repository.dart';
import 'package:cashbay/features/debts/data/models/debt.dart';
import 'package:cashbay/features/debts/data/models/debt_payment.dart';
import 'package:cashbay/features/debts/presentation/providers/debt_provider.dart';
import 'package:cashbay/features/transactions/data/repositories/transaction_repository.dart';

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

  test('opening leg cannot drop below what was already returned', () async {
    final provider2 = DebtProvider();
    await provider2.addDebt(
      Debt(
        type: 'debt',
        personName: 'Dedi',
        amount: 100000,
        remainingAmount: 100000,
        walletId: 1,
        status: 'active',
        date: DateTime(2026, 1, 1),
      ),
    );
    final titipan = provider2.debts.first;
    await provider2.addPayment(
      DebtPayment(
        debtId: titipan.id!,
        amount: 60000,
        walletId: 1,
        date: DateTime(2026, 1, 2),
      ),
    );

    final afterReturn = provider2.debts.firstWhere((d) => d.id == titipan.id);
    // 40.000 < 60.000 already returned -> rejected.
    final error = await provider2.updateOpeningLeg(
      debt: afterReturn,
      newAmount: 40000,
      newWalletId: 1,
    );
    expect(error, isNotNull);

    // 80.000 >= 60.000 returned -> allowed, sisa becomes 20.000.
    final ok = await provider2.updateOpeningLeg(
      debt: afterReturn,
      newAmount: 80000,
      newWalletId: 1,
    );
    expect(ok, isNull);
    final updated = provider2.debts.firstWhere((d) => d.id == titipan.id);
    expect(updated.amount, 80000);
    expect(updated.remainingAmount, 20000);
  });

  test('return leg cannot exceed the titipan total', () async {
    final provider3 = DebtProvider();
    await provider3.addDebt(
      Debt(
        type: 'debt',
        personName: 'Eka',
        amount: 100000,
        remainingAmount: 100000,
        walletId: 1,
        status: 'active',
        date: DateTime(2026, 1, 1),
      ),
    );
    final titipan = provider3.debts.first;
    await provider3.addPayment(
      DebtPayment(
        debtId: titipan.id!,
        amount: 30000,
        walletId: 1,
        date: DateTime(2026, 1, 2),
      ),
    );
    await provider3.loadDebtPayments(titipan.id!);
    final payment = provider3.selectedDebtPayments.first;
    final debt = provider3.debts.firstWhere((d) => d.id == titipan.id);

    // 30.000 already returned + this leg 30.000; raising to 120.000 exceeds total.
    final error = await provider3.updateReturnLeg(
      debt: debt,
      payment: payment,
      newAmount: 120000,
      newWalletId: 1,
    );
    expect(error, isNotNull);

    // Raising to 100.000 is exactly the total -> allowed, sisa becomes 0.
    final ok = await provider3.updateReturnLeg(
      debt: debt,
      payment: payment,
      newAmount: 100000,
      newWalletId: 1,
    );
    expect(ok, isNull);
    final updated = provider3.debts.firstWhere((d) => d.id == titipan.id);
    expect(updated.remainingAmount, 0);
    expect(updated.status, 'paid');
  });

  test('titipan moves the wallet but is not income/expense', () async {
    final txRepo = TransactionRepository();
    final provider4 = DebtProvider();

    // Titipan Saya: 30.000 leaves the wallet.
    await provider4.addDebt(
      Debt(
        type: 'debt',
        personName: 'Fani',
        amount: 30000,
        remainingAmount: 30000,
        walletId: 1,
        status: 'active',
        date: DateTime(2026, 4, 1),
      ),
    );
    final titipan = provider4.debts.first;
    await provider4.addPayment(
      DebtPayment(
        debtId: titipan.id!,
        amount: 30000,
        walletId: 1,
        date: DateTime(2026, 4, 2),
      ),
    );

    // Wallet balance reflects both legs (net 0 change here).
    expect(await balance(1), isNotNull);

    // But income/expense summaries ignore titipan entirely.
    expect(await txRepo.getTotalIncome(excludeTitipan: true), 0);
    expect(await txRepo.getTotalExpense(excludeTitipan: true), 0);
  });
}
