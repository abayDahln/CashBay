import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart' show InputValidation;
import '../../../../core/widgets/widgets.dart';
import '../../data/models/category.dart';
import '../providers/category_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CashBayAppBar(
        title: 'Kategori',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppTheme.black,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: const [
                  Tab(text: 'Pendapatan'),
                  Tab(text: 'Pengeluaran'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: AppCard(
        radius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        child: Consumer<CategoryProvider>(
          builder: (context, provider, _) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(provider.incomeCategories, 'income'),
                _buildCategoryList(provider.expenseCategories, 'expense'),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, String type) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada kategori ${type == 'income' ? 'pendapatan' : 'pengeluaran'}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambah kategori untuk mengelompokkan transaksi',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddCategoryDialog(initialType: type),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kategori'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          child: _buildCategoryTile(categories[index], type),
        );
      },
    );
  }

  Widget _buildCategoryTile(Category category, String type) {
    final color = type == 'income'
        ? AppTheme.black
        : AppTheme.black;

    return PressCard(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(category.icon),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCategoryDialog(category);
                } else if (value == 'delete') {
                  _deleteCategory(category);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: AppTheme.black),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: AppTheme.black)),
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

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'salary':
        return Icons.work;
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'other':
      default:
        return Icons.category;
    }
  }

  void _showAddCategoryDialog({String initialType = 'expense'}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: _CategoryDialog(
          initialType: initialType,
          onSubmit: (name, type, icon) async {
            final provider = context.read<CategoryProvider>();
            await provider.addCategory(name: name, type: type, icon: icon);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kategori ditambahkan')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: _CategoryDialog(
          initialName: category.name,
          initialType: category.type,
          initialIcon: category.icon,
          onSubmit: (name, type, icon) async {
            final provider = context.read<CategoryProvider>();
            await provider.updateCategory(
              category.copyWith(name: name, type: type, icon: icon),
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kategori diperbarui')),
              );
            }
          },
        ),
      ),
    );
  }

  void _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Hapus Kategori?'),
        content: Text(
          'Kategori "${category.name}" akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.black,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<CategoryProvider>();
      final success = await provider.deleteCategory(category.id!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kategori dihapus')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kategori tidak bisa dihapus (masih digunakan)',
              ),
            ),
          );
        }
      }
    }
  }
}

class _CategoryDialog extends StatefulWidget {
  final String initialType;
  final String? initialName;
  final String? initialIcon;
  final Function(String name, String type, String? icon) onSubmit;

  const _CategoryDialog({
    required this.initialType,
    this.initialName,
    this.initialIcon,
    required this.onSubmit,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String _selectedType;
  String? _selectedIcon;

  final List<String> _incomeIcons = [
    'salary',
    'business',
    'gift',
    'investment',
    'other',
  ];
  final List<String> _expenseIcons = [
    'food',
    'transport',
    'shopping',
    'health',
    'education',
    'entertainment',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _selectedType = widget.initialType;
    _selectedIcon = widget.initialIcon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icons = _selectedType == 'income' ? _incomeIcons : _expenseIcons;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialName == null
                      ? 'Tambah Kategori'
                      : 'Edit Kategori',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
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
              onSelectionChanged: (selection) =>
                  setState(() => _selectedType = selection.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              maxLength: InputValidation.maxCategory,
              decoration: const InputDecoration(
                labelText: 'Nama Kategori',
                hintText: 'Contoh: Gaji, Makan, Transport',
              ),
              validator: (v) => InputValidation.required(v, 'Nama Kategori'),
            ),
            const SizedBox(height: 16),
            Text(
              'Ikon',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: icons.map((iconName) {
                final isSelected = _selectedIcon == iconName;
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getIconData(iconName), size: 18),
                      const SizedBox(width: 6),
                      Text(_formatIconName(iconName)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedIcon = iconName);
                    }
                  },
                  selectedColor: AppTheme.black.withOpacity(0.2),
                  checkmarkColor: AppTheme.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSubmit(
                      _nameController.text.trim(),
                      _selectedType,
                      _selectedIcon,
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  widget.initialName == null ? 'Tambah' : 'Simpan',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'salary':
        return Icons.work;
      case 'business':
        return Icons.business;
      case 'gift':
        return Icons.card_giftcard;
      case 'investment':
        return Icons.trending_up;
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'entertainment':
        return Icons.movie;
      case 'other':
      default:
        return Icons.category;
    }
  }

  String _formatIconName(String iconName) {
    return iconName[0].toUpperCase() + iconName.substring(1);
  }
}
