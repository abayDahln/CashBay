import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import 'history_detail_screen.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  String _typeFilter = 'all';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (mounted) await context.read<TransactionProvider>().loadTransactions();
  }

  List<Transaction> _filtered(List<Transaction> transactions) {
    if (_typeFilter == 'all') return transactions;
    if (_typeFilter == 'tagihan') {
      return transactions.where((t) => t.isTagihanRelated).toList();
    }
    return transactions
        .where((t) => t.type == _typeFilter && !t.isTagihanRelated)
        .toList();
  }

  List<Transaction> _applySearch(List<Transaction> transactions) {
    if (_searchQuery.isEmpty) return transactions;
    final query = _searchQuery.toLowerCase();
    final categoryProvider = context.read<CategoryProvider>();
    final categories = {
      for (final category in [
        ...categoryProvider.incomeCategories,
        ...categoryProvider.expenseCategories,
      ])
        category.id: category.name.toLowerCase(),
    };
    return transactions.where((transaction) {
      return transaction.description?.toLowerCase().contains(query) == true ||
          transaction.note?.toLowerCase().contains(query) == true ||
          transaction.amount.toString().contains(query) ||
          (transaction.categoryId != null &&
              categories[transaction.categoryId]?.contains(query) == true);
    }).toList();
  }

  List<_DateSection> _buildSections(List<Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final buckets = <DateTime, List<Transaction>>{};
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      buckets.putIfAbsent(date, () => []).add(transaction);
    }
    final dates = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
    return dates.map((date) {
      const weekdays = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];
      final label = date == today
          ? 'Hari Ini'
          : date == yesterday
          ? 'Kemarin'
          : date.isAfter(weekStart.subtract(const Duration(days: 1)))
          ? weekdays[date.weekday - 1]
          : DateFormat('EEEE', 'id_ID').format(date);
      return _DateSection(label, date, buckets[date]!);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat',
                  style: AppTypography.largeTitle.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: AppTypography.subheadline.copyWith(
                    color: scheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi...',
                    prefixIcon: Icon(Icons.search, color: scheme.outline),
                    fillColor: scheme.surfaceContainer,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: Icon(Icons.close, color: scheme.outline),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSegmentedControl(scheme),
              ],
            ),
          ),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.transactions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final transactions = _applySearch(
                  _filtered(provider.transactions),
                );
                if (transactions.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    message: 'Tidak ditemukan',
                    subtitle: 'Coba kata kunci lain',
                  );
                }
                final categoryProvider = context.read<CategoryProvider>();
                final categoryNames = <int, String>{
                  for (final category in [
                    ...categoryProvider.incomeCategories,
                    ...categoryProvider.expenseCategories,
                  ])
                    if (category.id != null) category.id!: category.name,
                };
                return RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      for (final section in _buildSections(transactions)) ...[
                        _SectionHeader(label: section.label, date: section.date),
                        AppCard(
                          showBorder: true,
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (
                                var i = 0;
                                i < section.transactions.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  Divider(
                                    height: 0.5,
                                    thickness: 0.5,
                                    indent: 70,
                                    color: scheme.outlineVariant.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                TransactionTile(
                                  transaction: section.transactions[i],
                                  categoryName:
                                      section.transactions[i].categoryId == null
                                      ? null
                                      : categoryNames[section
                                            .transactions[i]
                                            .categoryId],
                                  onTap: () => Navigator.push(
                                    context,
                                    fadeSlideRoute(
                                      HistoryDetailScreen(
                                        transaction: section.transactions[i],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(ColorScheme scheme) {
    const filters = <(String, String)>[
      ('Semua', 'all'),
      ('Pengeluaran', 'expense'),
      ('Pendapatan', 'income'),
      ('Tagihan', 'tagihan'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          for (final (label, value) in filters)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _typeFilter = value),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: _typeFilter == value
                        ? scheme.surfaceContainerHighest
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.footnote.copyWith(
                      color: _typeFilter == value
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: _typeFilter == value
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void showFilterDialog() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Semua', 'all', sheetContext),
                  _chip('Pendapatan', 'income', sheetContext),
                  _chip('Pengeluaran', 'expense', sheetContext),
                  _chip('Tagihan', 'tagihan', sheetContext),
                  _chip('Transfer', 'transfer', sheetContext),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value, BuildContext sheetContext) {
    return ChoiceChip(
      label: Text(label),
      selected: _typeFilter == value,
      onSelected: (_) {
        setState(() => _typeFilter = value);
        Navigator.pop(sheetContext);
      },
    );
  }
}

class _DateSection {
  final String label;
  final DateTime date;
  final List<Transaction> transactions;
  _DateSection(this.label, this.date, this.transactions);
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.date});

  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: AppTypography.caption1.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Text(
          DateFormat('dd MMM yyyy', 'id_ID').format(date),
          style: AppTypography.caption1.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    ),
  );
}
