import 'package:flutter/foundation.dart' hide Category;
import '../../../transactions/data/repositories/transaction_repository.dart';

/// Which series the chart shows.
enum ChartSeries { income, expense }

class ChartBarData {
  final double value;
  /// Opposing type's value in the same month, drawn as a shadow behind the bar.
  final double shadowValue;
  final DateTime date;
  ChartBarData(this.value, {this.shadowValue = 0, required this.date});
}

class ReportProvider extends ChangeNotifier {
  final TransactionRepository _txRepo = TransactionRepository();

  ChartSeries _series = ChartSeries.income;
  int _year = DateTime.now().year;
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<ChartBarData> _chartData = [];
  double _maxValue = 0;
  int _expenseMonths = 0;
  DateTime? _firstTxDate;
  bool _isLoading = false;
  String? _error;

  ChartSeries get series => _series;
  int get year => _year;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get total =>
      _series == ChartSeries.income ? _totalIncome : _totalExpense;
  List<ChartBarData> get chartData => _chartData;
  /// Highest single month value across both income and expense, so the Y axis
  /// (and its gridlines) stays the same in either tab.
  double get maxValue => _maxValue;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ---- Year metrics ----

  /// Arus Kas Bersih / Laba Bersih: income - expense for the selected year.
  double get netCashFlow => _totalIncome - _totalExpense;

  /// Tingkat Pembakaran Dana: average monthly expense over the months that
  /// actually had spending (0 when there was none).
  double get burnRate => _expenseMonths == 0 ? 0 : _totalExpense / _expenseMonths;

  /// Rasio Tabungan / Margin Laba: (net cash flow / income) * 100, as a
  /// percentage. 0 when there is no income.
  double get savingsRate =>
      _totalIncome == 0 ? 0 : (netCashFlow / _totalIncome) * 100;

  /// Rasio Pengeluaran: (expense / income) * 100. 0 when there is no income.
  double get expenseRatio =>
      _totalIncome == 0 ? 0 : (_totalExpense / _totalIncome) * 100;

  int get _firstYear => _firstTxDate?.year ?? DateTime.now().year;
  int get _lastYear => DateTime.now().year;

  /// Any earlier year to step back to?
  bool get canGoPrevious => _year > _firstYear;
  /// Any later year to step forward to (never past the current year)?
  bool get canGoNext => _year < _lastYear;

  void init() {
    loadChartData();
  }

  void setSeries(ChartSeries series) {
    _series = series;
    loadChartData();
  }

  /// Moves the selected year one step, clamped to [first data year, now].
  void shiftYear(int delta) {
    final next = _year + delta;
    if (next < _firstYear || next > _lastYear) return;
    _year = next;
    loadChartData();
  }

  /// Loads the real (non-titipan) transactions of the selected year, bucketed
  /// by month. Months without data are omitted so the chart wastes no space.
  Future<void> loadChartData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _firstTxDate = await _txRepo.getFirstTransactionDate();
      final start = DateTime(_year, 1, 1);
      final end = DateTime(_year + 1, 1, 1);

      final txs = await _txRepo.getAllTransactions(
        startDate: start,
        endDate: end.subtract(const Duration(microseconds: 1)),
      );
      // Titipan moves the wallet but is not real income/expense.
      final real = txs.where((t) => !t.isTitipan).toList();
      _totalIncome = 0;
      _totalExpense = 0;
      final incomeByMonth = <int, double>{};
      final expenseByMonth = <int, double>{};
      for (final tx in real) {
        if (tx.type == 'income') {
          _totalIncome += tx.amount;
          incomeByMonth.update(
            tx.date.month,
            (v) => v + tx.amount,
            ifAbsent: () => tx.amount,
          );
        } else if (tx.type == 'expense') {
          _totalExpense += tx.amount;
          expenseByMonth.update(
            tx.date.month,
            (v) => v + tx.amount,
            ifAbsent: () => tx.amount,
          );
        }
        // transfers are not income/expense
      }

      final isIncome = _series == ChartSeries.income;
      final front = isIncome ? incomeByMonth : expenseByMonth;
      final back = isIncome ? expenseByMonth : incomeByMonth;
      // Show every month that has data in either type, so a month whose
      // opposing bar is present still appears (with its shadow).
      final months = <int>{...incomeByMonth.keys, ...expenseByMonth.keys}.toList()
        ..sort();
      _chartData = [
        for (final m in months)
          ChartBarData(
            front[m] ?? 0,
            shadowValue: back[m] ?? 0,
            date: DateTime(_year, m),
          ),
      ];
      // Y axis spans both types so the gridlines don't move between tabs.
      _maxValue = 0;
      for (final m in months) {
        final hi = incomeByMonth[m] ?? 0;
        final ex = expenseByMonth[m] ?? 0;
        final mMax = hi > ex ? hi : ex;
        if (mMax > _maxValue) _maxValue = mMax;
      }
      _expenseMonths = expenseByMonth.length;
    } catch (e) {
      _chartData = [];
      _expenseMonths = 0;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
