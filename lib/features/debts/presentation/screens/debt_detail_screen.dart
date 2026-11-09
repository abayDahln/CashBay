import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/debt.dart';
import '../../data/models/debt_payment.dart';
import '../providers/debt_provider.dart';
import '../../../dashboard/presentation/providers/wallet_provider.dart';
import 'debts_screen.dart' show DebtStatusBadge;

class DebtDetailScreen extends StatefulWidget {
  final Debt debt;

  const DebtDetailScreen({super.key, required this.debt});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  late Debt _debt;
  List<DebtPayment> _payments = [];

  bool get isDebt => _debt.type == 'debt';

  double get _paidRatio => _debt.amount > 0
      ? ((_debt.amount - _debt.remainingAmount) / _debt.amount).clamp(0.0, 1.0)
      : 0.0;

  @override
  void initState() {
    super.initState();
    _debt = widget.debt;
    _loadPayments();
    final walletProvider = context.read<WalletProvider>();
    if (walletProvider.wallets.isEmpty) walletProvider.loadWallets();
  }

  Future<void> _loadPayments() async {
    final provider = context.read<DebtProvider>();
    await provider.loadDebtPayments(_debt.id!);
    if (mounted) {
      setState(() {
        _payments = List.of(provider.selectedDebtPayments);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CashBayAppBar(
        title: isDebt ? 'Detail Titipan' : 'Detail Titipan Orang',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedListItem(index: 0, child: _buildSummaryCard()),
            const SizedBox(height: 16),
            AnimatedListItem(index: 1, child: _buildInfoCard()),
            const SizedBox(height: 16),
            AnimatedListItem(index: 2, child: _buildPaymentSection()),
          ],
        ),
      ),
      bottomNavigationBar: _debt.status == 'active'
          ? _buildAddPaymentBar()
          : null,
    );
  }

  Widget _buildSummaryCard() {
    final paid = _debt.amount - _debt.remainingAmount;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Icon(isDebt ? Icons.arrow_upward : Icons.arrow_downward),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _debt.personName,
                  style: textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              DebtStatusBadge(isPaid: _debt.status == 'paid'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Sisa',
            style: textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(_debt.remainingAmount),
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _paidRatio),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  semanticsLabel: 'Progres pembayaran',
                  semanticsValue: '${(value * 100).round()}%',
                ),
                const SizedBox(height: 8),
                Text(
                  '${(value * 100).toStringAsFixed(0)}% ${isDebt ? 'dibayar' : 'diterima'}',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total ${isDebt ? 'Titipan' : 'Titipan Orang'}',
                  CurrencyFormatter.format(_debt.amount),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Telah ${isDebt ? 'Dibayar' : 'Diterima'}',
                  CurrencyFormatter.format(paid),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: textTheme.titleMedium),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    final wallet = context
        .watch<WalletProvider>()
        .wallets
        .where((w) => w.id == _debt.walletId)
        .firstOrNull;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Informasi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Tanggal',
            DateFormatter.formatDate(_debt.date),
          ),
          if (_debt.dueDate != null)
            _buildInfoRow(
              Icons.event_outlined,
              'Jatuh tempo',
              DateFormatter.formatDate(_debt.dueDate!),
            ),
          if (wallet != null)
            _buildInfoRow(
              Icons.account_balance_wallet_outlined,
              'Dompet',
              wallet.name,
            ),
          if (_debt.note?.isNotEmpty == true)
            _buildInfoRow(Icons.notes, 'Catatan', _debt.note!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }

  Widget _buildPaymentSection() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_payments.isEmpty) {
      return AppCard(
        variant: AppCardVariant.outlined,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.history, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              'Belum ada histori pengembalian',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Histori Pengembalian',
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_payments.length} transaksi',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final entry in _payments.asMap().entries) ...[
            if (entry.key > 0)
              Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: scheme.outlineVariant,
              ),
            AnimatedListItem(
              index: entry.key,
              child: _buildPaymentTile(entry.value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentTile(DebtPayment payment) {
    final scheme = Theme.of(context).colorScheme;
    final wallet = context
        .read<WalletProvider>()
        .wallets
        .where((w) => w.id == payment.walletId)
        .firstOrNull;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        child: Icon(isDebt ? Icons.arrow_upward : Icons.arrow_downward),
      ),
      title: Text(
        CurrencyFormatter.format(payment.amount),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          DateFormatter.formatDate(payment.date),
          if (wallet != null) wallet.name,
        ].join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAddPaymentBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _showAddPaymentDialog,
          icon: const Icon(Icons.add),
          label: Text(isDebt ? 'Terima Pengembalian' : 'Kembalikan Uang'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ),
    );
  }

  Future<void> _showAddPaymentDialog() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _AddPaymentSheet(debt: _debt),
    );
    if (saved != true || !mounted) return;

    final provider = context.read<DebtProvider>();
    await _loadPayments();
    if (!mounted) return;
    final updated = [
      ...provider.debts,
      ...provider.receivables,
    ].where((d) => d.id == _debt.id).firstOrNull;
    if (updated != null) setState(() => _debt = updated);
    ToastWidget.success(
      context,
      'Pengembalian berhasil dicatat',
    );
  }
}

/// Bottom sheet form for recording an installment. Pops `true` on success.
class _AddPaymentSheet extends StatefulWidget {
  final Debt debt;
  const _AddPaymentSheet({required this.debt});

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  late DateTime _selectedDate;
  int? _walletId;
  bool _submitted = false;
  bool _isSaving = false;

  Debt get _debt => widget.debt;
  bool get _isDebt => _debt.type == 'debt';

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    // Preselect the wallet the debt was recorded with, if it still exists.
    final wallets = context.read<WalletProvider>().wallets;
    if (wallets.any((w) => w.id == _debt.walletId)) _walletId = _debt.walletId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? v) {
    // Only the remaining titipan caps the amount. Wallet balance is not a
    // limit: a titipan can be settled from the titipan money itself, so a
    // wallet may legitimately go negative here.
    return InputValidation.amountInRange(
      v,
      max: _debt.remainingAmount,
      maxMessage:
          'Melebihi sisa titipan (${CurrencyFormatter.format(_debt.remainingAmount)})',
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final debtDay = DateTime(_debt.date.year, _debt.date.month, _debt.date.day);
    final first = debtDay.isAfter(today) ? today : debtDay;
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(first) ? first : _selectedDate,
      firstDate: first,
      lastDate: now,
      helpText: 'Tanggal pengembalian',
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<DebtProvider>();
    final walletProvider = context.read<WalletProvider>();
    final success = await provider.addPayment(
      DebtPayment(
        debtId: _debt.id!,
        amount: InputValidation.parseAmount(_amountController.text)!,
        walletId: _walletId!,
        date: _selectedDate,
      ),
    );
    if (!mounted) return;

    if (success) {
      await walletProvider.loadWallets();
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() => _isSaving = false);
      ToastWidget.error(
        context,
        'Gagal menyimpan: ${provider.error ?? 'terjadi kesalahan'}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final wallets = context.watch<WalletProvider>().wallets;
    final remaining = CurrencyFormatter.format(_debt.remainingAmount);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Icon(
                      _isDebt ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isDebt ? 'Terima Pengembalian' : 'Kembalikan Uang',
                      style: textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [RupiahInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  prefixText: 'Rp ',
                  hintText: '0',
                  helperText: 'Sisa titipan $remaining',
                  helperMaxLines: 2,
                  errorMaxLines: 2,
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _amountController.text =
                          RupiahInputFormatter.formatValue(
                            _debt.remainingAmount,
                          ),
                icon: const Icon(Icons.done_all, size: 18),
                label: Text('Lunasi $remaining'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _walletId,
                isExpanded: true,
                items: [
                  for (final w in wallets)
                    DropdownMenuItem(
                      value: w.id,
                      child: Text(
                        w.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _isSaving
                    ? null
                    : (v) => setState(() => _walletId = v),
                decoration: InputDecoration(
                  labelText: _isDebt ? 'Masuk ke dompet' : 'Keluar dari dompet',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (v) => v == null ? 'Pilih dompet' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _isSaving ? null : _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tanggal',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(
                      Icons.arrow_drop_down,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  child: Text(
                    DateFormatter.formatDate(_selectedDate),
                    style: textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
