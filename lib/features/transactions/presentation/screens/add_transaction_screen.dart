import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/formatters.dart'
    show
        CurrencyFormatter,
        DateFormatter,
        InputValidation,
        RupiahInputFormatter;
import '../../../../core/widgets/widgets.dart';
import '../../data/models/transaction.dart';
import '../../../debts/data/models/debt.dart';
import '../providers/transaction_provider.dart';
import '../../../debts/presentation/providers/debt_provider.dart';
import '../../../dashboard/data/models/wallet.dart';
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
  bool _submitted = false;
  String? _attachmentPath;
  final ImagePicker _picker = ImagePicker();

  bool get _isTagihan => _transactionType == 'tagihan';
  bool get _isTransfer => _transactionType == 'transfer';
  String get _destinationWallet =>
      _paymentMethod == 'cash' ? 'ewallet' : 'cash';

  /// Expense and transfer spend from the source wallet, so the amount is
  /// capped by its balance.
  bool get _spendsFromWallet =>
      _transactionType == 'expense' || _transactionType == 'transfer';

  static String _walletLabel(String type) =>
      type == 'cash' ? 'Cash' : 'E-Wallet';

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

  /// Raw value of the amount field, 0 when empty.
  double get _amountValue =>
      InputValidation.parseAmount(_amountController.text) ?? 0;

  void _setAmount(double value) {
    final formatted = RupiahInputFormatter.formatValue(value);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  Wallet? _walletOfType(List<Wallet> wallets, String type) =>
      wallets.where((w) => w.type == type).firstOrNull;

  String? _validateAmount(String? v) {
    if (!_spendsFromWallet) return InputValidation.amountInRange(v);
    final wallet = _walletOfType(
      context.read<WalletProvider>().wallets,
      _paymentMethod,
    );
    if (wallet == null) return InputValidation.amountInRange(v);
    final balance = wallet.balance < 0 ? 0.0 : wallet.balance;
    return InputValidation.amountInRange(
      v,
      max: balance,
      maxMessage:
          'Saldo ${wallet.name} tidak cukup (sisa ${CurrencyFormatter.format(balance)})',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CashBayAppBar(title: 'Tambah Transaksi'),
      body: Consumer3<WalletProvider, CategoryProvider, DebtProvider>(
        builder: (context, walletProvider, categoryProvider, debtProvider, _) {
          final wallets = walletProvider.wallets;
          return Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAnimatedField(0, _buildTypeSelector()),
                        const SizedBox(height: 16),
                        _buildAnimatedField(0, _buildAmountField(wallets)),
                        const SizedBox(height: 24),
                        _buildInsetGroup('Detail utama', [
                          if (_isTagihan) ...[
                            _buildDebtDirectionSelector(),
                            const SizedBox(height: 16),
                            _buildBillNameField(),
                            const SizedBox(height: 8),
                            _buildPersonNameField(),
                            const SizedBox(height: 8),
                            _buildDueDatePresets(),
                          ] else if (_isTransfer) ...[
                            _buildTransferSelector(wallets),
                            const SizedBox(height: 16),
                            _buildDescriptionField(),
                          ] else ...[
                            _buildDescriptionField(),
                          ],
                        ]),
                        const SizedBox(height: 24),
                        _buildInsetGroup('Sumber dana & waktu', [
                          if (!_isTransfer) ...[
                            _buildPaymentMethod(wallets),
                            const SizedBox(height: 16),
                          ],
                          _buildDatePicker(),
                        ]),
                        const SizedBox(height: 24),
                        _buildInsetGroup('Catatan & lampiran', [
                          _buildNoteField(),
                          const SizedBox(height: 8),
                          _buildPhotoPicker(),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
              // Pinned save button: the Scaffold body shrinks above the
              // keyboard, so this stays visible while typing.
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _buildSubmitButton(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInsetGroup(String label, List<Widget> children) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: scheme.primary),
          ),
        ),
        AppCard(
          variant: AppCardVariant.outlined,
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
      ('income', Icons.south, 'Pendapatan'),
      ('expense', Icons.north, 'Pengeluaran'),
      ('tagihan', Icons.receipt_long, 'Tagihan'),
      ('transfer', Icons.swap_horiz, 'Transfer'),
    ];
    // Horizontally scrollable so all four fit on 360dp / large text scale.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (value, icon, label) in types)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(icon, size: 18),
                showCheckmark: false,
                label: Text(label),
                selected: _transactionType == value,
                onSelected: (_) => setState(() => _transactionType = value),
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
        Text('Arah Tagihan', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'debt',
                icon: Icon(Icons.north),
                label: Text(
                  'Tagihan Saya',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ButtonSegment(
                value: 'receivable',
                icon: Icon(Icons.south),
                label: Text(
                  'Tagihan Orang',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            selected: {_debtDirection},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _debtDirection = s.first),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField(List<Wallet> wallets) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasValue = _amountValue > 0;
    const quickAmounts = <int>[10000, 20000, 50000, 100000];
    final display = _amountController.text.isEmpty
        ? '0'
        : _amountController.text;
    final amountStyle = text.displaySmall?.copyWith(
      color: hasValue ? scheme.onSurface : scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final source = _spendsFromWallet
        ? _walletOfType(wallets, _paymentMethod)
        : null;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
          Text(
            'Nominal transaksi',
            style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Balances the clear button so the amount stays centred.
              const SizedBox(width: 48),
              Expanded(
                // The TextFormField stays transparent and handles input /
                // validation; the visible Text is auto-scaled to avoid wrap.
                child: Stack(
                  alignment: Alignment.topCenter,
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
                              style: text.titleLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(display, style: amountStyle),
                          ],
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [RupiahInputFormatter()],
                      onChanged: (_) => setState(() {}),
                      textAlign: TextAlign.center,
                      cursorHeight: 32,
                      style: amountStyle?.copyWith(color: Colors.transparent),
                      decoration: const InputDecoration(
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        errorMaxLines: 2,
                      ),
                      validator: _validateAmount,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 48,
                child: hasValue
                    ? IconButton(
                        tooltip: 'Kosongkan nominal',
                        icon: Icon(
                          Icons.cancel,
                          color: scheme.onSurfaceVariant,
                        ),
                        onPressed: () => _setAmount(0),
                      )
                    : null,
              ),
            ],
          ),
          if (source != null) ...[
            const SizedBox(height: 4),
            Text(
              'Saldo ${source.name}: ${CurrencyFormatter.format(source.balance)}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final amount in quickAmounts)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(CurrencyFormatter.formatShort(amount.toDouble())),
                  tooltip:
                      'Tambah ${CurrencyFormatter.format(amount.toDouble())}',
                  onPressed: () => _setAmount(_amountValue + amount),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    final isIncome = _transactionType == 'income';
    return TextFormField(
      controller: _descriptionController,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: _isTransfer
            ? 'Keterangan (opsional)'
            : isIncome
            ? 'Sumber Pendapatan'
            : 'Nama Transaksi',
        hintText: _isTransfer
            ? 'Contoh: Pindah ke E-Wallet'
            : isIncome
            ? 'Contoh: Gaji, Freelance'
            : 'Contoh: Makan siang, Bensin',
        prefixIcon: const Icon(Icons.edit_note),
      ),
      maxLength: InputValidation.maxDescription,
      validator: (v) {
        if (!_isTransfer) {
          final req = InputValidation.required(v, 'Deskripsi');
          if (req != null) return req;
        }
        return InputValidation.maxLength(
          v,
          'Deskripsi',
          InputValidation.maxDescription,
        );
      },
    );
  }

  Widget _buildTransferSelector(List<Wallet> wallets) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget walletTile(String caption, String type, CrossAxisAlignment align) {
      final wallet = _walletOfType(wallets, type);
      return Column(
        crossAxisAlignment: align,
        children: [
          Text(
            caption,
            style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type == 'cash' ? Icons.payments_outlined : Icons.phone_android,
                size: 18,
                color: scheme.onSurface,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _walletLabel(type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
              ),
            ],
          ),
          if (wallet != null)
            Text(
              CurrencyFormatter.format(wallet.balance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: walletTile('Dari', _paymentMethod, CrossAxisAlignment.start),
        ),
        IconButton.filledTonal(
          tooltip: 'Tukar dompet',
          icon: const Icon(Icons.swap_horiz),
          onPressed: () => setState(() => _paymentMethod = _destinationWallet),
        ),
        Expanded(
          child: walletTile('Ke', _destinationWallet, CrossAxisAlignment.end),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(List<Wallet> wallets) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final selected = _walletOfType(wallets, _paymentMethod);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isTagihan
              ? 'Metode Pembayaran'
              : _transactionType == 'income'
              ? 'Tujuan Dana'
              : 'Sumber Dana',
          style: text.labelLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'cash',
                icon: Icon(Icons.payments_outlined),
                label: Text('Cash'),
              ),
              ButtonSegment(
                value: 'ewallet',
                icon: Icon(Icons.phone_android),
                label: Text('E-Wallet'),
              ),
            ],
            selected: {_paymentMethod},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _paymentMethod = s.first),
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'Saldo: ${CurrencyFormatter.format(selected.balance)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBillNameField() {
    return TextFormField(
      controller: _billNameController,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Nama Tagihan',
        hintText: 'Contoh: Pinjaman Motor, Cicilan Rumah',
        prefixIcon: Icon(Icons.description_outlined),
      ),
      maxLength: InputValidation.maxBillName,
      validator: (v) => InputValidation.name(
        v,
        'Nama Tagihan',
        max: InputValidation.maxBillName,
      ),
    );
  }

  Widget _buildPersonNameField() {
    final isDebt = _debtDirection == 'debt';
    return TextFormField(
      controller: _personNameController,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: isDebt ? 'Nama Pemberi Pinjaman' : 'Nama Penerima Pinjaman',
        hintText: isDebt ? 'Dari siapa?' : 'Ke siapa?',
        prefixIcon: const Icon(Icons.person_outline),
      ),
      maxLength: InputValidation.maxPersonName,
      validator: (v) =>
          InputValidation.name(v, 'Nama', max: InputValidation.maxPersonName),
    );
  }

  Widget _buildDueDatePresets() {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isCustom = _duePreset == DueDatePreset.custom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jatuh Tempo', style: text.labelLarge),
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
            ChoiceChip(
              avatar: const Icon(Icons.calendar_today, size: 18),
              showCheckmark: false,
              label: Text(
                isCustom ? DateFormatter.formatDate(_dueDate) : 'Pilih Tanggal',
              ),
              selected: isCustom,
              onSelected: (_) async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate.isBefore(DateTime.now())
                      ? DateTime.now()
                      : _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null && mounted) {
                  setState(() {
                    _dueDate = picked;
                    _duePreset = DueDatePreset.custom;
                  });
                }
              },
            ),
          ],
        ),
        if (!isCustom)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Jatuh tempo: ${DateFormatter.formatDate(_dueDate)}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
        if (picked != null && mounted) {
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
          prefixIcon: Icon(Icons.calendar_today_outlined),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          DateFormatter.formatDate(_selectedDate),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      minLines: 2,
      maxLines: 4,
      maxLength: InputValidation.maxNote,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        labelText: 'Catatan (opsional)',
        hintText: _isTagihan ? 'Catatan tagihan...' : 'Tambahkan catatan...',
        alignLabelWithHint: true,
      ),
      validator: (v) =>
          InputValidation.maxLength(v, 'Catatan', InputValidation.maxNote),
    );
  }

  Widget _buildPhotoPicker() {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.image_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lampiran Foto (opsional)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (_attachmentPath != null)
              IconButton(
                tooltip: 'Hapus foto',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _attachmentPath = null),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_attachmentPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_attachmentPath!),
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              semanticLabel: 'Lampiran foto',
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Kamera'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galeri'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
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
    if (file == null || !mounted) return;
    final err = InputValidation.imageFile(file.path);
    if (err != null) {
      ToastWidget.error(context, err);
      return;
    }
    setState(() => _attachmentPath = file.path);
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

  String? _optionalText(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (_isLoading) return; // prevent double submit
    FocusScope.of(context).unfocus();
    if (!_submitted) setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final walletProvider = context.read<WalletProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final debtProvider = context.read<DebtProvider>();
    final wallet = _walletOfType(walletProvider.wallets, _paymentMethod);
    if (wallet == null) {
      ToastWidget.error(context, 'Dompet tidak ditemukan');
      return;
    }
    final destWallet = _isTransfer
        ? _walletOfType(walletProvider.wallets, _destinationWallet)
        : null;
    if (_isTransfer && (destWallet == null || destWallet.id == wallet.id)) {
      ToastWidget.error(context, 'Dompet asal dan tujuan harus berbeda');
      return;
    }

    final amount = InputValidation.parseAmount(_amountController.text)!;
    final note = _optionalText(_noteController);

    setState(() => _isLoading = true);

    bool success;

    if (_isTagihan) {
      final debtType = _debtDirection;
      final transaction = Transaction(
        type: 'expense',
        amount: amount,
        walletId: wallet.id!,
        categoryId: null,
        note: _optionalText(_personNameController) ?? note,
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
          ToastWidget.error(context, 'Gagal menyimpan');
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
        note: note,
        date: _selectedDate,
        billName: _billNameController.text.trim(),
        dueDate: _dueDate,
        reminderEnabled: true,
        paymentMethod: _paymentMethod,
        attachmentPath: _attachmentPath,
      );
      success = await debtProvider.addDebt(debt);
    } else if (_isTransfer) {
      final transaction = Transaction(
        type: 'transfer',
        amount: amount,
        walletId: wallet.id!,
        toWalletId: destWallet!.id,
        categoryId: null,
        note: note,
        date: _selectedDate,
        createdAt: DateTime.now(),
        description:
            _optionalText(_descriptionController) ??
            'Transfer ke ${_walletLabel(_destinationWallet)}',
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
        note: note,
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
      ToastWidget.success(context, 'Berhasil disimpan');
      Navigator.pop(context, true);
    } else {
      ToastWidget.error(context, 'Gagal menyimpan');
    }
  }
}
