import 'package:flutter/foundation.dart' hide Category;
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/repositories/category_repository.dart';

enum ChartMode { daily, monthly, yearly }

class ChartBarData {
  final String label;
  final double netBalance;
  final DateTime? date;
  ChartBarData(this.label, this.netBalance, {this.date});
}

class CategorySummary {
  final String name;
  final String? icon;
  final double amount;
  final double percentage;
  CategorySummary(this.name, this.icon, this.amount, this.percentage);
}

class ReportProvider extends ChangeNotifier {
  final TransactionRepository _txRepo = TransactionRepository();
  final CategoryRepository _catRepo = CategoryRepository();

  ChartMode _chartMode = ChartMode.monthly;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalTransferOut = 0;
  double _totalTransferIn = 0;
  List<ChartBarData> _chartData = [];
  List<CategorySummary> _incomeCategories = [];
  List<CategorySummary> _expenseCategories = [];
  List<Transaction> _recentTransactions = [];
  bool _isLoading = false;
  String? _error;

  ChartMode get chartMode => _chartMode;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get totalTransferOut => _totalTransferOut;
  double get totalTransferIn => _totalTransferIn;
  double get balance => _totalIncome - _totalExpense - _totalTransferOut + _totalTransferIn;
  List<ChartBarData> get chartData => _chartData;
  List<CategorySummary> get incomeCategories => _incomeCategories;
  List<CategorySummary> get expenseCategories => _expenseCategories;
  List<Transaction> get recentTransactions => _recentTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<int> get availableYears {
    final now = DateTime.now().year;
    return List.generate(now - 2019, (i) => 2020 + i);
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

  Future<void> loadChartData() async {
    DateTime start, end;
    switch (_chartMode) {
      case ChartMode.daily:
        start = DateTime(_selectedYear, _selectedMonth, 1);
        end = DateTime(_selectedYear, _selectedMonth + 1, 1);
        break;
      case ChartMode.monthly:
        start = DateTime(_selectedYear, 1, 1);
        end = DateTime(_selectedYear + 1, 1, 1);
        break;
      case ChartMode.yearly:
        start = DateTime(2000, 1, 1);
        end = DateTime(2100, 1, 1);
        break;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cats = await _catRepo.getAllCategories();
      final catMap = <int, Category>{};
      for (final c in cats) {
        if (c.id != null) catMap[c.id!] = c;
      }

      final txs = await _txRepo.getAllTransactions(startDate: start, endDate: end);
      _computeChartData(txs);
      _computeSummaries(txs, catMap);
    } catch (e) {
      _chartData = [];
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _computeChartData(List<Transaction> txs) {
    final Map<String, double> netByKey = {};

    for (final tx in txs) {
      String key;
      switch (_chartMode) {
        case ChartMode.daily:
          key = tx.date.day.toString();
          break;
        case ChartMode.monthly:
          key = tx.date.month.toString();
          break;
        case ChartMode.yearly:
          key = tx.date.year.toString();
          break;
      }

      double amount;
      if (tx.type == 'income') {
        amount = tx.amount.toDouble();
      } else if (tx.type == 'expense') {
        amount = -tx.amount.toDouble();
      } else {
        amount = 0.0;
      }
      netByKey.update(key, (v) => v + amount, ifAbsent: () => amount);
    }

    final sortedKeys = netByKey.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    _chartData = sortedKeys.map((key) {
      String label;
      DateTime? date;
      switch (_chartMode) {
        case ChartMode.daily:
          label = key;
          date = DateTime(_selectedYear, _selectedMonth, int.parse(key));
          break;
        case ChartMode.monthly:
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
          label = months[int.parse(key) - 1];
          date = DateTime(_selectedYear, int.parse(key));
          break;
        case ChartMode.yearly:
          label = key;
          date = DateTime(int.parse(key));
          break;
      }
      return ChartBarData(label, netByKey[key]!, date: date);
    }).toList();
  }

  void _computeSummaries(List<Transaction> txs, Map<int, Category> categories) {
    _totalIncome = 0;
    _totalExpense = 0;
    _totalTransferOut = 0;
    _totalTransferIn = 0;

    final incomeByCategory = <int?, double>{};
    final expenseByCategory = <int?, double>{};

    for (final tx in txs) {
      switch (tx.type) {
        case 'income':
          _totalIncome += tx.amount;
          incomeByCategory.update(tx.categoryId, (v) => v + tx.amount, ifAbsent: () => tx.amount);
        case 'expense':
          _totalExpense += tx.amount;
          expenseByCategory.update(tx.categoryId, (v) => v + tx.amount, ifAbsent: () => tx.amount);
        case 'transfer':
          _totalTransferOut += tx.amount;
      }
    }

    final totalInc = _totalIncome;
    _incomeCategories = incomeByCategory.entries
      .map((e) {
        final cat = e.key != null ? categories[e.key] : null;
        return CategorySummary(
          cat?.name ?? 'Tanpa Kategori',
          cat?.icon,
          e.value,
          totalInc > 0 ? (e.value / totalInc * 100) : 0,
        );
      })
      .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalExp = _totalExpense;
    _expenseCategories = expenseByCategory.entries
      .map((e) {
        final cat = e.key != null ? categories[e.key] : null;
        return CategorySummary(
          cat?.name ?? 'Tanpa Kategori',
          cat?.icon,
          e.value,
          totalExp > 0 ? (e.value / totalExp * 100) : 0,
        );
      })
      .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    _recentTransactions = txs
      .where((t) => t.type == 'income' || t.type == 'expense')
      .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (_recentTransactions.length > 5) {
      _recentTransactions = _recentTransactions.sublist(0, 5);
    }
  }
}
