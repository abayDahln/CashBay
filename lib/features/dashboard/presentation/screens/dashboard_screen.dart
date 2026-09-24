import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
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
import '../../../categories/presentation/providers/category_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final _historyKey = GlobalKey<HistoryScreenState>();

  static const _titles = ['', 'Riwayat'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CashBayAppBar(
        title: _titles[_selectedIndex],
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _historyKey.currentState?.showFilterDialog(),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardHome(onLihatSemua: () => setState(() => _selectedIndex = 1)),
          HistoryScreen(key: _historyKey),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
      floatingActionButton: _selectedIndex <= 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  fadeSlideRoute(const AddTransactionScreen()),
                );
              },
              backgroundColor: AppTheme.black,
              child: const Icon(Icons.add, color: Colors.white),
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
    return Consumer3<WalletProvider, TransactionProvider, DebtProvider>(
      builder: (context, walletProvider, transactionProvider, debtProvider, _) {
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalBalanceCard(walletProvider.totalBalance),
                const SizedBox(height: 16),
                _buildWalletCards(walletProvider),
                const SizedBox(height: 16),
                _buildTagihanCards(debtProvider),
                const SizedBox(height: 16),
                _buildRecentTransactions(context, transactionProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalBalanceCard(double total) {
    return RepaintBoundary(
      child: AppCard(
                showBorder: true,
                radius: const BorderRadius.all(Radius.circular(20)),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance, color: AppTheme.textSecondary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Total Saldo',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedBalance(
              value: total,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
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

  Widget _buildWalletCards(WalletProvider provider) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
                        showBorder: true,
                        radius: const BorderRadius.all(Radius.circular(16)),
            padding: const EdgeInsets.all(14),
            child: _buildWalletContent(
              'Cash',
              provider.cashWallet?.balance ?? 0,
              Icons.money,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
                        showBorder: true,
                        radius: const BorderRadius.all(Radius.circular(16)),
            padding: const EdgeInsets.all(14),
            child: _buildWalletContent(
              'E-Wallet',
              provider.ewalletWallet?.balance ?? 0,
              Icons.phone_android,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletContent(String title, double balance, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.black, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedBalance(
          value: balance,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: balance >= 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
          formatter: CurrencyFormatter.formatMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTagihanCards(DebtProvider provider) {
    return Row(
      children: [
        Expanded(
          child: PressCard(
            onTap: () {
              Navigator.push(
                context,
                fadeSlideRoute(const DebtsScreen(initialTab: 0)),
              );
            },
            child: AppCard(
                            showBorder: true,
                            radius: const BorderRadius.all(Radius.circular(16)),
              padding: const EdgeInsets.all(14),
              child: _buildTagihanContent(
                'Tagihan Saya',
                provider.totalActiveDebt,
                Icons.arrow_upward,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PressCard(
            onTap: () {
              Navigator.push(
                context,
                fadeSlideRoute(const DebtsScreen(initialTab: 1)),
              );
            },
            child: AppCard(
                            showBorder: true,
                            radius: const BorderRadius.all(Radius.circular(16)),
              padding: const EdgeInsets.all(14),
              child: _buildTagihanContent(
                'Tagihan Orang',
                provider.totalActiveReceivable,
                Icons.arrow_downward,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagihanContent(String title, double balance, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.tagihan, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedBalance(
          value: balance,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.tagihan,
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
    final categoryOf = <int, String>{
      for (final c in [...catProvider.incomeCategories, ...catProvider.expenseCategories])
        if (c.id != null) c.id!: c.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi Terbaru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: widget.onLihatSemua,
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentTransactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada transaksi',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentTransactions.asMap().entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: entry.key < recentTransactions.length - 1 ? 8 : 0),
              child: TransactionTile(
                transaction: entry.value,
                categoryName: entry.value.categoryId != null
                    ? categoryOf[entry.value.categoryId]
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryDetailScreen(transaction: entry.value),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
