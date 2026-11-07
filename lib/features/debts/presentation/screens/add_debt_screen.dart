import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/debt.dart';
import '../providers/debt_provider.dart';
import '../../../dashboard/presentation/providers/wallet_provider.dart';

class AddDebtScreen extends StatefulWidget {
  final String initialType;

  const AddDebtScreen({super.key, required this.initialType});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late String _selectedType;
  int? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  DateTime? _dueDate;
  bool _isLoading = false;
  bool _submitted = false;

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _today() => _dayOf(DateTime.now());

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    await context.read<WalletProvider>().loadWallets();
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _personLabel => _selectedType == 'debt'
      ? 'Nama Pemberi Pinjaman'
      : 'Nama Penerima Pinjaman';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Tanggal tagihan',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      // A due date before the debt date makes no sense; drop it.
      if (_dueDate != null && _dueDate!.isBefore(_dayOf(picked))) {
        _dueDate = null;
      }
    });
  }

  Future<void> _pickDueDate() async {
    final first = _dayOf(_selectedDate);
    final initial =
        _dueDate ??
        (first.isAfter(_today())
            ? first
            : _today().add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(_today().year + 10, 12, 31),
      helpText: 'Tanggal jatuh tempo',
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDebt = _selectedType == 'debt';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: CashBayAppBar(
        title: isDebt ? 'Tambah Tagihan' : 'Tambah Tagihan Orang',
        leading: IconButton(
          tooltip: 'Tutup',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, _) {
          final wallets = walletProvider.wallets;
          final selectedWallet = wallets
              .where((w) => w.id == _selectedWalletId)
              .firstOrNull;

          return Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedListItem(index: 0, child: _buildTypeSelector()),
                  const SizedBox(height: 24),
                  AnimatedListItem(
                    index: 1,
                    child: TextFormField(
                      controller: _personController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: _personLabel,
                        hintText: isDebt
                            ? 'Dari siapa Anda meminjam?'
                            : 'Ke siapa Anda meminjamkan?',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      maxLength: InputValidation.maxPersonName,
                      validator: (v) => InputValidation.name(
                        v,
                        _personLabel,
                        max: InputValidation.maxPersonName,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedListItem(
                    index: 2,
                    child: TextFormField(
                      controller: _amountController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [RupiahInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Jumlah',
                        prefixText: 'Rp ',
                        prefixIcon: Icon(Icons.payments_outlined),
                        hintText: '0',
                        errorMaxLines: 2,
                      ),
                      validator: InputValidation.amount,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedListItem(
                    index: 3,
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedWalletId,
                      isExpanded: true,
                      items: [
                        for (final wallet in wallets)
                          DropdownMenuItem(
                            value: wallet.id,
                            child: Text(
                              '${wallet.name} (${wallet.type == 'cash' ? 'Cash' : 'E-Wallet'})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _isLoading
                          ? null
                          : (value) =>
                                setState(() => _selectedWalletId = value),
                      decoration: InputDecoration(
                        labelText: isDebt
                            ? 'Dompet yang Menerima Dana'
                            : 'Dompet yang Mengeluarkan Dana',
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                        helperText: selectedWallet != null
                            ? 'Saldo ${CurrencyFormatter.format(selectedWallet.balance)}'
                            : null,
                      ),
                      validator: (value) =>
                          value == null ? 'Pilih dompet' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedListItem(
                    index: 4,
                    child: _buildDateField(
                      label: 'Tanggal',
                      icon: Icons.calendar_today_outlined,
                      value: DateFormatter.formatDate(_selectedDate),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedListItem(
                    index: 5,
                    child: _buildDateField(
                      label: 'Jatuh Tempo (opsional)',
                      icon: Icons.event_outlined,
                      value: _dueDate != null
                          ? DateFormatter.formatDate(_dueDate!)
                          : null,
                      placeholder: 'Pilih tanggal jatuh tempo',
                      onTap: _pickDueDate,
                      onClear: _dueDate != null
                          ? () => setState(() => _dueDate = null)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedListItem(
                    index: 6,
                    child: TextFormField(
                      controller: _noteController,
                      enabled: !_isLoading,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: InputValidation.maxNote,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Catatan (opsional)',
                        hintText: isDebt
                            ? 'Contoh: Pinjam uang untuk beli motor, tanpa bunga'
                            : 'Contoh: Pinjamkan uang ke teman untuk modal usaha',
                        hintMaxLines: 2,
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => InputValidation.maxLength(
                        v,
                        'Catatan',
                        InputValidation.maxNote,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedListItem(
                    index: 7,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Simpan ${isDebt ? "Tagihan" : "Tagihan Orang"}',
                              style: textTheme.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required String? value,
    required VoidCallback onTap,
    String? placeholder,
    VoidCallback? onClear,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: onClear != null
              ? IconButton(
                  tooltip: 'Hapus $label',
                  icon: const Icon(Icons.close),
                  onPressed: _isLoading ? null : onClear,
                )
              : Icon(Icons.arrow_drop_down, color: scheme.onSurfaceVariant),
        ),
        child: Text(
          value ?? placeholder ?? '',
          style: textTheme.bodyLarge?.copyWith(
            color: value == null ? scheme.onSurfaceVariant : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jenis', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'debt',
                icon: Icon(Icons.arrow_upward),
                label: Text('Tagihan Saya'),
              ),
              ButtonSegment(
                value: 'receivable',
                icon: Icon(Icons.arrow_downward),
                label: Text('Tagihan Orang'),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: _isLoading
                ? null
                : (selection) {
                    setState(() => _selectedType = selection.first);
                  },
            showSelectedIcon: false,
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      ToastWidget.error(context, 'Periksa kembali data yang diisi');
      return;
    }

    setState(() => _isLoading = true);

    final amount = InputValidation.parseAmount(_amountController.text)!;
    final note = _noteController.text.trim();

    final debt = Debt(
      type: _selectedType,
      personName: _personController.text.trim(),
      amount: amount,
      remainingAmount: amount,
      walletId: _selectedWalletId!,
      status: 'active',
      note: note.isEmpty ? null : note,
      date: _selectedDate,
      dueDate: _dueDate,
    );

    final provider = context.read<DebtProvider>();
    final success = await provider.addDebt(debt);

    if (!mounted) return;
    if (success) {
      ToastWidget.success(context, 'Tagihan berhasil ditambahkan');
      Navigator.pop(context, true);
    } else {
      setState(() => _isLoading = false);
      ToastWidget.error(
        context,
        'Gagal menyimpan: ${provider.error ?? 'terjadi kesalahan'}',
      );
    }
  }
}
