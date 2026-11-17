import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
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
          final t = L.of(context);
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
                Text(t.filter, style: textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(t.status, style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in [
                      (t.all, 'all'),
                      (t.belumLunas, 'active'),
                      (t.lunas, 'paid'),
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
                Text(t.dateRange, style: textTheme.titleSmall),
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
                            helpText: t.chooseDateRange,
                          );
                          if (range != null) {
                            update(() => _dateRange = range);
                          }
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _dateRange != null
                              ? '${DateFormatter.formatShortDate(_dateRange!.start)} - ${DateFormatter.formatShortDate(_dateRange!.end)}'
                              : t.chooseDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_dateRange != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: t.clearDateFilter,
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
                        child: Text(t.reset),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(t.apply),
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
    final t = L.of(context);
    return Scaffold(
      appBar: CashBayAppBar(
        title: t.titipan,
        actions: [
          IconButton(
            tooltip: t.filterTitipan,
            isSelected: _hasFilter,
            icon: Badge(
              isLabelVisible: _hasFilter,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: PreferredSize(
          // M3 tab with an icon stacked above its label: 72dp.
          preferredSize: const Size.fromHeight(72),
          child: Consumer<DebtProvider>(
            builder: (context, provider, _) {
              final debtActive = provider.debts
                  .where((d) => d.status == 'active')
                  .length;
              final receivableActive = provider.receivables
                  .where((d) => d.status == 'active')
                  .length;
              return TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: _tabIcon(Icons.arrow_upward, debtActive),
                    text: t.titipanSaya,
                  ),
                  Tab(
                    icon: _tabIcon(Icons.arrow_downward, receivableActive),
                    text: t.titipanOrang,
                  ),
                ],
              );
            },
          ),
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
        tooltip: t.addTitipan,
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
    final t = L.of(context);
    final isDebt = type == 'debt';
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final finance = FinanceColors.of(context);
    final accent = finance.titipan;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _accentIcon(
                isDebt ? Icons.arrow_upward : Icons.arrow_downward,
                accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isDebt ? t.remainingTitipanSaya : t.remainingTitipanOrang,
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: NominalText(
              amount: total,
              symbolColor: accent,
              style: textTheme.headlineMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activeCount == 0
                ? t.noActiveTitipan
                : t.activeTitipanCount(activeCount),
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Tab icon badged with the number of still-unpaid titipan, so a pending
  /// titipan is visible even while the other tab is selected. Follows the M3
  /// badge spec: error-role container, top-end offset over the anchor icon.
  Widget _tabIcon(IconData icon, int activeCount) => Badge.count(
    count: activeCount,
    isLabelVisible: activeCount > 0,
    smallSize: 16,
    largeSize: 16,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    offset: const Offset(6, -6),
    textStyle: Theme.of(context).textTheme.labelSmall,
    child: Icon(icon),
  );

  /// 40dp ringed avatar matching the transaction tiles.
  Widget _accentIcon(IconData icon, Color accent) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: accent.withValues(alpha: 0.06),
      border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
    ),
    child: Icon(icon, size: 20, color: accent),
  );

  List<_DateGroup> _groupByDate(List<Debt> debts) {
    final t = L.of(context);
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
    if (todayList.isNotEmpty) groups.add(_DateGroup(t.today, todayList));
    if (thisWeekList.isNotEmpty) {
      groups.add(_DateGroup(t.thisWeek, thisWeekList));
    }
    if (thisMonthList.isNotEmpty) {
      groups.add(_DateGroup(t.thisMonth, thisMonthList));
    }
    if (earlierList.isNotEmpty) {
      groups.add(_DateGroup(t.previous, earlierList));
    }
    return groups;
  }

  Widget _buildEmptyState(String type, {required bool filtered}) {
    final t = L.of(context);
    if (filtered) {
      return EmptyState(
        icon: Icons.filter_list_off,
        message: t.noTitipanMatch,
        subtitle: t.changeOrResetFilter,
        buttonLabel: t.resetFilter,
        buttonIcon: Icons.restart_alt,
        onButtonTap: _resetFilter,
      );
    }
    final isDebt = type == 'debt';
    return EmptyState(
      icon: isDebt ? Icons.receipt_long_outlined : Icons.people_outline,
      message: isDebt ? t.noTitipan : t.noTitipanOrang,
      subtitle: isDebt ? t.noTitipanHint : t.noTitipanOrangHint,
      buttonLabel: isDebt ? t.addTitipanTitle : t.addTitipanOrang,
      onButtonTap: () => _openAddTitipan(isDebt ? 'debt' : 'receivable'),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(color: scheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtTile(Debt debt) {
    final t = L.of(context);
    final isDebt = debt.type == 'debt';
    final isPaid = debt.status == 'paid';
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final finance = FinanceColors.of(context);
    final accent = finance.titipan;
    final paidRatio = debt.amount > 0
        ? ((debt.amount - debt.remainingAmount) / debt.amount).clamp(0.0, 1.0)
        : 0.0;
    // Progress colour by how far along the titipan is: red when barely any is
    // paid, amber in the middle, green near/at completion.
    final progressColor = titipanProgressColor(paidRatio, finance, scheme);
    final dateFormat = DateFormat(
      'dd MMM yyyy',
      Localizations.localeOf(context).toLanguageTag(),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = debt.dueDate;
    final dueDay = due == null
        ? null
        : DateTime(due.year, due.month, due.day);
    final isOverdue = !isPaid && dueDay != null && dueDay.isBefore(today);
    // Warn a week out, so the deadline is not a surprise.
    final isDueSoon =
        !isPaid &&
        !isOverdue &&
        dueDay != null &&
        dueDay.difference(today).inDays <= 7;
    final subtitle = due == null
        ? dateFormat.format(debt.date)
        : '${t.dueDateLabel}: ${dateFormat.format(due)}';
    final subtitleColor = isOverdue
        ? scheme.error
        : isDueSoon
        ? finance.titipan
        : scheme.onSurfaceVariant;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(16),
      onTap: () =>
          Navigator.push(context, fadeSlideRoute(DebtDetailScreen(debt: debt))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _accentIcon(
                isDebt ? Icons.arrow_upward : Icons.arrow_downward,
                accent,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
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
                        color: subtitleColor,
                        fontWeight: isOverdue || isDueSoon
                            ? FontWeight.w600
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // A paid card carries its own check icon, so the "Sisa Rp 0"
              // column is left out entirely.
              if (!isPaid)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t.remaining,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    NominalText(
                      amount: debt.remainingAmount,
                      symbolColor: scheme.onSurfaceVariant,
                      style: textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (debt.amount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: paidRatio,
                    color: progressColor,
                    borderRadius: BorderRadius.circular(4),
                    semanticsLabel: t.progressPayment,
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
                    isDebt
                        ? t.paidFrom(
                            CurrencyFormatter.format(
                              debt.amount - debt.remainingAmount,
                            ),
                            CurrencyFormatter.format(debt.amount),
                          )
                        : t.receivedFrom(
                            CurrencyFormatter.format(
                              debt.amount - debt.remainingAmount,
                            ),
                            CurrencyFormatter.format(debt.amount),
                          ),
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isPaid) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 16, color: finance.income),
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

/// Progress colour for a titipan: red when barely paid, amber in the middle,
/// green near/at completion.
Color titipanProgressColor(double ratio, FinanceColors finance, ColorScheme scheme) =>
    ratio >= 0.75
    ? finance.income
    : ratio >= 0.34
    ? finance.titipan
    : scheme.error;

/// Tonal status label ("Lunas" / "Belum Lunas") shared by the debt list and detail.
class DebtStatusBadge extends StatelessWidget {
  final bool isPaid;
  const DebtStatusBadge({super.key, required this.isPaid});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Badge(
      label: Text(isPaid ? L.of(context).lunas : L.of(context).belumLunas),
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
