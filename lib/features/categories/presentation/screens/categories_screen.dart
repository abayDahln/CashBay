import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart' show InputValidation;
import '../../../../core/widgets/widgets.dart';
import '../../data/models/category.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/category_provider.dart';

String _typeLabel(String type, L t) =>
    type == 'income' ? t.pendapatanLower : t.pengeluaranLower;

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
    final t = L.of(context);
    return Scaffold(
      appBar: CashBayAppBar(
        title: t.tagTransactions,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t.income),
            Tab(text: t.expense),
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
        tooltip: t.addTag,
        onPressed: () => _showCategorySheet(initialType: _currentType),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, String type) {
    final t = L.of(context);
    if (categories.isEmpty) {
      return EmptyState(
        icon: type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
        message: t.noTag(_typeLabel(type, t)),
        subtitle: t.addTagHint,
        buttonLabel: t.addTagLabel,
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
          child: _buildCategoryTile(categories[index]),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(Category category) {
    final t = L.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListTile(
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
                  t.defaultBadge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
            )
          : null,
      onTap: () => _showCategorySheet(category: category),
      trailing: PopupMenuButton<String>(
        tooltip: t.tagOptions,
        onSelected: (value) {
          if (value == 'edit') {
            _showCategorySheet(category: category);
          } else if (value == 'delete') {
            _deleteCategory(category);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_outlined),
              title: Text(t.edit),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              iconColor: scheme.error,
              textColor: scheme.error,
              leading: const Icon(Icons.delete_outline),
              title: Text(t.delete),
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
        onSubmit: (name, type) async {
          if (!isEdit) {
            final id = await provider.addCategory(name: name, type: type);
            return id != null;
          }
          final ok = await provider.updateCategory(
            category.copyWith(name: name, type: type),
          );
          // The provider only patches the list matching the new type, so a
          // type change needs a full reload to move the row between tabs.
          if (ok && type != category.type) await provider.loadCategories();
          return ok;
        },
      ),
    );

    if (saved == true && mounted) {
      final t = L.of(context);
      ToastWidget.success(context, isEdit ? t.tagUpdated : t.tagAdded);
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final t = L.of(context);
    final provider = context.read<CategoryProvider>();
    final scheme = Theme.of(context).colorScheme;

    try {
      if (await provider.isCategoryInUse(category.id!)) {
        if (mounted) {
          ToastWidget.error(context, t.tagInUse(category.name));
        }
        return;
      }
    } catch (e) {
      if (mounted) ToastWidget.error(context, t.checkTagFailed('$e'));
      return;
    }
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: scheme.error),
        title: Text(t.deleteTagQ),
        content: Text(
          category.isDefault
              ? t.deleteTagDefault(category.name)
              : t.deleteTagConfirm(category.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    try {
      final success = await provider.deleteCategory(category.id!);
      if (!mounted) return;
      if (success) {
        ToastWidget.success(context, t.tagDeleted);
      } else {
        ToastWidget.error(context, t.tagCannotDelete);
      }
    } catch (e) {
      if (mounted) ToastWidget.error(context, t.deleteTagFailed('$e'));
    }
  }
}

class _CategorySheet extends StatefulWidget {
  final Category? category;
  final String initialType;

  /// Persists the category; returns false when the save did not succeed.
  final Future<bool> Function(String name, String type) onSubmit;

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
  bool _submitted = false;
  bool _saving = false;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final t = L.of(context);
    final base = InputValidation.name(
      value,
      t.tagName,
      max: InputValidation.maxCategory,
      l10n: t,
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
      return t.tagDuplicate(_typeLabel(_selectedType, t));
    }
    return null;
  }

  Future<void> _submit() async {
    final t = L.of(context);
    if (_saving) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final ok = await widget.onSubmit(
        _nameController.text.trim(),
        _selectedType,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        ToastWidget.error(context, t.tagSaveFailed);
      }
    } catch (e) {
      if (mounted) ToastWidget.error(context, t.tagSaveFailedDetail('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final textTheme = Theme.of(context).textTheme;

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
                _isEdit ? t.editTag : t.addTagLabel,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'income',
                    label: Text(t.income),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: 'expense',
                    label: Text(t.expense),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: _saving
                    ? null
                    : (selection) {
                        setState(() => _selectedType = selection.first);
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
                decoration: InputDecoration(
                  labelText: t.tagNameField,
                  hintText: t.tagNameSample,
                ),
                validator: _validateName,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(t.cancel),
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
                          : Text(_isEdit ? t.save : t.add),
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
