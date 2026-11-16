import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_preferences_provider.dart';
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
import '../../../report/presentation/screens/report_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  /// Type filter to hand to [HistoryScreen] when it first builds (the state
  /// does not exist yet, so [HistoryScreenState.setTypeFilter] cannot be used).
  String? _historyFilter;
  final _historyKey = GlobalKey<HistoryScreenState>();
  final _homeKey = GlobalKey<DashboardHomeState>();

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return Scaffold(
      body: SlideIndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardHome(
            key: _homeKey,
            onLihatSemua: () {
              setState(() => _selectedIndex = 1);
              _historyKey.currentState?.reload();
            },
            onSelectType: (type) {
              setState(() {
                _selectedIndex = 1;
                _historyFilter = type;
              });
              _historyKey.currentState?.setTypeFilter(type);
            },
          ),
          HistoryScreen(key: _historyKey, initialTypeFilter: _historyFilter),
          const ReportScreen(),
          const ProfileScreen(),
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
          ? Theme(
              data: Theme.of(context).copyWith(
                floatingActionButtonTheme: Theme.of(context)
                    .floatingActionButtonTheme
                    .copyWith(
                      sizeConstraints: const BoxConstraints.tightFor(
                        width: 76,
                        height: 76,
                      ),
                    ),
              ),
              child: FloatingActionButton(
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
                child: const Icon(Icons.add, size: 32),
              ),
            )
          : null,
    );
  }
}

class _DashboardHome extends StatefulWidget {
  final VoidCallback? onLihatSemua;
  final ValueChanged<String>? onSelectType;
  const _DashboardHome({super.key, this.onLihatSemua, this.onSelectType});

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
      _txRepository.getTotalIncome(
        startDate: start,
        endDate: end,
        excludeTitipan: true,
      ),
      _txRepository.getTotalExpense(
        startDate: start,
        endDate: end,
        excludeTitipan: true,
      ),
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
              _WelcomeHeader(topInset: MediaQuery.paddingOf(context).top),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
            icon: Icons.trending_up,
            onTap: () => widget.onSelectType?.call('income'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: L.of(context).expenseLabel,
            amount: _monthExpense,
            icon: Icons.trending_down,
            onTap: () => widget.onSelectType?.call('expense'),
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

/// Recolors the batik by its luminance while preserving the PNG's alpha.
ColorFilter _batikTintFilter(Color tint) {
  const redWeight = 0.2126;
  const greenWeight = 0.7152;
  const blueWeight = 0.0722;
  final r = tint.r;
  final g = tint.g;
  final b = tint.b;

  return ColorFilter.matrix([
    r * redWeight,
    r * greenWeight,
    r * blueWeight,
    0,
    0,
    g * redWeight,
    g * greenWeight,
    g * blueWeight,
    0,
    0,
    b * redWeight,
    b * greenWeight,
    b * blueWeight,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);
}

/// Full-bleed greeting header: a wave banner on top, then the time-based
/// greeting and subtitle on the page background.
class _WelcomeHeader extends StatelessWidget {
  final double topInset;
  const _WelcomeHeader({required this.topInset});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final name = context.watch<ProfileProvider>().name;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? t.goodMorning(name)
        : hour < 18
        ? t.goodAfternoon(name)
        : t.goodEvening(name);

    return SliverToBoxAdapter(
      child: ColoredBox(
        // Paint the complete sliver explicitly so the batik layer always
        // fades onto the exact same surface color used by the content below.
        color: scheme.surface,
        child: Stack(
          children: [
          // Banner painted as the background of the whole header so there is no
          // Column boundary where a hairline seam could show while scrolling.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // The asset's alpha fades its lower edge into the surface.
                // The PNG is a light, low-saturation texture, so the muted M3
                // light `primary` reads as a washed-out grey on the pale
                // surface; the light theme tints with the saturated user seed
                // instead. The dark theme keeps the scheme's light primary.
                DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage(
                        'public/batik_pattern_transparent.png',
                      ),
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, 0.6),
                      colorFilter: _batikTintFilter(
                        Theme.of(context).brightness == Brightness.light
                            ? context
                                  .watch<ThemePreferencesProvider>()
                                  .seedColor
                            : scheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
            Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topInset + 72),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.welcomeSubtitle,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
    // Nominal figures are plain black/white, not the dark primary tint.
    final amountColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
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
              child: NominalText(
                amount: provider.totalBalance,
                style: AppTheme.nominal(
                  text.displaySmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                  ),
                  letterSpacing: -0.5,
                ),
                symbolColor: scheme.primary,
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
                    amountColor: amountColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _WalletBreakdown(
                    label: t.ewallet,
                    icon: Icons.smartphone_outlined,
                    balance: provider.ewalletWallet?.balance ?? 0,
                    amountColor: amountColor,
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
  final Color amountColor;
  const _WalletBreakdown({
    required this.label,
    required this.icon,
    required this.balance,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.onPrimaryContainer),
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
              NominalText(
                amount: balance,
                short: true,
                symbolColor: scheme.primary,
                style: AppTheme.nominal(
                  text.titleSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
  final VoidCallback? onTap;
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.icon,
    this.onTap,
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
              Icon(icon, size: 16, color: scheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBalance(
            value: amount,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
  final VoidCallback onTap;
  const _TagihanCard({
    required this.title,
    required this.amount,
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
              Icon(Icons.receipt_long, size: 16, color: scheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 8),
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
