import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/wallet_provider.dart';
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
              child: const Icon(Icons.add, size: 28),
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Consumer3<WalletProvider, TransactionProvider, DebtProvider>(
        builder: (context, walletProvider, transactionProvider, debtProvider, _) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ScreenTitle(title: 'Dashboard'),
                  const SizedBox(height: 16),
                  _buildTotalBalanceCard(walletProvider.totalBalance),
                  const SizedBox(height: 24),
                  _buildWalletSection(walletProvider),
                  const SizedBox(height: 24),
                  _buildTagihanSection(debtProvider),
                  const SizedBox(height: 24),
                  _buildRecentTransactions(context, transactionProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalBalanceCard(double total) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: AppCard(
        showBorder: true,
        radius: const BorderRadius.all(Radius.circular(20)),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Total Saldo',
                  style: AppTypography.subheadline.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedBalance(
              value: total,
              style: AppTypography.headlineLargeMobile.copyWith(
                color: scheme.onSurface,
              ),
              formatter: CurrencyFormatter.formatShort,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection(WalletProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SUMBER DANA'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppCard(
                showBorder: true,
                padding: const EdgeInsets.all(14),
                child: _walletCard(
                  'Cash',
                  provider.cashWallet?.balance ?? 0,
                  Icons.payments,
                  scheme,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                showBorder: true,
                padding: const EdgeInsets.all(14),
                child: _walletCard(
                  'E-Wallet',
                  provider.ewalletWallet?.balance ?? 0,
                  Icons.smartphone,
                  scheme,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _walletCard(
    String title,
    double balance,
    IconData icon,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: scheme.primary, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: AppTypography.caption2.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedBalance(
          value: balance,
          style: AppTypography.headline.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          formatter: CurrencyFormatter.formatMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTagihanSection(DebtProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('TAGIHAN & PIUTANG'),
            const Spacer(),
            Text(
              '${provider.debts.length} Terbuka',
              style: AppTypography.caption2.copyWith(color: scheme.outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppCard(
                showBorder: true,
                padding: const EdgeInsets.all(14),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    fadeSlideRoute(const DebtsScreen(initialTab: 0)),
                  ),
                  child: _tagihanCard(
                    'Tagihan Saya',
                    provider.totalActiveDebt,
                    Icons.north,
                    scheme,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                showBorder: true,
                padding: const EdgeInsets.all(14),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    fadeSlideRoute(const DebtsScreen(initialTab: 1)),
                  ),
                  child: _tagihanCard(
                    'Tagihan Orang',
                    provider.totalActiveReceivable,
                    Icons.south,
                    scheme,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tagihanCard(
    String title,
    double balance,
    IconData icon,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: scheme.primary, size: 18),
            ),
            const Spacer(),
            Text(
              title,
              style: AppTypography.caption2.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedBalance(
          value: balance,
          style: AppTypography.headline.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          formatter: CurrencyFormatter.formatMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    final scheme = Theme.of(context).colorScheme;
    final categoryOf = <int, String>{
      for (final c in [
        ...catProvider.incomeCategories,
        ...catProvider.expenseCategories,
      ])
        if (c.id != null) c.id!: c.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Transaksi Terbaru',
              style: AppTypography.headline.copyWith(color: scheme.onSurface),
            ),
            const Spacer(),
            TextButton(
              onPressed: widget.onLihatSemua,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                foregroundColor: scheme.primary,
              ),
              child: Text(
                'Lihat Semua',
                style: AppTypography.subheadline.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AppCard(
          showBorder: true,
          padding: EdgeInsets.zero,
          child: recentTransactions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 40, color: scheme.outline),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada transaksi',
                          style: AppTypography.subheadline.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < recentTransactions.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 0.5,
                          thickness: 0.5,
                          indent: 70,
                          color: scheme.outlineVariant.withValues(alpha: 0.15),
                        ),
                      TransactionTile(
                        transaction: recentTransactions[i],
                        categoryName: recentTransactions[i].categoryId != null
                            ? categoryOf[recentTransactions[i].categoryId]
                            : null,
                        showChevron: false,
                        onTap: () => Navigator.push(
                          context,
                          fadeSlideRoute(
                            HistoryDetailScreen(
                              transaction: recentTransactions[i],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.caption2.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  final String title;
  const _ScreenTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.largeTitle.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
