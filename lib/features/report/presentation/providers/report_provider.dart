import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';

/// Which series the chart shows.
enum ChartSeries { income, expense }

class ChartBarData {
  final String label;
  final double value;
  final DateTime? date;
  ChartBarData(this.label, this.value, {this.date});
}

class ReportProvider extends ChangeNotifier {
  final TransactionRepository _txRepo = TransactionRepository();

  ChartSeries _series = ChartSeries.income;
  int _year = DateTime.now().year;
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<ChartBarData> _chartData = [];
  Map<int, List<Transaction>> _byMonthTx = {};
  int? _selectedMonth;
  List<Transaction> _selectedTx = [];
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
  int? get selectedMonth => _selectedMonth;
  List<Transaction> get selectedMonthTransactions => _selectedTx;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      final byMonth = <int, double>{};
      for (final tx in real) {
        if (tx.type == 'income') {
          _totalIncome += tx.amount;
        } else if (tx.type == 'expense') {
          _totalExpense += tx.amount;
        } else {
          continue; // transfers are not income/expense
        }
        if ((tx.type == 'income') != (_series == ChartSeries.income)) continue;
        byMonth.update(tx.date.month, (v) => v + tx.amount, ifAbsent: () => tx.amount);
      }

      final months = byMonth.keys.toList()..sort();
      _chartData = [
        for (final m in months)
          ChartBarData(
            DateFormat('MMM', 'id_ID').format(DateTime(_year, m)),
            byMonth[m]!,
            date: DateTime(_year, m),
          ),
      ];
      // Group the series' transactions per month for the detail list.
      _byMonthTx = {};
      for (final tx in real) {
        if ((tx.type == 'income') != (_series == ChartSeries.income)) continue;
        (_byMonthTx[tx.date.month] ??= []).add(tx);
      }
      // Default selection = the latest month shown on the chart.
      final defaultMonth = months.isEmpty ? null : months.last;
      if (_selectedMonth == null || !months.contains(_selectedMonth)) {
        _selectedMonth = defaultMonth;
      }
      _selectedTx = _selectedMonth == null
          ? []
          : (_byMonthTx[_selectedMonth!] ?? [])
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _chartData = [];
      _selectedTx = [];
      _selectedMonth = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selects the month whose bar was tapped and lists its transactions.
  void selectMonth(DateTime month) {
    _selectedMonth = month.month;
    final list = (_byMonthTx[month.month] ?? []).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _selectedTx = list;
    notifyListeners();
  }
}
