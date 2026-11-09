import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart' show InputValidation;
import '../../../../core/widgets/widgets.dart';
import '../../data/models/category.dart';
import '../providers/category_provider.dart';

const _incomeIcons = ['salary', 'business', 'gift', 'investment', 'other'];
const _expenseIcons = [
  'food',
  'transport',
  'shopping',
  'health',
  'education',
  'entertainment',
  'other',
];

IconData _categoryIcon(String? iconName) => switch (iconName) {
  'salary' => Icons.work_outline,
  'business' => Icons.business_center_outlined,
  'gift' => Icons.card_giftcard,
  'investment' => Icons.trending_up,
  'food' => Icons.restaurant,
  'transport' => Icons.directions_car_outlined,
  'shopping' => Icons.shopping_bag_outlined,
  'health' => Icons.local_hospital_outlined,
  'education' => Icons.school_outlined,
  'entertainment' => Icons.movie_outlined,
  _ => Icons.category_outlined,
};

String _iconLabel(String iconName) => switch (iconName) {
  'salary' => 'Gaji',
  'business' => 'Bisnis',
  'gift' => 'Hadiah',
  'investment' => 'Investasi',
  'food' => 'Makanan',
  'transport' => 'Transportasi',
  'shopping' => 'Belanja',
  'health' => 'Kesehatan',
  'education' => 'Pendidikan',
  'entertainment' => 'Hiburan',
  _ => 'Lainnya',
};

String _typeLabel(String type) =>
    type == 'income' ? 'pendapatan' : 'pengeluaran';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    await context.read<CategoryProvider>().loadCategories();
  }

  String get _currentType => _tabController.index == 0 ? 'income' : 'expense';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CashBayAppBar(
        title: 'Tag Transaksi',
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendapatan'),
            Tab(text: 'Pengeluaran'),
          ],
        ),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading &&
              provider.incomeCategories.isEmpty &&
              provider.expenseCategories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(provider.incomeCategories, 'income'),
              _buildCategoryList(provider.expenseCategories, 'expense'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah tag',
        onPressed: () => _showCategorySheet(initialType: _currentType),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, String type) {
    if (categories.isEmpty) {
      return EmptyState(
        icon: type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
        message: 'Belum ada tag ${_typeLabel(type)}',
        subtitle: 'Tambah tag untuk mengelompokkan transaksi',
        buttonLabel: 'Tambah Tag',
        onButtonTap: () => _showCategorySheet(initialType: type),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom padding keeps the last row clear of the FAB.
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: categories.length,
        itemBuilder: (context, index) => AnimatedListItem(
          index: index,
          child: _buildCategoryTile(categories[index], type),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(Category category, String type) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final finance = FinanceColors.of(context);
    final isIncome = type == 'income';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIncome
            ? finance.incomeContainer
            : finance.expenseContainer,
        foregroundColor: isIncome
            ? finance.onIncomeContainer
            : finance.onExpenseContainer,
        child: Icon(_categoryIcon(category.icon)),
      ),
      title: Text(category.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: category.isDefault
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bawaan',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
            )
          : null,
      onTap: () => _showCategorySheet(category: category),
      trailing: PopupMenuButton<String>(
        tooltip: 'Opsi tag',
        onSelected: (value) {
          if (value == 'edit') {
            _showCategorySheet(category: category);
          } else if (value == 'delete') {
            _deleteCategory(category);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit'),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              iconColor: scheme.error,
              textColor: scheme.error,
              leading: const Icon(Icons.delete_outline),
              title: const Text('Hapus'),
            ),
          ),
        ],
      ),
    );
  }

  /// Add (when [category] is null) or edit a category in a bottom sheet.
  Future<void> _showCategorySheet({
    Category? category,
    String initialType = 'expense',
  }) async {
    final provider = context.read<CategoryProvider>();
    final isEdit = category != null;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _CategorySheet(
        category: category,
        initialType: category?.type ?? initialType,
        onSubmit: (name, type, icon) async {
          if (!isEdit) {
            final id = await provider.addCategory(
              name: name,
              type: type,
              icon: icon,
            );
            return id != null;
          }
          final ok = await provider.updateCategory(
            category.copyWith(name: name, type: type, icon: icon),
          );
          // The provider only patches the list matching the new type, so a
          // type change needs a full reload to move the row between tabs.
          if (ok && type != category.type) await provider.loadCategories();
          return ok;
        },
      ),
    );

    if (saved == true && mounted) {
      ToastWidget.success(
        context,
        isEdit ? 'Tag diperbarui' : 'Tag ditambahkan',
      );
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final provider = context.read<CategoryProvider>();
    final scheme = Theme.of(context).colorScheme;

    try {
      if (await provider.isCategoryInUse(category.id!)) {
        if (mounted) {
          ToastWidget.error(
            context,
            'Tag "${category.name}" masih digunakan transaksi',
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) ToastWidget.error(context, 'Gagal memeriksa tag: $e');
      return;
    }
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: scheme.error),
        title: const Text('Hapus Tag?'),
        content: Text(
          category.isDefault
              ? 'Tag bawaan "${category.name}" akan dihapus permanen.'
              : 'Tag "${category.name}" akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    try {
      final success = await provider.deleteCategory(category.id!);
      if (!mounted) return;
      if (success) {
        ToastWidget.success(context, 'Tag dihapus');
      } else {
        ToastWidget.error(
          context,
          'Tag tidak bisa dihapus (masih digunakan)',
        );
      }
    } catch (e) {
      if (mounted) ToastWidget.error(context, 'Gagal menghapus tag: $e');
    }
  }
}

class _CategorySheet extends StatefulWidget {
  final Category? category;
  final String initialType;

  /// Persists the category; returns false when the save did not succeed.
  final Future<bool> Function(String name, String type, String? icon) onSubmit;

  const _CategorySheet({
    required this.category,
    required this.initialType,
    required this.onSubmit,
  });

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedType;
  String? _selectedIcon;
  bool _submitted = false;
  bool _saving = false;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedType = widget.initialType;
    _selectedIcon = widget.category?.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final base = InputValidation.name(
      value,
      'Nama tag',
      max: InputValidation.maxCategory,
    );
    if (base != null) return base;

    final name = value!.trim().toLowerCase();
    final provider = context.read<CategoryProvider>();
    final sameType = _selectedType == 'income'
        ? provider.incomeCategories
        : provider.expenseCategories;
    final duplicate = sameType.any(
      (c) =>
          c.id != widget.category?.id && c.name.trim().toLowerCase() == name,
    );
    if (duplicate) {
      return 'Tag ${_typeLabel(_selectedType)} dengan nama ini sudah ada';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final ok = await widget.onSubmit(
        _nameController.text.trim(),
        _selectedType,
        _selectedIcon,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        ToastWidget.error(context, 'Gagal menyimpan tag');
      }
    } catch (e) {
      if (mounted) ToastWidget.error(context, 'Gagal menyimpan tag: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final icons = _selectedType == 'income' ? _incomeIcons : _expenseIcons;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? 'Edit Tag' : 'Tambah Tag',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'income',
                    label: Text('Pendapatan'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: 'expense',
                    label: Text('Pengeluaran'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: _saving
                    ? null
                    : (selection) {
                        setState(() {
                          _selectedType = selection.first;
                          final available = _selectedType == 'income'
                              ? _incomeIcons
                              : _expenseIcons;
                          if (!available.contains(_selectedIcon)) {
                            _selectedIcon = null;
                          }
                        });
                        // Duplicate check depends on the type.
                        if (_submitted) _formKey.currentState?.validate();
                      },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                enabled: !_saving,
                autofocus: !_isEdit,
                maxLength: InputValidation.maxCategory,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nama Tag',
                  hintText: 'Contoh: Gaji, Makan, Transport',
                ),
                validator: _validateName,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              Text('Ikon', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final iconName in icons)
                    ChoiceChip(
                      avatar: Icon(_categoryIcon(iconName), size: 18),
                      label: Text(_iconLabel(iconName)),
                      selected: _selectedIcon == iconName,
                      showCheckmark: false,
                      onSelected: _saving
                          ? null
                          : (selected) => setState(
                              () => _selectedIcon = selected ? iconName : null,
                            ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEdit ? 'Simpan' : 'Tambah'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
