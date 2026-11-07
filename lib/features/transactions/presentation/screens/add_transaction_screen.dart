import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart'
    show DateFormatter, InputValidation;
import '../../../../core/widgets/widgets.dart';
import '../../data/models/transaction.dart';
import '../../../debts/data/models/debt.dart';
import '../providers/transaction_provider.dart';
import '../../../debts/presentation/providers/debt_provider.dart';
import '../../../dashboard/presentation/providers/wallet_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';

enum DueDatePreset { days3, week1, weeks2, month1, months3, year1, custom }

DateTime _calculateDueDate(DateTime from, DueDatePreset preset) {
  switch (preset) {
    case DueDatePreset.days3:
      return from.add(const Duration(days: 3));
    case DueDatePreset.week1:
      return from.add(const Duration(days: 7));
    case DueDatePreset.weeks2:
      return from.add(const Duration(days: 14));
    case DueDatePreset.month1:
      return DateTime(from.year, from.month + 1, from.day);
    case DueDatePreset.months3:
      return DateTime(from.year, from.month + 3, from.day);
    case DueDatePreset.year1:
      return DateTime(from.year + 1, from.month, from.day);
    case DueDatePreset.custom:
      return from;
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
  String get _destinationWallet =>
      _paymentMethod == 'cash' ? 'ewallet' : 'cash';

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
    setState(() {});
  }

  /// Raw integer value of the amount field, 0 when empty.
  double get _amountValue =>
      double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;

  void _setAmount(double value) {
    final formatted = value <= 0 ? '' : _formatRupiah(value.toInt().toString());
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CashBayAppBar(title: 'Tambah Transaksi'),
      body: Consumer3<WalletProvider, CategoryProvider, DebtProvider>(
        builder: (context, walletProvider, categoryProvider, debtProvider, _) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAnimatedField(0, _buildTypeSelector()),
                  const SizedBox(height: 20),
                  _buildAnimatedField(0, _buildAmountField()),
                  const SizedBox(height: 16),
                  _buildInsetGroup(
                    'DETAIL UTAMA',
                    [
                      if (_isTagihan) ...[
                        _buildDebtDirectionSelector(),
                        const SizedBox(height: 12),
                        _buildBillNameField(),
                        const SizedBox(height: 12),
                        _buildPersonNameField(),
                        const SizedBox(height: 12),
                        _buildDueDatePresets(),
                      ] else if (_isTransfer) ...[
                        _buildTransferSelector(),
                        const SizedBox(height: 12),
                        _buildDescriptionField(),
                      ] else ...[
                        _buildDescriptionField(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInsetGroup(
                    'SUMBER DANA & WAKTU',
                    [
                      if (!_isTransfer) ...[
                        _buildPaymentMethod(),
                        const SizedBox(height: 12),
                      ],
                      _buildDatePicker(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInsetGroup('CATATAN & LAMPIRAN', [
                    _buildNoteField(),
                    const SizedBox(height: 12),
                    _buildPhotoPicker(),
                  ]),
                  const SizedBox(height: 24),
                  _buildAnimatedField(12, _buildSubmitButton()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsetGroup(String label, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: AppTypography.caption1.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        AppCard(
          showBorder: true,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
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
    const types = <(String, IconData, String)>[
      ('expense', Icons.arrow_upward, 'Pengeluaran'),
      ('income', Icons.arrow_downward, 'Pendapatan'),
      ('tagihan', Icons.receipt_long, 'Tagihan'),
      ('transfer', Icons.swap_horiz, 'Transfer'),
    ];
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          for (final (value, icon, label) in types)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _transactionType = value;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _transactionType == value
                        ? scheme.surfaceBright
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(icon, size: 19, color: scheme.primary),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption2.copyWith(
                          color: _transactionType == value
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDebtDirectionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arah Tagihan',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                value: 'debt',
                icon: Icons.north,
                label: 'Tagihan Saya',
                selectedValue: _debtDirection,
                onTap: (v) => setState(() => _debtDirection = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionCard(
                value: 'receivable',
                icon: Icons.south,
                label: 'Tagihan Orang',
                selectedValue: _debtDirection,
                onTap: (v) => setState(() => _debtDirection = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = _amountValue > 0;
    const quickAmounts = <int>[10000, 20000, 50000, 100000];
    final display = _amountController.text.isEmpty
        ? '0'
        : _amountController.text;
    final amountStyle = AppTypography.headlineLargeMobile.copyWith(
      color: hasValue ? scheme.onSurface : scheme.outline,
    );
    return AppCard(
      showBorder: true,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Text(
            'NOMINAL TRANSAKSI',
            style: AppTypography.caption1.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                // The TextFormField stays transparent and handles input /
                // validation; the visible Text is auto-scaled to avoid wrap.
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IgnorePointer(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Rp',
                              style: AppTypography.headline.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(display, style: amountStyle),
                          ],
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      onChanged: _onAmountChanged,
                      textAlign: TextAlign.center,
                      cursorHeight: 28,
                      style: amountStyle.copyWith(color: Colors.transparent),
                      decoration: const InputDecoration(
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      validator: InputValidation.amount,
                    ),
                  ],
                ),
              ),
              // Clear button — only visible when there is a value.
              if (hasValue)
                IconButton(
                  tooltip: 'Kosongkan nominal',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.cancel, size: 20, color: scheme.outline),
                  onPressed: () => _setAmount(0),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final amount in quickAmounts)
                _buildQuickAmountChip(amount),
              if (hasValue) _buildQuickAmountChip(null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(int? amount) {
    final scheme = Theme.of(context).colorScheme;
    final isClear = amount == null;
    final label = isClear
        ? 'Hapus'
        : '+${_formatRupiah((amount ~/ 1000).toString())}rb';
    return GestureDetector(
      onTap: () => _setAmount(isClear ? 0 : _amountValue + amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: AppTypography.footnote.copyWith(
            color: isClear ? scheme.error : scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: _isTransfer
            ? 'Keterangan (opsional)'
            : _transactionType == 'income'
            ? 'Sumber Pendapatan'
            : 'Nama Transaksi',
        hintText: _isTransfer
            ? 'Contoh: Pindah ke E-Wallet'
            : _transactionType == 'income'
            ? 'Contoh: Gaji, Freelance'
            : 'Contoh: Makan siang, Bensin',
        prefixIcon: Icon(Icons.edit_note),
      ),
      maxLength: InputValidation.maxDescription,
      // Counter disembunyikan; batas 200 karakter tetap berlaku.
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      validator: _isTransfer
          ? null
          : (v) => InputValidation.required(v, 'Deskripsi'),
    );
  }

  Widget _buildTransferSelector() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dari',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _paymentMethod == 'cash'
                        ? Icons.money
                        : Icons.phone_android,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _paymentMethod == 'cash' ? 'Cash' : 'E-Wallet',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Tukar dompet',
          icon: Icon(
            Icons.swap_vert,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => setState(() => _paymentMethod = _destinationWallet),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Ke',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _destinationWallet == 'cash' ? 'Cash' : 'E-Wallet',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _destinationWallet == 'cash'
                        ? Icons.money
                        : Icons.phone_android,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                value: 'cash',
                label: 'Cash',
                selectedValue: _paymentMethod,
                onTap: (v) => setState(() => _paymentMethod = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionCard(
                value: 'ewallet',
                label: 'E-Wallet',
                selectedValue: _paymentMethod,
                onTap: (v) => setState(() => _paymentMethod = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// A tappable card used as a single-choice option (replaces segmented rows).
  Widget _buildOptionCard({
    required String value,
    required String label,
    required String selectedValue,
    required ValueChanged<String> onTap,
    IconData? icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = selectedValue == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.subheadline.copyWith(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillNameField() {
    return TextFormField(
      controller: _billNameController,
      decoration: const InputDecoration(
        labelText: 'Nama Tagihan',
        hintText: 'Contoh: Pinjaman Motor, Cicilan Rumah',
        prefixIcon: Icon(Icons.description),
      ),
      maxLength: InputValidation.maxBillName,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      validator: (v) => InputValidation.required(v, 'Nama Tagihan'),
    );
  }

  Widget _buildPersonNameField() {
    final isDebt = _debtDirection == 'debt';
    return TextFormField(
      controller: _personNameController,
      decoration: InputDecoration(
        labelText: isDebt ? 'Nama Pemberi Pinjaman' : 'Nama Penerima Pinjaman',
        hintText: isDebt ? 'Dari siapa?' : 'Ke siapa?',
        prefixIcon: Icon(Icons.person),
      ),
      maxLength: InputValidation.maxPersonName,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      validator: (v) => InputValidation.required(v, 'Nama'),
    );
  }

  Widget _buildDueDatePresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jatuh Tempo',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
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
                      ? Theme.of(context).colorScheme.onSurface
                      : null,
                ),
              ),
              avatar: Icon(Icons.calendar_today, size: 16),
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
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tanggal Transaksi',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormatter.formatDate(_selectedDate),
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      maxLines: 3,
      maxLength: 100,
      decoration: InputDecoration(
        labelText: 'Catatan (opsional)',
        hintText: _isTagihan ? 'Catatan tagihan...' : 'Tambahkan catatan...',
        alignLabelWithHint: true,
        counterText: '',
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.image,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Lampiran Foto (opsional)',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (_attachmentPath != null)
              IconButton(
                tooltip: 'Hapus foto',
                icon: Icon(Icons.close, size: 18),
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
                  icon: Icon(Icons.camera_alt, size: 18),
                  label: Text('Kamera'),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.photo_library, size: 18),
                  label: Text('Galeri'),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
      ],
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          );
        }
        return;
      }
      setState(() => _attachmentPath = file.path);
    }
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _isLoading ? null : _submit,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: _isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Simpan'),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final rawAmount = _amountController.text.replaceAll('.', '');
    final amount = double.parse(rawAmount);

    final walletProvider = context.read<WalletProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final debtProvider = context.read<DebtProvider>();
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
        description:
            '${debtType == 'debt' ? 'Tagihan Saya' : 'Tagihan Orang'} - ${_billNameController.text.trim()}',
        paymentMethod: _paymentMethod,
        attachmentPath: _attachmentPath,
      );
      final txnSuccess = await transactionProvider.addTransaction(transaction);
      if (!txnSuccess) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan'),
              backgroundColor: Theme.of(context).colorScheme.onSurface,
            ),
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
      success = await debtProvider.addDebt(debt);
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
      success = await transactionProvider.addTransaction(transaction);
    } else {
      final transaction = Transaction(
        type: _transactionType,
        amount: amount,
        walletId: wallet.id!,
        categoryId: null,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        date: _selectedDate,
        createdAt: DateTime.now(),
        description: _descriptionController.text.trim(),
        paymentMethod: _paymentMethod,
        attachmentPath: _attachmentPath,
      );

      success = await transactionProvider.addTransaction(transaction);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      if (_isTagihan) debtProvider.loadActiveDebts();
      walletProvider.loadWallets();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil disimpan',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan'),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }
  }
}
