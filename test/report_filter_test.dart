import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:cashbay/core/database/app_database.dart';
import 'package:cashbay/features/report/presentation/providers/report_provider.dart';
import 'package:cashbay/features/transactions/data/models/transaction.dart';
import 'package:cashbay/features/transactions/data/repositories/transaction_repository.dart';

/// Covers the simplified Analytics time filter: month default (per day),
/// month custom (per month), year default (per month Jan–Dec) and year custom
/// (per year), plus the 12-unit cap.
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

    // Two days in Mar 2026, plus months in 2025 and a year 2020.
    await seed('income', 100, DateTime(2026, 3, 5));
    await seed('expense', 40, DateTime(2026, 3, 5));
    await seed('income', 10, DateTime(2026, 3, 20));
    await seed('income', 200, DateTime(2026, 7, 1));
    await seed('income', 5, DateTime(2025, 12, 31));
    await seed('expense', 7, DateTime(2020, 6, 1));
  });

  tearDownAll(() async {
    await AppDatabase().close();
  });

  test('month default buckets per day and sums the whole month', () async {
    provider.setChartMode(ChartMode.month);
    provider.setYear(2026);
    provider.setMonth(3);
    await provider.loadChartData();

    // Bars are per-day: 5th (100-40=60) and 20th (10).
    expect(provider.chartBucket, ChartBucket.day);
    expect(provider.chartData.length, 2);
    expect(provider.totalIncome, 110);
    expect(provider.totalExpense, 40);
  });

  test('month custom buckets per month across the range', () async {
    provider.setMonthRange(DateTime(2026, 3), DateTime(2026, 7));
    await provider.loadChartData();

    expect(provider.chartBucket, ChartBucket.month);
    // Mar and Jul have data => two bars.
    expect(provider.chartData.length, 2);
    expect(provider.totalIncome, 310); // 110 + 200
    expect(provider.totalExpense, 40);
  });

  test('year default buckets per month (Jan–Dec)', () async {
    provider.clearMonthRange();
    provider.setChartMode(ChartMode.year);
    provider.setYear(2026);
    await provider.loadChartData();

    expect(provider.chartBucket, ChartBucket.month);
    // Mar and Jul => two bars.
    expect(provider.chartData.length, 2);
    expect(provider.totalIncome, 310);
  });

  test('year custom buckets per year across the range', () async {
    provider.setYearRange(2020, 2026);
    await provider.loadChartData();

    expect(provider.chartBucket, ChartBucket.year);
    // 2020, 2025, 2026 have data => three bars.
    expect(provider.chartData.length, 3);
    expect(provider.totalExpense, 47); // 40 + 7
  });

  test('range cap is 12 units', () {
    expect(
      ReportProvider.monthsBetween(DateTime(2026, 1), DateTime(2026, 12)),
      12,
    );
    expect(
      ReportProvider.monthsBetween(DateTime(2026, 1), DateTime(2026, 12)),
      lessThanOrEqualTo(ReportProvider.maxRangeMonths),
    );
  });

  test('mode switch preserves each mode custom state', () async {
    // Year is custom (2020–2026) from the previous test; switch to month and
    // back, custom must persist.
    provider.setChartMode(ChartMode.month);
    await provider.loadChartData();
    provider.setChartMode(ChartMode.year);
    await provider.loadChartData();

    expect(provider.isYearCustom, isTrue);
    expect(provider.chartBucket, ChartBucket.year);
  });

  test('clearing custom ranges returns to the default bucket', () {
    provider.setChartMode(ChartMode.month);
    provider.setMonthRange(DateTime(2026, 3), DateTime(2026, 7));
    expect(provider.isMonthCustom, isTrue);
    expect(provider.chartBucket, ChartBucket.month);
    provider.clearMonthRange();
    expect(provider.isMonthCustom, isFalse);
    expect(provider.chartBucket, ChartBucket.day);

    provider.setChartMode(ChartMode.year);
    provider.setYearRange(2020, 2026);
    expect(provider.isYearCustom, isTrue);
    expect(provider.chartBucket, ChartBucket.year);
    provider.clearYearRange();
    expect(provider.isYearCustom, isFalse);
    expect(provider.chartBucket, ChartBucket.month);
  });
}
