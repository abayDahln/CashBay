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

  test('both types per month: front value + opposing shadow', () async {
    provider.setSeries(ChartSeries.income);
    await provider.loadChartData();

    // Mar: income 110 (front), expense 40 (shadow). Jul: income 200, no expense.
    final mar = provider.chartData.firstWhere((d) => d.date.month == 3);
    expect(mar.value, 110);
    expect(mar.shadowValue, 40);
    final jul = provider.chartData.firstWhere((d) => d.date.month == 7);
    expect(jul.value, 200);
    expect(jul.shadowValue, 0);

    // Y axis spans both types: Mar+Jul income is 200, Mar expense 40 -> 200.
    expect(provider.maxValue, 200);
    expect(provider.total, 310);
  });

  test('expense tab shows the same months, income as shadow', () async {
    provider.setSeries(ChartSeries.expense);
    await provider.loadChartData();

    // Both Mar and Jul appear (Jul has only income -> value 0, shadow 200).
    expect(provider.chartData.length, 2);
    final mar = provider.chartData.firstWhere((d) => d.date.month == 3);
    expect(mar.value, 40);
    expect(mar.shadowValue, 110);
    final jul = provider.chartData.firstWhere((d) => d.date.month == 7);
    expect(jul.value, 0);
    expect(jul.shadowValue, 200);
    expect(provider.total, 40);
    // Axis max is identical to the income tab.
    expect(provider.maxValue, 200);
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

  test('year metrics: burn rate, net cash flow, ratios', () async {
    // Back to the current year (income 310, expense 40, only Mar has expense).
    provider.shiftYear(2);
    provider.setSeries(ChartSeries.income);
    await provider.loadChartData();

    expect(provider.netCashFlow, 270); // 310 - 40
    expect(provider.burnRate, 40); // one month with expense -> 40 / 1
    expect(provider.savingsRate, closeTo(270 / 310 * 100, 0.001));
    expect(provider.expenseRatio, closeTo(40 / 310 * 100, 0.001));
  });

  test('ratios are 0 when there is no income', () async {
    // Earlier year only has an expense (no income).
    provider.shiftYear(-2);
    await provider.loadChartData();

    expect(provider.totalIncome, 0);
    expect(provider.savingsRate, 0);
    expect(provider.expenseRatio, 0);
    expect(provider.netCashFlow, -7);
    expect(provider.burnRate, 7);
  });
}
