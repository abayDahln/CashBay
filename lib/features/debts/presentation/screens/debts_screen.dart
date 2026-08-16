import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/debt.dart';
import '../providers/debt_provider.dart';
import 'add_debt_screen.dart';

class DebtsScreen extends StatefulWidget {
  final int initialTab;
  const DebtsScreen({super.key, this.initialTab = 0});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _statusFilter = 'all';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<DebtProvider>().loadAllDebts();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AppCard(
                radius: const BorderRadius.all(Radius.circular(20)),
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('Semua', 'all', _statusFilter, (v) {
                    setSheetState(() => _statusFilter = v);
                    setState(() {});
                  }),
                  _buildFilterChip('Aktif', 'active', _statusFilter, (v) {
                    setSheetState(() => _statusFilter = v);
                    setState(() {});
                  }),
                  _buildFilterChip('Lunas', 'paid', _statusFilter, (v) {
                    setSheetState(() => _statusFilter = v);
                    setState(() {});
                  }),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Rentang Tanggal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _dateRange,
                  );
                  if (range != null) {
                    setSheetState(() => _dateRange = range);
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  _dateRange != null
                      ? '${DateFormat('dd/MM/yy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yy').format(_dateRange!.end)}'
                      : 'Pilih tanggal',
                ),
              ),
              if (_dateRange != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setSheetState(() => _dateRange = null);
                    setState(() {});
                  },
                  child: const Text('Hapus filter tanggal'),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Terapkan'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current, Function(String) onSelected) {
    final selected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppTheme.black.withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected ? AppTheme.black : null,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
    );
  }

  List<Debt> _filterDebts(List<Debt> debts) {
    var filtered = debts;
    if (_statusFilter == 'active') {
      filtered = filtered.where((d) => d.status == 'active').toList();
    } else if (_statusFilter == 'paid') {
      filtered = filtered.where((d) => d.status == 'paid').toList();
    }
    if (_dateRange != null) {
      filtered = filtered.where((d) =>
          d.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
          d.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CashBayAppBar(
        title: 'Tagihan',
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _statusFilter != 'all' || _dateRange != null
                  ? AppTheme.black
                  : null,
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: AppCard(
        radius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(child: _tabButton('Tagihan Saya', Icons.arrow_upward, 0)),
                  const SizedBox(width: 12),
                  Expanded(child: _tabButton('Tagihan Orang', Icons.arrow_downward, 1)),
                ],
              ),
            ),
            Expanded(
              child: Consumer<DebtProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDebtList(_filterDebts(provider.debts), 'debt', provider),
                      _buildDebtList(_filterDebts(provider.receivables), 'receivable', provider),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _tabButton(String label, IconData icon, int index) {
    final selected = _tabController.index == index;
    return InkWell(
      onTap: () => setState(() => _tabController.animateTo(index)),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppTheme.black : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? AppTheme.black.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppTheme.black : Colors.grey[600], size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: selected ? AppTheme.black : Colors.grey[700],
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtList(
    List<Debt> debts,
    String type,
    DebtProvider provider,
  ) {
    if (debts.isEmpty) {
      return _buildEmptyState(type);
    }

    final groups = _groupByDate(debts);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final group in groups) ...[
            _buildSectionHeader(group.label, group.debts.length, type),
            const SizedBox(height: 8),
            ...group.debts.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(bottom: entry.key < group.debts.length - 1 ? 8 : 0),
                    child: _buildDebtTile(entry.value, type, provider),
                  ),
                ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  List<_DateGroup> _groupByDate(List<Debt> debts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    List<Debt> todayList = [];
    List<Debt> thisWeekList = [];
    List<Debt> thisMonthList = [];
    List<Debt> earlierList = [];

    for (final debt in debts) {
      final d = DateTime(debt.date.year, debt.date.month, debt.date.day);
      if (d == today) {
        todayList.add(debt);
      } else if (d.isAfter(thisWeekStart.subtract(const Duration(days: 1)))) {
        thisWeekList.add(debt);
      } else if (d.isAfter(thisMonthStart.subtract(const Duration(days: 1)))) {
        thisMonthList.add(debt);
      } else {
        earlierList.add(debt);
      }
    }

    final groups = <_DateGroup>[];
    if (todayList.isNotEmpty) groups.add(_DateGroup('Hari Ini', todayList));
    if (thisWeekList.isNotEmpty) groups.add(_DateGroup('Minggu Ini', thisWeekList));
    if (thisMonthList.isNotEmpty) groups.add(_DateGroup('Bulan Ini', thisMonthList));
    if (earlierList.isNotEmpty) groups.add(_DateGroup('Sebelumnya', earlierList));
    return groups;
  }

  Widget _buildEmptyState(String type) {
    final isDebt = type == 'debt';
    return EmptyState(
      icon: isDebt ? Icons.account_balance_wallet : Icons.people,
      message: isDebt ? 'Belum ada tagihan' : 'Belum ada tagihan orang',
      subtitle: isDebt
          ? 'Catat tagihan yang Anda pinjam dari orang lain'
          : 'Catat uang yang Anda pinjamkan ke orang lain',
      buttonLabel: isDebt ? 'Tambah Tagihan' : 'Tambah Tagihan Orang',
      onButtonTap: _showAddDebtDialog,
    );
  }

  Widget _buildSectionHeader(String title, int count, String type) {
    final isDebt = type == 'debt';
    final color = isDebt ? AppTheme.black : AppTheme.darkGray;

    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebtTile(Debt debt, String type, DebtProvider provider) {
    final isDebt = type == 'debt';
    final color = isDebt ? AppTheme.black : AppTheme.darkGray;

    return PressCard(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDebt ? Icons.receipt_long : Icons.file_download,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.billName?.isNotEmpty == true
                        ? debt.billName!
                        : debt.personName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (debt.personName.isNotEmpty &&
                      debt.billName?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        debt.personName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatDate(debt.date),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Lunas',
                style: TextStyle(
                  color: AppTheme.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDebtDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => AddDebtScreen(
          initialType: _tabController.index == 0 ? 'debt' : 'receivable',
        ),
      ),
    );
  }
}

class _DateGroup {
  final String label;
  final List<Debt> debts;
  _DateGroup(this.label, this.debts);
}
