import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:cashbay/core/database/app_database.dart';
import 'package:cashbay/features/report/presentation/providers/report_provider.dart';
import 'package:cashbay/features/transactions/data/models/transaction.dart';
import 'package:cashbay/features/transactions/data/repositories/transaction_repository.dart';

/// Covers the Analytics chart: per-year view where only months that have data
/// appear (no zero bars), series toggled between income and expense, and year
/// navigation limited to years that hold data.
void main() {
  late String path;
  final repo = TransactionRepository();
  final provider = ReportProvider();

  Future<void> seed(String type, double amount, DateTime date) =>
      repo.insertTransaction(
        Transaction(
          type: type,
          amount: amount,
          walletId: 1,
          date: date,
          createdAt: date,
        ),
      );

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('id_ID', null);
    path = join(await getDatabasesPath(), 'cashbay.db');
    if (File(path).existsSync()) File(path).deleteSync();
    await AppDatabase().database;

    final thisYear = DateTime.now().year;
    // Two months in the current year (Mar + Jul), nothing in between.
    await seed('income', 110, DateTime(thisYear, 3, 5));
    await seed('expense', 40, DateTime(thisYear, 3, 5));
    await seed('income', 200, DateTime(thisYear, 7, 1));
    // An earlier year with a single expense.
    await seed('expense', 7, DateTime(thisYear - 2, 6, 1));
  });

  tearDownAll(() async {
    await AppDatabase().close();
  });

  test('only months with data appear, no zero bars', () async {
    provider.init(); // starts on the current year
    await provider.loadChartData();

    expect(provider.chartData.length, 2); // Mar + Jul only
    expect(provider.chartData[0].value, 110);
    expect(provider.chartData[1].value, 200);
    expect(provider.total, 310);
  });

  test('default selected month is the latest bar (Jul)', () async {
    provider.setSeries(ChartSeries.income);
    await provider.loadChartData();

    expect(provider.selectedMonth, 7);
    expect(provider.selectedMonthTransactions.length, 1);
    expect(provider.selectedMonthTransactions.first.amount, 200);
  });

  test('selectMonth lists only that month of the active series', () async {
    provider.setSeries(ChartSeries.income);
    await provider.loadChartData();
    provider.selectMonth(DateTime(provider.year, 3));
    expect(provider.selectedMonth, 3);
    expect(provider.selectedMonthTransactions.length, 1);
    expect(provider.selectedMonthTransactions.first.type, 'income');

    provider.setSeries(ChartSeries.expense);
    await provider.loadChartData();
    provider.selectMonth(DateTime(provider.year, 3));
    expect(provider.selectedMonthTransactions.length, 1);
    expect(provider.selectedMonthTransactions.first.type, 'expense');
  });

  test('expense series excludes income', () async {
    provider.setSeries(ChartSeries.expense);
    await provider.loadChartData();

    expect(provider.chartData.length, 1); // only Mar has expense
    expect(provider.chartData.first.value, 40);
    expect(provider.total, 40);
  });

  test('shiftYear only reaches years that have data', () async {
    provider.setSeries(ChartSeries.income);
    await provider.loadChartData();
    final thisYear = DateTime.now().year;
    expect(provider.year, thisYear);
    expect(provider.canGoNext, isFalse); // never past the current year
    expect(provider.canGoPrevious, isTrue);

    provider.shiftYear(-1); // no data the year before
    await provider.loadChartData();
    expect(provider.year, thisYear - 1);
    expect(provider.chartData, isEmpty);
    expect(provider.totalIncome, 0);

    provider.shiftYear(-1); // reaches the year with data
    await provider.loadChartData();
    expect(provider.year, thisYear - 2);
    expect(provider.canGoPrevious, isFalse);

    provider.setSeries(ChartSeries.expense);
    await provider.loadChartData();
    expect(provider.chartData.length, 1);
    expect(provider.totalExpense, 7);
    expect(provider.total, 7);
  });
}
