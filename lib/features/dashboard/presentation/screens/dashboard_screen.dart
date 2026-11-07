import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardHome(
            onLihatSemua: () => setState(() => _selectedIndex = 1),
          ),
          HistoryScreen(key: _historyKey),
          const ReportScreen(),
          const SettingsScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
      floatingActionButton: _selectedIndex <= 1
          ? FloatingActionButton(
              tooltip: 'Tambah transaksi',
              onPressed: () {
                Navigator.push(
                  context,
                  fadeSlideRoute(const AddTransactionScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _DashboardHome extends StatefulWidget {
  final VoidCallback? onLihatSemua;
  const _DashboardHome({this.onLihatSemua});

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
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
      _txRepository.getTotalIncome(startDate: start, endDate: end),
      _txRepository.getTotalExpense(startDate: start, endDate: end),
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
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverAppBar.medium(title: Text('Dashboard')),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                sliver: SliverList.list(
                  children: [
                    _BalanceHeroCard(provider: walletProvider),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Bulan Ini',
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
    final finance = FinanceColors.of(context);
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Pendapatan',
            amount: _monthIncome,
            icon: Icons.south,
            container: finance.incomeContainer,
            onContainer: finance.onIncomeContainer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'Pengeluaran',
            amount: _monthExpense,
            icon: Icons.north,
            container: finance.expenseContainer,
            onContainer: finance.onExpenseContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildTagihanSection(DebtProvider provider) {
    final finance = FinanceColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Tagihan & Piutang',
          trailing: Text(
            '${provider.debts.length} Terbuka',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _TagihanCard(
                title: 'Tagihan Saya',
                amount: provider.totalActiveDebt,
                icon: Icons.north,
                container: finance.expenseContainer,
                onContainer: finance.onExpenseContainer,
                onTap: () => Navigator.push(
                  context,
                  fadeSlideRoute(const DebtsScreen(initialTab: 0)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TagihanCard(
                title: 'Tagihan Orang',
                amount: provider.totalActiveReceivable,
                icon: Icons.south,
                container: finance.incomeContainer,
                onContainer: finance.onIncomeContainer,
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
    final recentTransactions = provider.transactions.take(3).toList();
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
      content = const EmptyState(
        icon: Icons.receipt_long_outlined,
        message: 'Belum ada transaksi',
        subtitle: 'Tekan tombol + untuk mencatat transaksi pertama',
      );
    } else {
      content = Column(
        children: [
          for (var i = 0; i < recentTransactions.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            TransactionTile(
              transaction: recentTransactions[i],
              categoryName: recentTransactions[i].categoryId != null
                  ? categoryOf[recentTransactions[i].categoryId]
                  : null,
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
          title: 'Transaksi Terbaru',
          trailing: TextButton(
            onPressed: widget.onLihatSemua,
            child: const Text('Lihat Semua'),
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

/// Hero "Total Saldo" card with the Cash / E-Wallet breakdown.
class _BalanceHeroCard extends StatelessWidget {
  final WalletProvider provider;
  const _BalanceHeroCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
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
                  'Total Saldo',
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
                    label: 'Cash',
                    icon: Icons.payments_outlined,
                    balance: provider.cashWallet?.balance ?? 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _WalletBreakdown(
                    label: 'E-Wallet',
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
  final IconData icon;
  final Color container;
  final Color onContainer;
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.container,
    required this.onContainer,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      color: container,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: onContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge?.copyWith(color: onContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBalance(
            value: amount,
            style: text.titleMedium?.copyWith(
              color: onContainer,
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
