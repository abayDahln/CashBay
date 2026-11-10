import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/wallet_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../debts/presentation/providers/debt_provider.dart';
import '../../../transactions/presentation/screens/add_transaction_screen.dart';
import '../../../debts/presentation/screens/debts_screen.dart';
import '../../../transactions/presentation/screens/history_screen.dart';
import '../../../transactions/presentation/screens/history_detail_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../report/presentation/screens/report_screen.dart';
import '../../../categories/presentation/providers/category_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final _historyKey = GlobalKey<HistoryScreenState>();
  final _homeKey = GlobalKey<DashboardHomeState>();

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardHome(
            key: _homeKey,
            onLihatSemua: () {
              setState(() => _selectedIndex = 1);
              _historyKey.currentState?.reload();
            },
          ),
          HistoryScreen(key: _historyKey),
          const ReportScreen(),
          const SettingsScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // Reload the full list when opening Riwayat so it never shows the
          // truncated (limit: 10) list loaded for the dashboard.
          if (index == 1) _historyKey.currentState?.reload();
        },
      ),
      floatingActionButton: _selectedIndex <= 1
          ? FloatingActionButton(
              tooltip: t.addTransaction,
              onPressed: () async {
                final saved = await Navigator.push(
                  context,
                  fadeSlideRoute(const AddTransactionScreen()),
                );
                // Refresh once so every tab shows the new data without a manual
                // pull-to-refresh.
                if (saved == true && mounted) {
                  await _homeKey.currentState?.refresh();
                  if (mounted) _historyKey.currentState?.reload();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _DashboardHome extends StatefulWidget {
  final VoidCallback? onLihatSemua;
  const _DashboardHome({super.key, this.onLihatSemua});

  @override
  State<_DashboardHome> createState() => DashboardHomeState();
}

class DashboardHomeState extends State<_DashboardHome> {
  final _txRepository = TransactionRepository();
  double _monthIncome = 0;
  double _monthExpense = 0;

  /// Last transaction list seen. The provider replaces the list on every
  /// reload (after add / edit / delete), which also refreshes month totals.
  List<Transaction>? _lastTransactions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onRefresh());
  }

  /// Reloads wallets, transactions and debts. Public so the shell can trigger
  /// it after a new transaction is saved.
  Future<void> refresh() => _onRefresh();

  Future<void> _onRefresh() async {
    final walletProvider = context.read<WalletProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final debtProvider = context.read<DebtProvider>();
    await Future.wait([
      walletProvider.refreshBalances(),
      transactionProvider.loadTransactions(limit: 10),
      debtProvider.loadActiveDebts(),
    ]);
  }

  Future<void> _loadMonthTotals() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(
      now.year,
      now.month + 1,
    ).subtract(const Duration(microseconds: 1));
    final results = await Future.wait([
      _txRepository.getTotalIncome(startDate: start, endDate: end, excludeTitipan: true),
      _txRepository.getTotalExpense(startDate: start, endDate: end, excludeTitipan: true),
    ]);
    if (!mounted) return;
    setState(() {
      _monthIncome = results[0];
      _monthExpense = results[1];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<WalletProvider, TransactionProvider, DebtProvider>(
      builder: (context, walletProvider, transactionProvider, debtProvider, _) {
        if (!identical(transactionProvider.transactions, _lastTransactions)) {
          _lastTransactions = transactionProvider.transactions;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _loadMonthTotals(),
          );
        }
        final scheme = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        final t = L.of(context);
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar.medium(title: Text(t.dashboard)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                sliver: SliverList.list(
                  children: [
                    _BalanceHeroCard(provider: walletProvider),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: t.thisMonth,
                      trailing: Text(
                        DateFormatter.formatMonthYear(DateTime.now()),
                        style: text.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    _buildMonthSummary(),
                    const SizedBox(height: 16),
                    _buildTagihanSection(debtProvider),
                    const SizedBox(height: 16),
                    _buildRecentTransactions(context, transactionProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthSummary() {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: L.of(context).incomeLabel,
            amount: _monthIncome,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: L.of(context).expenseLabel,
            amount: _monthExpense,
          ),
        ),
      ],
    );
  }

  Widget _buildTagihanSection(DebtProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    final t = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: t.titipanPiutang,
          trailing: Text(
            t.titipanOpenCount(provider.debts.length),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _TagihanCard(
                title: t.titipanSaya,
                amount: provider.totalActiveDebt,
                icon: Icons.north,
                container: scheme.primaryContainer,
                onContainer: scheme.onPrimaryContainer,
                onTap: () => Navigator.push(
                  context,
                  fadeSlideRoute(const DebtsScreen(initialTab: 0)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TagihanCard(
                title: t.titipanOrang,
                amount: provider.totalActiveReceivable,
                icon: Icons.south,
                container: scheme.primaryContainer,
                onContainer: scheme.onPrimaryContainer,
                onTap: () => Navigator.push(
                  context,
                  fadeSlideRoute(const DebtsScreen(initialTab: 1)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final recentTransactions = provider.transactions.take(10).toList();
    final t = L.of(context);
    final catProvider = context.watch<CategoryProvider>();
    final categoryOf = <int, String>{
      for (final c in [
        ...catProvider.incomeCategories,
        ...catProvider.expenseCategories,
      ])
        if (c.id != null) c.id!: c.name,
    };
    
    final Widget content;
    if (recentTransactions.isEmpty && provider.isLoading) {
      content = const _TransactionSkeleton();
    } else if (recentTransactions.isEmpty) {
      content = EmptyState(
        icon: Icons.receipt_long_outlined,
        message: t.noTransactions,
      );
    } else {
      content = Column(
        children: [
          for (var i = 0; i < recentTransactions.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            TransactionTile(
              transaction: recentTransactions[i],
              categoryName: _joinCategoryNames(
                recentTransactions[i].categoryIds,
                categoryOf,
              ),
              showChevron: false,
              onTap: () => Navigator.push(
                context,
                fadeSlideRoute(
                  HistoryDetailScreen(transaction: recentTransactions[i]),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: t.recentTransactions,
          trailing: TextButton(
            onPressed: widget.onLihatSemua,
            child: Text(t.viewAll),
          ),
        ),
        AppCard(
          variant: AppCardVariant.outlined,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      ],
    );
  }
}

/// Comma-joined category names for a transaction's tag ids.
String? _joinCategoryNames(List<int> ids, Map<int, String> names) {
  final resolved = ids.map((id) => names[id]).whereType<String>().toList();
  return resolved.isEmpty ? null : resolved.join(', ');
}

/// Hero "Total Saldo" card with the Cash / E-Wallet breakdown.
class _BalanceHeroCard extends StatelessWidget {
  final WalletProvider provider;
  const _BalanceHeroCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final t = L.of(context);
    final onColor = scheme.onPrimaryContainer;
    return RepaintBoundary(
      child: AppCard(
        color: scheme.primaryContainer,
        radius: BorderRadius.circular(AppTheme.radiusXl),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: onColor,
                ),
                const SizedBox(width: 8),
                Text(
                  t.totalBalance,
                  style: text.titleSmall?.copyWith(color: onColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedBalance(
                value: provider.totalBalance,
                style: text.displaySmall?.copyWith(
                  color: onColor,
                  fontWeight: FontWeight.w600,
                ),
                formatter: CurrencyFormatter.format,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _WalletBreakdown(
                    label: t.cash,
                    icon: Icons.payments_outlined,
                    balance: provider.cashWallet?.balance ?? 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _WalletBreakdown(
                    label: t.ewallet,
                    icon: Icons.smartphone_outlined,
                    balance: provider.ewalletWallet?.balance ?? 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletBreakdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final double balance;
  const _WalletBreakdown({
    required this.label,
    required this.icon,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: scheme.surface,
          foregroundColor: scheme.primary,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
              AnimatedBalance(
                value: balance,
                style: text.titleSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
                formatter: CurrencyFormatter.formatMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  const _SummaryTile({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          AnimatedBalance(
            value: amount,
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            formatter: CurrencyFormatter.formatMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TagihanCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color container;
  final Color onContainer;
  final VoidCallback onTap;
  const _TagihanCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.container,
    required this.onContainer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AppCard(
      variant: AppCardVariant.outlined,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: container,
                foregroundColor: onContainer,
                child: Icon(icon, size: 18),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          AnimatedBalance(
            value: amount,
            style: text.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            formatter: CurrencyFormatter.formatMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 48dp section header: titleMedium label plus an optional trailing widget.
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// Placeholder rows shown while the first transaction load is in flight.
class _TransactionSkeleton extends StatelessWidget {
  const _TransactionSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
    );
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(radius: 20, backgroundColor: color),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(140, 14),
                        const SizedBox(height: 8),
                        bar(88, 12),
                      ],
                    ),
                  ),
                  bar(64, 14),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
