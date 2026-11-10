import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/debt.dart';
import '../../../transactions/presentation/screens/add_transaction_screen.dart';
import '../../../dashboard/presentation/providers/wallet_provider.dart';
import '../providers/debt_provider.dart';
import 'debt_detail_screen.dart';

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

  bool get _hasFilter => _statusFilter != 'all' || _dateRange != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
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

  void _resetFilter() => setState(() {
    _statusFilter = 'all';
    _dateRange = null;
  });

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final textTheme = Theme.of(context).textTheme;
          void update(VoidCallback fn) {
            setSheetState(fn);
            setState(() {});
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter', style: textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('Status', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in const [
                      ('Semua', 'all'),
                      ('Belum Lunas', 'active'),
                      ('Lunas', 'paid'),
                    ])
                      ChoiceChip(
                        label: Text(option.$1),
                        selected: _statusFilter == option.$2,
                        onSelected: (_) =>
                            update(() => _statusFilter = option.$2),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Rentang Tanggal', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(now.year + 10, 12, 31),
                            initialDateRange: _dateRange,
                            helpText: 'Pilih rentang tanggal',
                          );
                          if (range != null) {
                            update(() => _dateRange = range);
                          }
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _dateRange != null
                              ? '${DateFormatter.formatShortDate(_dateRange!.start)} - ${DateFormatter.formatShortDate(_dateRange!.end)}'
                              : 'Pilih tanggal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_dateRange != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Hapus filter tanggal',
                        onPressed: () => update(() => _dateRange = null),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _hasFilter
                            ? () => update(() {
                                _statusFilter = 'all';
                                _dateRange = null;
                              })
                            : null,
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Terapkan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
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
      filtered = filtered
          .where(
            (d) =>
                d.date.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                d.date.isBefore(_dateRange!.end.add(const Duration(days: 1))),
          )
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CashBayAppBar(
        title: 'Titipan',
        actions: [
          IconButton(
            tooltip: 'Filter titipan',
            isSelected: _hasFilter,
            icon: Badge(
              isLabelVisible: _hasFilter,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.arrow_upward), text: 'Titipan Saya'),
            Tab(icon: Icon(Icons.arrow_downward), text: 'Titipan Orang'),
          ],
        ),
      ),
      body: Consumer<DebtProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading &&
              provider.debts.isEmpty &&
              provider.receivables.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildDebtList(provider.debts, 'debt', provider.totalActiveDebt),
              _buildDebtList(
                provider.receivables,
                'receivable',
                provider.totalActiveReceivable,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah titipan',
        onPressed: () =>
            _openAddTitipan(_tabController.index == 0 ? 'debt' : 'receivable'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDebtList(List<Debt> all, String type, double totalActive) {
    final debts = _filterDebts(all);
    final groups = _groupByDate(debts);
    final activeCount = all.where((d) => d.status == 'active').length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom padding keeps the last card clear of the FAB.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _buildSummaryCard(type, totalActive, activeCount),
          const SizedBox(height: 16),
          if (debts.isEmpty)
            _buildEmptyState(type, filtered: all.isNotEmpty)
          else
            for (final group in groups) ...[
              _buildSectionHeader(group.label, group.debts.length),
              const SizedBox(height: 8),
              for (final debt in group.debts) ...[
                _buildDebtTile(debt),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String type, double total, int activeCount) {
    final isDebt = type == 'debt';
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDebt ? Icons.arrow_upward : Icons.arrow_downward,
                size: 20,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDebt ? 'Sisa titipan saya' : 'Sisa titipan orang',
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(total),
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activeCount == 0
                ? 'Tidak ada titipan belum lunas'
                : '$activeCount titipan belum lunas',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
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
    if (thisWeekList.isNotEmpty) {
      groups.add(_DateGroup('Minggu Ini', thisWeekList));
    }
    if (thisMonthList.isNotEmpty) {
      groups.add(_DateGroup('Bulan Ini', thisMonthList));
    }
    if (earlierList.isNotEmpty) {
      groups.add(_DateGroup('Sebelumnya', earlierList));
    }
    return groups;
  }

  Widget _buildEmptyState(String type, {required bool filtered}) {
    if (filtered) {
      return EmptyState(
        icon: Icons.filter_list_off,
        message: 'Tidak ada titipan yang cocok',
        subtitle: 'Coba ubah atau reset filter',
        buttonLabel: 'Reset Filter',
        buttonIcon: Icons.restart_alt,
        onButtonTap: _resetFilter,
      );
    }
    final isDebt = type == 'debt';
    return EmptyState(
      icon: isDebt ? Icons.receipt_long_outlined : Icons.people_outline,
      message: isDebt ? 'Belum ada titipan' : 'Belum ada titipan orang',
      subtitle: isDebt
          ? 'Catat uang yang Anda titipkan ke orang lain'
          : 'Catat uang orang lain yang Anda pegang',
      buttonLabel: isDebt ? 'Tambah Titipan' : 'Tambah Titipan Orang',
      onButtonTap: () => _openAddTitipan(isDebt ? 'debt' : 'receivable'),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Badge(
          label: Text('$count'),
          backgroundColor: scheme.secondaryContainer,
          textColor: scheme.onSecondaryContainer,
        ),
      ],
    );
  }

  Widget _buildDebtTile(Debt debt) {
    final isDebt = debt.type == 'debt';
    final isPaid = debt.status == 'paid';
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue =
        !isPaid &&
        debt.dueDate != null &&
        DateTime(debt.dueDate!.year, debt.dueDate!.month, debt.dueDate!.day)
            .isBefore(today);
    final subtitle = debt.dueDate != null
        ? DateFormatter.formatDate(debt.dueDate!)
        : DateFormatter.formatDate(debt.date);
    final paidRatio = debt.amount > 0
        ? ((debt.amount - debt.remainingAmount) / debt.amount).clamp(0.0, 1.0)
        : 0.0;

    return AppCard(
      variant: AppCardVariant.outlined,
      // Overdue titipan get a faint red wash so they stand out in the list.
      color: isOverdue
          ? Color.alphaBlend(
              scheme.error.withValues(alpha: 0.10),
              scheme.surface,
            )
          : null,
      padding: const EdgeInsets.all(16),
      onTap: () =>
          Navigator.push(context, fadeSlideRoute(DebtDetailScreen(debt: debt))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: const Icon(Icons.receipt_long),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.personName,
                        style: textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: isOverdue
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      CurrencyFormatter.format(debt.remainingAmount),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (debt.amount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: paidRatio,
                    borderRadius: BorderRadius.circular(4),
                    semanticsLabel: 'Progres pembayaran',
                    semanticsValue: '${(paidRatio * 100).round()}%',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(paidRatio * 100).round()}%',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${CurrencyFormatter.format(debt.amount - debt.remainingAmount)} ${isDebt ? 'dibayar' : 'diterima'} dari ${CurrencyFormatter.format(debt.amount)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isPaid) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Lunas',
                    style: textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Opens the shared add-transaction screen on the Titipan tab, matching the
  /// selected list ("Titipan Saya" -> debt, "Titipan Orang" -> receivable).
  Future<void> _openAddTitipan(String direction) async {
    final saved = await Navigator.push(
      context,
      fadeSlideRoute(
        AddTransactionScreen(
          initialType: 'tagihan',
          initialDebtDirection: direction,
        ),
      ),
    );
    if (saved == true && mounted) {
      await context.read<DebtProvider>().loadAllDebts();
      if (!mounted) return;
      await context.read<WalletProvider>().refreshBalances();
    }
  }
}

/// Tonal status label ("Lunas" / "Belum Lunas") shared by the debt list and detail.
class DebtStatusBadge extends StatelessWidget {
  final bool isPaid;
  const DebtStatusBadge({super.key, required this.isPaid});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Badge(
      label: Text(isPaid ? 'Lunas' : 'Belum Lunas'),
      largeSize: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: Theme.of(context).textTheme.labelSmall,
      backgroundColor: isPaid
          ? scheme.primaryContainer
          : scheme.tertiaryContainer,
      textColor: isPaid
          ? scheme.onPrimaryContainer
          : scheme.onTertiaryContainer,
    );
  }
}

class _DateGroup {
  final String label;
  final List<Debt> debts;
  _DateGroup(this.label, this.debts);
}
