import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart'
    show DateFormatter, InputValidation;
import '../../../../core/widgets/widgets.dart';
import '../../data/models/debt.dart';
import '../../../dashboard/data/models/wallet.dart';
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
  Wallet? _selectedWallet;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

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

  @override
  Widget build(BuildContext context) {
    final isDebt = _selectedType == 'debt';
    final color = isDebt
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: CashBayAppBar(
        title: isDebt ? 'Tambah Tagihan' : 'Tambah Tagihan Orang',
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, _) {
            final wallets = walletProvider.wallets;

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedListItem(
                      index: 0,
                      child: _buildTypeSelector(isDebt, color),
                    ),
                    const SizedBox(height: 24),
                    AnimatedListItem(
                      index: 1,
                      child: TextFormField(
                        controller: _personController,
                        decoration: InputDecoration(
                          labelText: isDebt
                              ? 'Nama Pemberi Pinjaman'
                              : 'Nama Penerima Pinjaman',
                          hintText: isDebt
                              ? 'Dari siapa Anda meminjam?'
                              : 'Ke siapa Anda meminjamkan?',
                          prefixIcon: const Icon(Icons.person),
                        ),
                        maxLength: InputValidation.maxPersonName,
                        validator: (v) => InputValidation.required(
                          v,
                          isDebt
                              ? 'Nama Pemberi Pinjaman'
                              : 'Nama Penerima Pinjaman',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedListItem(
                      index: 2,
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah',
                          prefixText: 'Rp ',
                          prefixIcon: Icon(Icons.attach_money),
                          hintText: 'Masukkan nominal',
                        ),
                        validator: InputValidation.amount,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedListItem(
                      index: 3,
                      child: DropdownButtonFormField<Wallet>(
                        initialValue: _selectedWallet,
                        items: wallets
                            .map(
                              (wallet) => DropdownMenuItem(
                                value: wallet,
                                child: Text(
                                  '${wallet.name} (${wallet.type == 'cash' ? 'Cash' : 'E-Wallet'})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedWallet = value),
                        decoration: InputDecoration(
                          labelText: isDebt
                              ? 'Dompet yang Menerima Dana'
                              : 'Dompet yang Mengeluarkan Dana',
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                        ),
                        validator: (value) =>
                            value == null ? 'Pilih dompet' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedListItem(
                      index: 4,
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormatter.formatDate(_selectedDate),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedListItem(
                      index: 5,
                      child: TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        maxLength: InputValidation.maxNote,
                        decoration: InputDecoration(
                          labelText: 'Catatan (opsional)',
                          hintText: isDebt
                              ? 'Contoh: Pinjam uang untuk beli motor, tanpa bunga'
                              : 'Contoh: Pinjamkan uang ke teman untuk modal usaha',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AnimatedListItem(
                      index: 6,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: color,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                  ),
                                )
                              : Text(
                                  'Simpan ${isDebt ? "Tagihan" : "Tagihan Orang"}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
      ),
    );
  }

  Widget _buildTypeSelector(bool isDebt, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
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
          onSelectionChanged: (selection) {
            setState(() => _selectedType = selection.first);
          },
          showSelectedIcon: false,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWallet == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih dompet')));
      return;
    }

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text.replaceAll('.', ''));

    final debt = Debt(
      type: _selectedType,
      personName: _personController.text.trim(),
      amount: amount,
      remainingAmount: amount,
      walletId: _selectedWallet!.id!,
      status: 'active',
      note: _noteController.text.isEmpty ? null : _noteController.text.trim(),
      date: _selectedDate,
    );

    final provider = context.read<DebtProvider>();
    final success = await provider.addDebt(debt);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tagihan berhasil ditambahkan')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: ${provider.error}')));
      }
    }
  }
}
