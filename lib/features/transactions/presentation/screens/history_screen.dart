import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
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
  static const _filterValues = <String>[
    'all',
    'income',
    'expense',
    'tagihan',
    'transfer',
  ];

  String _filterLabel(String value, L t) => switch (value) {
    'income' => t.income,
    'expense' => t.expense,
    'tagihan' => t.titipan,
    'transfer' => t.transfer,
    _ => t.all,
  };

  String _typeFilter = 'all';
  final _searchController = TextEditingController();
  final _filterScrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (mounted) await context.read<TransactionProvider>().loadTransactions();
  }

  /// Reloads the full (unlimited) list. Called when the tab becomes visible so
  /// it never shows a list truncated by the dashboard's limited load.
  Future<void> reload() => _loadTransactions();

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
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return transactions;
    // "15.000" / "Rp 15000" should match an amount of 15000.
    final digits = query.replaceAll(RegExp(r'[^0-9]'), '');
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
          (digits.isNotEmpty &&
              transaction.amount.toInt().toString().contains(digits)) ||
          transaction.categoryIds.any(
            (id) => categories[id]?.contains(query) == true,
          );
    }).toList();
  }

  List<_DateSection> _buildSections(List<Transaction> transactions, L t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    return dates.map((date) {
      final label = date == today
          ? t.today
          : date == yesterday
          ? t.yesterday
          : DateFormat('EEEE', locale).format(date);
      return _DateSection(label, date, buckets[date]!);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final t = L.of(context);
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              t.history,
              style: text.headlineMedium?.copyWith(color: scheme.onSurface),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: t.searchTransaction,
              elevation: const WidgetStatePropertyAll(0),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
              textInputAction: TextInputAction.search,
              leading: Icon(Icons.search, color: scheme.onSurfaceVariant),
              trailing: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    tooltip: t.clearSearch,
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close),
                  ),
              ],
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          _buildFilterChips(t),
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
                  final noData = provider.transactions.isEmpty;
                  final hasQuery = _searchQuery.trim().isNotEmpty;
                  return RefreshIndicator(
                    onRefresh: _loadTransactions,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: noData
                                ? Icons.receipt_long_outlined
                                : Icons.search_off,
                            message: noData ? t.noTransactions : t.notFound,
                            subtitle: noData
                                ? t.noTransactionsHint
                                : hasQuery
                                ? t.tryOtherKeyword
                                : t.noTxForFilter,
                          ),
                        ),
                      ],
                    ),
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
                final sections = _buildSections(transactions, t);
                return RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionHeader(
                              label: section.label,
                              date: section.date,
                            ),
                            AppCard(
                              variant: AppCardVariant.outlined,
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
                                        height: 1,
                                        indent: 72,
                                        color: scheme.outlineVariant,
                                      ),
                                    _tile(
                                      section.transactions[i],
                                      categoryNames,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Transaction transaction, Map<int, String> categoryNames) {
    final names = transaction.categoryIds
        .map((id) => categoryNames[id])
        .whereType<String>()
        .toList();
    return TransactionTile(
      transaction: transaction,
      categoryName: names.isEmpty ? null : names.join(', '),
      onTap: () => Navigator.push(
        context,
        fadeSlideRoute(HistoryDetailScreen(transaction: transaction)),
      ),
    );
  }

  Widget _buildFilterChips(L t) {
    final scheme = Theme.of(context).colorScheme;
    // Horizontally scrollable; edge fades hint at more chips and each side
    // hides once the row reaches that scroll end.
    return AnimatedBuilder(
      animation: _filterScrollController,
      builder: (context, _) {
        final position = _filterScrollController.hasClients
            ? _filterScrollController.position
            : null;
        final showLeft = position != null && position.pixels > 0;
        final showRight =
            position != null && position.pixels < position.maxScrollExtent;
        return Stack(
          children: [
            SingleChildScrollView(
              controller: _filterScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  for (final value in _filterValues)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_filterLabel(value, t)),
                        selected: _typeFilter == value,
                        onSelected: (_) => setState(() => _typeFilter = value),
                      ),
                    ),
                ],
              ),
            ),
            _edgeFade(scheme.surface, Alignment.centerLeft, showLeft),
            _edgeFade(scheme.surface, Alignment.centerRight, showRight),
          ],
        );
      },
    );
  }

  Widget _edgeFade(Color color, Alignment alignment, bool visible) {
    final isLeft = alignment == Alignment.centerLeft;
    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: 0,
      bottom: 8,
      width: 32,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                colors: [color, color.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showFilterDialog() {
    final t = L.of(context);
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
              Text(t.filter, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in _filterValues)
                    _chip(_filterLabel(value, t), value, sheetContext),
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(color: scheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat(
              'dd MMM yyyy',
              Localizations.localeOf(context).toLanguageTag(),
            ).format(date),
            style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
