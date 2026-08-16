import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
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
    await context.read<TransactionProvider>().loadTransactions();
  }

  List<Transaction> _filtered(List<Transaction> transactions) {
    if (_typeFilter == 'all') return transactions;
    if (_typeFilter == 'tagihan') {
      return transactions.where((t) => t.isTagihanRelated).toList();
    }
    return transactions.where((t) => t.type == _typeFilter && !t.isTagihanRelated).toList();
  }

  List<Transaction> _applySearch(List<Transaction> transactions) {
    if (_searchQuery.isEmpty) return transactions;
    final q = _searchQuery.toLowerCase();
    final catProvider = context.read<CategoryProvider>();
    final catMap = {
      for (final c in [...catProvider.incomeCategories, ...catProvider.expenseCategories])
        c.id: c.name.toLowerCase(),
    };
    return transactions.where((t) {
      if (t.description?.toLowerCase().contains(q) == true) return true;
      if (t.note?.toLowerCase().contains(q) == true) return true;
      if (t.amount.toString().contains(q)) return true;
      if (t.categoryId != null && catMap[t.categoryId]?.contains(q) == true) return true;
      return false;
    }).toList();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari transaksi...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          isDense: true,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  List<_DateSection> _buildSections(List<Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));

    final Map<DateTime, List<Transaction>> buckets = {};
    for (final t in transactions) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      buckets.putIfAbsent(d, () => []).add(t);
    }

    final sortedDates = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
    final sections = <_DateSection>[];

    for (final date in sortedDates) {
      String label;
      if (date == today) {
        label = 'Hari Ini';
      } else if (date == yesterday) {
        label = 'Kemarin';
      } else if (date.isAfter(thisWeekStart.subtract(const Duration(days: 1)))) {
        final dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
        label = dayNames[date.weekday - 1];
      } else {
        label = DateFormat('EEEE', 'id_ID').format(date);
      }
      sections.add(_DateSection(label, date, buckets[date]!));
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: AppCard(
            radius: BorderRadius.zero,
            padding: EdgeInsets.zero,
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.transactions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = _applySearch(_filtered(provider.transactions));

                final catProvider = context.read<CategoryProvider>();
                final categoryOf = <int, String>{
                  for (final c in [...catProvider.incomeCategories, ...catProvider.expenseCategories])
                    if (c.id != null) c.id!: c.name,
                };

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    message: 'Tidak ditemukan',
                    subtitle: 'Coba kata kunci lain',
                  );
                }

                final sections = _buildSections(filtered);

                return RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final section in sections) ...[
                        _SectionHeader(label: section.label, date: section.date),
                        for (final txn in section.transactions)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TransactionTile(
                                transaction: txn,
                                categoryName: txn.categoryId != null
                                    ? categoryOf[txn.categoryId]
                                    : null,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HistoryDetailScreen(transaction: txn),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AppCard(
                radius: const BorderRadius.all(Radius.circular(20)),
        padding: const EdgeInsets.all(16),
        child: Column(
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Semua', 'all', ctx),
                _chip('Pendapatan', 'income', ctx),
                _chip('Pengeluaran', 'expense', ctx),
                _chip('Tagihan', 'tagihan', ctx),
                _chip('Transfer', 'transfer', ctx),
              ],
            ),
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
    );
  }

  Widget _chip(String label, String value, BuildContext sheetContext) {
    final selected = _typeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _typeFilter = value);
        Navigator.pop(sheetContext);
      },
      selectedColor: AppTheme.black.withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected ? AppTheme.black : null,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
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
  final String label;
  final DateTime date;
  const _SectionHeader({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            DateFormat('dd MMM yyyy', 'id_ID').format(date),
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
