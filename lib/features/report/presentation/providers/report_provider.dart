import 'package:flutter/foundation.dart' hide Category;
import 'package:intl/intl.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';

enum ChartMode { month, year }

/// Granularity of the chart bars, derived from mode + whether a custom range
/// is active.
enum ChartBucket { day, month, year }

class ChartBarData {
  final String label;
  final double netBalance;
  final DateTime? date;
  ChartBarData(this.label, this.netBalance, {this.date});
}

class ReportProvider extends ChangeNotifier {
  final TransactionRepository _txRepo = TransactionRepository();

  static const int maxRangeMonths = 12;

  ChartMode _chartMode = ChartMode.month;

  // Default (single) period.
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // Month custom range (inclusive), null = not custom.
  DateTime? _monthRangeStart;
  DateTime? _monthRangeEnd;

  // Year custom range (inclusive), null = not custom.
  int? _yearRangeStart;
  int? _yearRangeEnd;

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalTransferOut = 0;
  double _totalTransferIn = 0;
  List<ChartBarData> _chartData = [];
  List<Transaction> _recentTransactions = [];
  bool _isLoading = false;
  String? _error;

  ChartMode get chartMode => _chartMode;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  bool get isMonthCustom => _monthRangeStart != null && _monthRangeEnd != null;
  bool get isYearCustom => _yearRangeStart != null && _yearRangeEnd != null;
  DateTime? get monthRangeStart => _monthRangeStart;
  DateTime? get monthRangeEnd => _monthRangeEnd;
  int? get yearRangeStart => _yearRangeStart;
  int? get yearRangeEnd => _yearRangeEnd;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get totalTransferOut => _totalTransferOut;
  double get totalTransferIn => _totalTransferIn;
  double get balance =>
      _totalIncome - _totalExpense - _totalTransferOut + _totalTransferIn;
  List<ChartBarData> get chartData => _chartData;
  List<Transaction> get recentTransactions => _recentTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<int> get availableYears {
    final now = DateTime.now().year;
    return List.generate(now - 2010 + 1, (i) => 2010 + i);
  }

  void init() {
    loadChartData();
  }

  void setChartMode(ChartMode mode) {
    _chartMode = mode;
    loadChartData();
  }

  void setYear(int year) {
    _selectedYear = year;
    loadChartData();
  }

  void setMonth(int month) {
    _selectedMonth = month;
    loadChartData();
  }

  /// Number of months in an inclusive start..end month range.
  static int monthsBetween(DateTime start, DateTime end) =>
      (end.year - start.year) * 12 + (end.month - start.month) + 1;

  /// Sets a custom month range (start/end month inclusive). The end must be
  /// at or after the start and span at most [maxRangeMonths] months.
  void setMonthRange(DateTime start, DateTime end) {
    _monthRangeStart = DateTime(start.year, start.month);
    _monthRangeEnd = DateTime(end.year, end.month);
    loadChartData();
  }

  void clearMonthRange() {
    _monthRangeStart = null;
    _monthRangeEnd = null;
    loadChartData();
  }

  /// Sets a custom year range (inclusive), at most [maxRangeMonths] years.
  void setYearRange(int start, int end) {
    _yearRangeStart = start;
    _yearRangeEnd = end;
    loadChartData();
  }

  void clearYearRange() {
    _yearRangeStart = null;
    _yearRangeEnd = null;
    loadChartData();
  }

  /// Moves the active period one step back/forward for the current mode.
  /// Only applies to the default (non-custom) period.
  void shiftPeriod(int delta) {
    switch (_chartMode) {
      case ChartMode.month:
        if (isMonthCustom) return;
        final shifted = DateTime(_selectedYear, _selectedMonth + delta);
        _selectedYear = shifted.year;
        _selectedMonth = shifted.month;
      case ChartMode.year:
        if (isYearCustom) return;
        _selectedYear += delta;
    }
    loadChartData();
  }

  /// The active date window `[start, end)`.
  ({DateTime start, DateTime end}) get _window {
    switch (_chartMode) {
      case ChartMode.month:
        if (isMonthCustom) {
          return (
            start: DateTime(_monthRangeStart!.year, _monthRangeStart!.month, 1),
            end: DateTime(_monthRangeEnd!.year, _monthRangeEnd!.month + 1, 1),
          );
        }
        return (
          start: DateTime(_selectedYear, _selectedMonth, 1),
          end: DateTime(_selectedYear, _selectedMonth + 1, 1),
        );
      case ChartMode.year:
        if (isYearCustom) {
          return (
            start: DateTime(_yearRangeStart!, 1, 1),
            end: DateTime(_yearRangeEnd! + 1, 1, 1),
          );
        }
        return (
          start: DateTime(_selectedYear, 1, 1),
          end: DateTime(_selectedYear + 1, 1, 1),
        );
    }
  }

  /// Bar granularity for the current mode + custom state.
  ChartBucket get chartBucket {
    switch (_chartMode) {
      case ChartMode.month:
        return isMonthCustom ? ChartBucket.month : ChartBucket.day;
      case ChartMode.year:
        return isYearCustom ? ChartBucket.year : ChartBucket.month;
    }
  }

  Future<void> loadChartData() async {
    final w = _window;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // `_window.end` is exclusive; the repository compares inclusively.
      final endInclusive = w.end.subtract(const Duration(microseconds: 1));
      final txs = await _txRepo.getAllTransactions(
        startDate: w.start,
        endDate: endInclusive,
      );
      // Titipan moves the wallet but is not real income/expense, so it is
      // excluded from the chart and the period totals.
      final real = txs.where((t) => !t.isTitipan).toList();
      _computeChartData(real);
      _computeSummaries(real, recent: txs);
    } catch (e) {
      _chartData = [];
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _computeChartData(List<Transaction> txs) {
    final bucket = chartBucket;
    final Map<DateTime, double> netByKey = {};

    DateTime keyOf(DateTime d) => switch (bucket) {
      ChartBucket.day => DateTime(d.year, d.month, d.day),
      ChartBucket.month => DateTime(d.year, d.month),
      ChartBucket.year => DateTime(d.year),
    };

    for (final tx in txs) {
      final amount = tx.type == 'income'
          ? tx.amount.toDouble()
          : tx.type == 'expense'
          ? -tx.amount.toDouble()
          : 0.0;
      final key = keyOf(tx.date);
      netByKey.update(key, (v) => v + amount, ifAbsent: () => amount);
    }

    final sortedKeys = netByKey.keys.toList()..sort();
    _chartData = sortedKeys.map((key) {
      final String label;
      switch (bucket) {
        case ChartBucket.day:
          label = key.day.toString();
        case ChartBucket.month:
          label = DateFormat('MMM', 'id_ID').format(key);
        case ChartBucket.year:
          label = key.year.toString();
      }
      return ChartBarData(label, netByKey[key]!, date: key);
    }).toList();
  }

  void _computeSummaries(
    List<Transaction> txs, {
    List<Transaction>? recent,
  }) {
    _totalIncome = 0;
    _totalExpense = 0;
    _totalTransferOut = 0;
    _totalTransferIn = 0;

    for (final tx in txs) {
      switch (tx.type) {
        case 'income':
          _totalIncome += tx.amount;
        case 'expense':
          _totalExpense += tx.amount;
        case 'transfer':
          _totalTransferOut += tx.amount;
      }
    }

    _recentTransactions = (recent ?? txs)
        .where((t) => t.type == 'income' || t.type == 'expense')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (_recentTransactions.length > 5) {
      _recentTransactions = _recentTransactions.sublist(0, 5);
    }
  }
}
