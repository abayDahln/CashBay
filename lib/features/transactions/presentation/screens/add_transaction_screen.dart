import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/formatters.dart' show DateFormatter, InputValidation;
import '../../../../core/widgets/widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transaction.dart';
import '../../../debts/data/models/debt.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../providers/transaction_provider.dart';
import '../../../debts/presentation/providers/debt_provider.dart';
import '../../../dashboard/presentation/providers/wallet_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';

enum DueDatePreset { days3, week1, weeks2, month1, months3, year1, custom }

DateTime _calculateDueDate(DateTime from, DueDatePreset preset) {
  switch (preset) {
    case DueDatePreset.days3: return from.add(const Duration(days: 3));
    case DueDatePreset.week1: return from.add(const Duration(days: 7));
    case DueDatePreset.weeks2: return from.add(const Duration(days: 14));
    case DueDatePreset.month1: return DateTime(from.year, from.month + 1, from.day);
    case DueDatePreset.months3: return DateTime(from.year, from.month + 3, from.day);
    case DueDatePreset.year1: return DateTime(from.year + 1, from.month, from.day);
    case DueDatePreset.custom: return from;
  }
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _personNameController = TextEditingController();
  final _billNameController = TextEditingController();
  TextEditingController? _categoryController;

  String _transactionType = 'expense';
  String _debtDirection = 'debt';
  String _paymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  DueDatePreset _duePreset = DueDatePreset.custom;
  DateTime _dueDate = DateTime.now();

  bool _isLoading = false;
  String? _attachmentPath;
  final ImagePicker _picker = ImagePicker();

  bool get _isTagihan => _transactionType == 'tagihan';
  bool get _isTransfer => _transactionType == 'transfer';
  String get _destinationWallet => _paymentMethod == 'cash' ? 'ewallet' : 'cash';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final walletProvider = context.read<WalletProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    if (walletProvider.wallets.isEmpty) {
      await walletProvider.loadWallets();
    }
    if (categoryProvider.incomeCategories.isEmpty &&
        categoryProvider.expenseCategories.isEmpty) {
      await categoryProvider.loadCategories();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _descriptionController.dispose();
    _personNameController.dispose();
    _billNameController.dispose();
    super.dispose();
  }

  String _formatRupiah(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final number = int.parse(digits);
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return formatted;
  }

  void _onAmountChanged(String value) {
    final formatted = _formatRupiah(value.replaceAll(RegExp(r'[^0-9]'), ''));
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CashBayAppBar(title: 'Tambah Transaksi'),
      body: AppCard(
        radius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        child: Consumer3<WalletProvider, CategoryProvider, DebtProvider>(
          builder: (context, walletProvider, categoryProvider, debtProvider, _) {
          final expenseCategories = categoryProvider.expenseCategories;
          final incomeCategories = categoryProvider.incomeCategories;
          final categories = _transactionType == 'income'
              ? incomeCategories
              : expenseCategories;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTypeSelector(),
                  const SizedBox(height: 20),
                  _buildAnimatedField(0, _buildAmountField()),
                  const SizedBox(height: 16),
                  if (_isTagihan) ...[
                    _buildAnimatedField(1, _buildDebtDirectionSelector()),
                    const SizedBox(height: 16),
                    _buildAnimatedField(2, _buildBillNameField()),
                    const SizedBox(height: 16),
                    _buildAnimatedField(3, _buildPersonNameField()),
                    const SizedBox(height: 16),
                    _buildAnimatedField(4, _buildDueDatePresets()),
                    const SizedBox(height: 16),
                  ] else if (_isTransfer) ...[
                    _buildAnimatedField(1, _buildTransferSelector()),
                    const SizedBox(height: 16),
                    _buildAnimatedField(2, _buildDescriptionField()),
                  ] else ...[
                    _buildAnimatedField(1, _buildDescriptionField()),
                    const SizedBox(height: 16),
                    _buildAnimatedField(2, _buildCategoryAutocomplete(categories)),
                  ],
                  if (!_isTransfer) ...[
                    const SizedBox(height: 16),
                    _buildAnimatedField(8, _buildPaymentMethod()),
                  ],
                  const SizedBox(height: 16),
                  _buildAnimatedField(9, _buildDatePicker()),
                  const SizedBox(height: 16),
                  _buildAnimatedField(10, _buildNoteField()),
                  const SizedBox(height: 16),
                  _buildAnimatedField(11, _buildPhotoPicker()),
                  const SizedBox(height: 24),
                  _buildAnimatedField(12, _buildSubmitButton()),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildAnimatedField(int index, Widget child) {
    return AnimatedListItem(
      index: index,
      slideOffset: const Offset(0, 16),
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTypeSegment('expense', 'Pengeluaran', Icons.arrow_upward)),
            const SizedBox(width: 8),
            Expanded(child: _buildTypeSegment('income', 'Pendapatan', Icons.arrow_downward)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTypeSegment('tagihan', 'Tagihan', Icons.compare_arrows)),
            const SizedBox(width: 8),
            Expanded(child: _buildTypeSegment('transfer', 'Transfer', Icons.swap_horiz)),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeSegment(String value, String label, IconData icon) {
    final selected = _transactionType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = value;
          _categoryController?.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.black : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtDirectionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Arah Tagihan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDirectionButton(
                label: 'Tagihan Saya',
                icon: Icons.arrow_upward,
                isSelected: _debtDirection == 'debt',
                onTap: () => setState(() => _debtDirection = 'debt'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDirectionButton(
                label: 'Tagihan Orang',
                icon: Icons.arrow_downward,
                isSelected: _debtDirection == 'receivable',
                onTap: () => setState(() => _debtDirection = 'receivable'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectionButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.black : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.black.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.black : Colors.grey[600], size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.black : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          onChanged: _onAmountChanged,
          decoration: const InputDecoration(
            labelText: 'Jumlah',
            prefixText: 'Rp ',
            hintText: '0',
          ),
          validator: InputValidation.amount,
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: _isTransfer ? 'Keterangan (opsional)' : _transactionType == 'income' ? 'Sumber Pendapatan' : 'Nama Transaksi',
            hintText: _isTransfer ? 'Contoh: Pindah ke E-Wallet' : _transactionType == 'income' ? 'Contoh: Gaji, Freelance' : 'Contoh: Makan siang, Bensin',
            prefixIcon: const Icon(Icons.edit_note),
          ),
          maxLength: InputValidation.maxDescription,
          validator: _isTransfer ? null : (v) => InputValidation.required(v, 'Deskripsi'),
        ),
      ),
    );
  }

  Widget _buildCategoryAutocomplete(List<Category> categories) {
    final categoryNames = categories.map((c) => c.name).toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Autocomplete<String>(
          optionsBuilder: (value) {
            if (value.text.isEmpty) return categoryNames;
            return categoryNames.where((c) =>
                c.toLowerCase().contains(value.text.toLowerCase()));
          },
          onSelected: (selection) {
            _categoryController?.text = selection;
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmit) {
            _categoryController = controller;
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                hintText: 'Cari atau ketik kategori baru...',
                prefixIcon: Icon(Icons.category),
              ),
              validator: (v) {
                if (_isTagihan) return null;
                return (v == null || v.isEmpty) ? 'Pilih kategori' : null;
              },
            );
          },
          displayStringForOption: (option) => option,
        ),
      ),
    );
  }

  Widget _buildTransferSelector() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dari', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(_paymentMethod == 'cash' ? Icons.money : Icons.phone_android, size: 18, color: AppTheme.black),
                      const SizedBox(width: 6),
                      Text(_paymentMethod == 'cash' ? 'Cash' : 'E-Wallet', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.swap_vert, color: AppTheme.black),
              onPressed: () => setState(() => _paymentMethod = _destinationWallet),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Ke', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(_destinationWallet == 'cash' ? 'Cash' : 'E-Wallet', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Icon(_destinationWallet == 'cash' ? Icons.money : Icons.phone_android, size: 18, color: AppTheme.black),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isTagihan
              ? 'Metode Pembayaran'
              : _isTransfer
                  ? 'Dompet Sumber'
                  : _transactionType == 'income'
                      ? 'Tujuan Dana'
                      : 'Sumber Dana',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'cash', label: Text('Cash'), icon: Icon(Icons.money)),
            ButtonSegment(value: 'ewallet', label: Text('E-Wallet'), icon: Icon(Icons.phone_android)),
          ],
          selected: {_paymentMethod},
          onSelectionChanged: (selected) {
            setState(() => _paymentMethod = selected.first);
          },
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            shape: WidgetStateProperty.resolveWith((states) {
              return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              );
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppTheme.black;
              return Colors.white;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return AppTheme.textSecondary;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBillNameField() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TextFormField(
          controller: _billNameController,
          decoration: const InputDecoration(
            labelText: 'Nama Tagihan',
            hintText: 'Contoh: Pinjaman Motor, Cicilan Rumah',
            prefixIcon: Icon(Icons.description),
          ),
          maxLength: InputValidation.maxBillName,
          validator: (v) => InputValidation.required(v, 'Nama Tagihan'),
        ),
      ),
    );
  }

  Widget _buildPersonNameField() {
    final isDebt = _debtDirection == 'debt';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TextFormField(
          controller: _personNameController,
          decoration: InputDecoration(
            labelText: isDebt ? 'Nama Pemberi Pinjaman' : 'Nama Penerima Pinjaman',
            hintText: isDebt ? 'Dari siapa?' : 'Ke siapa?',
            prefixIcon: const Icon(Icons.person),
          ),
          maxLength: InputValidation.maxPersonName,
          validator: (v) => InputValidation.required(v, 'Nama'),
        ),
      ),
    );
  }

  Widget _buildDueDatePresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Jatuh Tempo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _dueDateChip('3 Hari', DueDatePreset.days3),
            _dueDateChip('1 Minggu', DueDatePreset.week1),
            _dueDateChip('2 Minggu', DueDatePreset.weeks2),
            _dueDateChip('1 Bulan', DueDatePreset.month1),
            _dueDateChip('3 Bulan', DueDatePreset.months3),
            _dueDateChip('1 Tahun', DueDatePreset.year1),
            ActionChip(
              label: Text(
                _duePreset == DueDatePreset.custom
                    ? DateFormatter.formatDate(_dueDate)
                    : 'Pilih Tanggal...',
                style: TextStyle(
                  color: _duePreset == DueDatePreset.custom
                      ? AppTheme.black
                      : null,
                ),
              ),
              avatar: const Icon(Icons.calendar_today, size: 16),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _dueDate = picked;
                    _duePreset = DueDatePreset.custom;
                  });
                }
              },
            ),
          ],
        ),
        if (_duePreset != DueDatePreset.custom)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Jatuh tempo: ${DateFormatter.formatDate(_dueDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  Widget _dueDateChip(String label, DueDatePreset preset) {
    return ChoiceChip(
      label: Text(label),
      selected: _duePreset == preset,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _duePreset = preset;
            _dueDate = _calculateDueDate(_selectedDate, preset);
          });
        }
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
            if (_isTagihan && _duePreset != DueDatePreset.custom) {
              _dueDate = _calculateDueDate(picked, _duePreset);
            }
          });
        }
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Tanggal Transaksi',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              DateFormatter.formatDate(_selectedDate),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TextFormField(
          controller: _noteController,
          maxLines: 3,
          maxLength: 100,
          decoration: InputDecoration(
            labelText: 'Catatan (opsional)',
            hintText: _isTagihan
                ? 'Catatan tagihan...'
                : 'Tambahkan catatan...',
            alignLabelWithHint: true,
            counterText: '',
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                const Text(
                  'Lampiran Foto (opsional)',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const Spacer(),
                if (_attachmentPath != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _attachmentPath = null),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_attachmentPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_attachmentPath!),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Kamera'),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('Galeri'),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (file != null) {
      final err = InputValidation.imageFile(file.path);
      if (err != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppTheme.black));
        return;
      }
      setState(() => _attachmentPath = file.path);
    }
  }

  Widget _buildSubmitButton() {
    return PressCard(
      child: FilledButton(
        onPressed: _isLoading ? null : _submit,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Simpan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final rawAmount = _amountController.text.replaceAll('.', '');
    final amount = double.parse(rawAmount);

    final walletProvider = context.read<WalletProvider>();
    final wallet = walletProvider.wallets.firstWhere(
      (w) => w.type == _paymentMethod,
    );

    bool success;

    if (_isTagihan) {
      final debtType = _debtDirection;
      final transaction = Transaction(
        type: 'expense',
        amount: amount,
        walletId: wallet.id!,
        categoryId: null,
        note: _personNameController.text.trim().isNotEmpty
            ? _personNameController.text.trim()
            : (_noteController.text.isEmpty ? null : _noteController.text),
        date: _selectedDate,
        createdAt: DateTime.now(),
        description: '${debtType == 'debt' ? 'Tagihan Saya' : 'Tagihan Orang'} - ${_billNameController.text.trim()}',
        paymentMethod: _paymentMethod,
        attachmentPath: _attachmentPath,
      );
      final txnSuccess = await context.read<TransactionProvider>().addTransaction(transaction);
      if (!txnSuccess) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Gagal menyimpan'), backgroundColor: AppTheme.black),
          );
        }
        return;
      }
      final debt = Debt(
        type: debtType,
        personName: _personNameController.text.trim(),
        amount: amount,
        remainingAmount: 0,
        walletId: wallet.id!,
        status: 'paid',
        note: _noteController.text.isEmpty ? null : _noteController.text,
        date: _selectedDate,
        billName: _billNameController.text.trim(),
        dueDate: _dueDate,
        reminderEnabled: true,
        paymentMethod: _paymentMethod,
        attachmentPath: _attachmentPath,
      );
      success = await context.read<DebtProvider>().addDebt(debt);
    } else if (_isTransfer) {
      final destWallet = walletProvider.wallets.firstWhere(
        (w) => w.type == _destinationWallet,
      );
      final transaction = Transaction(
        type: 'transfer',
        amount: amount,
        walletId: wallet.id!,
        toWalletId: destWallet.id,
        categoryId: null,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        date: _selectedDate,
        createdAt: DateTime.now(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : 'Transfer ke ${_destinationWallet == 'cash' ? 'Cash' : 'E-Wallet'}',
        paymentMethod: _paymentMethod,
        attachmentPath: _attachmentPath,
      );
      success = await context.read<TransactionProvider>().addTransaction(transaction);
    } else {
      int? categoryId;
      final categoryName = (_categoryController?.text ?? '').trim();

      if (categoryName.isNotEmpty) {
        final catProvider = context.read<CategoryProvider>();
        final catType = _transactionType == 'income' ? 'income' : 'expense';
        final existing = catProvider.incomeCategories + catProvider.expenseCategories;
        final match = existing.cast<Category?>().firstWhere(
          (c) => c!.name.toLowerCase() == categoryName.toLowerCase(),
          orElse: () => null,
        );

        if (match != null) {
          categoryId = match.id;
        } else {
          final repo = CategoryRepository();
          final newId = await repo.insertCategory(Category(
            name: categoryName,
            type: catType,
          ));
          categoryId = newId;
          await catProvider.loadCategories();
        }
      }

      final transaction = Transaction(
        type: _transactionType,
        amount: amount,
        walletId: wallet.id!,
        categoryId: categoryId,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        date: _selectedDate,
        createdAt: DateTime.now(),
        description: _descriptionController.text.trim(),
        paymentMethod: _paymentMethod,
        attachmentPath: _attachmentPath,
      );

      success = await context.read<TransactionProvider>().addTransaction(transaction);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      if (_isTagihan) context.read<DebtProvider>().loadActiveDebts();
      context.read<WalletProvider>().loadWallets();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Berhasil disimpan', style: TextStyle(color: Colors.black87)),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal menyimpan'),
          backgroundColor: AppTheme.black,
        ),
      );
    }
  }
}
