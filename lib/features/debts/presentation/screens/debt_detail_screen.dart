import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart' show CurrencyFormatter, DateFormatter, InputValidation;
import '../../../../core/widgets/widgets.dart';
import '../../data/models/debt.dart';
import '../../data/models/debt_payment.dart';
import '../../../dashboard/data/models/wallet.dart';
import '../providers/debt_provider.dart';
import '../../../dashboard/presentation/providers/wallet_provider.dart';

class DebtDetailScreen extends StatefulWidget {
  final Debt debt;

  const DebtDetailScreen({super.key, required this.debt});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen>
    with SingleTickerProviderStateMixin {
  late Debt _debt;
  List<DebtPayment> _payments = [];
  bool _isLoading = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _debt = widget.debt;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: _debt.amount > 0
          ? (_debt.amount - _debt.remainingAmount) / _debt.amount
          : 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    _progressController.forward();
    _loadPayments();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    final provider = context.read<DebtProvider>();
    await provider.loadDebtPayments(_debt.id!);
    if (mounted) {
      setState(() {
        _payments = provider.selectedDebtPayments;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDebt = _debt.type == 'debt';
    final color = isDebt ? AppTheme.black : AppTheme.darkGray;

    return Scaffold(
      appBar: CashBayAppBar(
        title: isDebt ? 'Detail Tagihan' : 'Detail Tagihan Orang',
        actions: [
          if (_debt.status == 'active')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showEditDialog,
            ),
        ],
      ),
      body: AppCard(
        radius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedListItem(
                index: 0,
                child: _buildSummaryCard(color),
              ),
              const SizedBox(height: 16),
              AnimatedListItem(
                index: 1,
                child: _buildInfoCard(),
              ),
              const SizedBox(height: 16),
              AnimatedListItem(
                index: 2,
                child: _buildPaymentSection(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _debt.status == 'active'
          ? _buildAddPaymentBar(color)
          : null,
    );
  }

  Widget _buildSummaryCard(Color color) {
    final paid = _debt.amount - _debt.remainingAmount;

    return AppCard(
      padding: const EdgeInsets.all(20),
      radius: BorderRadius.circular(18),
      boxShadow: AppTheme.cardShadow,
      border: Border.all(color: color.withOpacity(0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDebt ? Icons.arrow_upward : Icons.arrow_downward,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _debt.personName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _debt.status == 'active'
                      ? color.withOpacity(0.1)
                      : AppTheme.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _debt.status == 'active' ? 'Aktif' : 'Lunas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        _debt.status == 'active' ? color : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total ${isDebt ? 'Tagihan' : 'Tagihan Orang'}',
                  CurrencyFormatter.format(_debt.amount),
                  color,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Sisa',
                  CurrencyFormatter.format(_debt.remainingAmount),
                  _debt.remainingAmount > 0 ? color : AppTheme.textSecondary,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Telah ${isDebt ? 'Dibayar' : 'Diterima'}',
                  CurrencyFormatter.format(paid),
                  AppTheme.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 10,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Text(
                '${(_progressAnimation.value * 100).toStringAsFixed(0)}% ${isDebt ? 'dibayar' : 'diterima'}',
                style: TextStyle(fontSize: 12, color: color),
              );
            },
          ),
        ],
      ),
    );
  }

  bool get isDebt => _debt.type == 'debt';

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: AppTheme.textSecondary),
              SizedBox(width: 8),
              Text(
                'Informasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Tanggal', DateFormatter.formatDate(_debt.date)),
          if (_debt.note?.isNotEmpty == true)
            _buildInfoRow('Catatan', _debt.note!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    if (_payments.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'Belum ada histori ${isDebt ? 'pembayaran' : 'penerimaan'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Histori ${isDebt ? 'Pembayaran' : 'Penerimaan'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_payments.length} transaksi',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          ..._payments.asMap().entries.map(
                (entry) => AnimatedListItem(
                  index: entry.key,
                  child: _buildPaymentTile(entry.value),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(DebtPayment payment) {
    final isDebt = _debt.type == 'debt';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDebt ? AppTheme.black : AppTheme.darkGray)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDebt ? Icons.arrow_downward : Icons.arrow_upward,
              color: isDebt ? AppTheme.black : AppTheme.darkGray,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              CurrencyFormatter.format(payment.amount),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormatter.formatDate(payment.date),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPaymentBar(Color color) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PressCard(
          child: FilledButton.icon(
            onPressed: _showAddPaymentDialog,
            icon: const Icon(Icons.add),
            label: Text(isDebt ? 'Bayar Cicilan' : 'Terima Cicilan'),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPaymentDialog() {
    final color = isDebt ? AppTheme.black : AppTheme.darkGray;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    Wallet? selectedWallet;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AppCard(
                radius: const BorderRadius.all(Radius.circular(20)),
        padding: const EdgeInsets.all(16),
        child: Consumer<WalletProvider>(
          builder: (context, walletProvider, _) {
            final wallets = walletProvider.wallets;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDebt
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isDebt ? 'Bayar Cicilan' : 'Terima Cicilan',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    prefixText: 'Rp ',
                    hintText: 'Masukkan nominal',
                  ),
                  validator: InputValidation.amount,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Wallet>(
                  value: selectedWallet,
                  items: wallets
                      .map((w) => DropdownMenuItem(
                            value: w,
                            child: Text(w.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedWallet = v),
                  decoration: const InputDecoration(labelText: 'Dompet'),
                  validator: (v) => v == null ? 'Pilih dompet' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    hintText: 'Catatan cicilan',
                  ),
                  maxLines: 2,
                  maxLength: InputValidation.maxNote,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            selectedDate = date;
                            setState(() {});
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          DateFormatter.formatShortDate(selectedDate),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (amountController.text.isEmpty ||
                          selectedWallet == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Isi jumlah dan pilih dompet'),
                          ),
                        );
                        return;
                      }

                      final amount =
                          double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nominal tidak valid'),
                          ),
                        );
                        return;
                      }

                      if (amount > _debt.remainingAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Maksimal ${CurrencyFormatter.format(_debt.remainingAmount)}',
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(ctx);

                      final provider = context.read<DebtProvider>();
                      final success = await provider.addPayment(
                        DebtPayment(
                          debtId: _debt.id!,
                          amount: amount,
                          walletId: selectedWallet!.id!,
                          date: selectedDate,
                        ),
                      );

                      if (success) {
                        await _loadPayments();
                        setState(() {
                          _debt = provider.debts
                              .firstWhere((d) => d.id == _debt.id);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${isDebt ? "Pembayaran" : "Penerimaan"} berhasil dicatat',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Gagal: ${provider.error}'),
                          ),
                        );
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  void _showEditDialog() {}
}
