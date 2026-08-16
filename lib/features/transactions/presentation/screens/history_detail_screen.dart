import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart' show CurrencyFormatter, DateFormatter, InputValidation;
import '../../../../core/widgets/widgets.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../dashboard/presentation/providers/wallet_provider.dart';

class HistoryDetailScreen extends StatefulWidget {
  final Transaction transaction;
  const HistoryDetailScreen({super.key, required this.transaction});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late Transaction _transaction;
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _descriptionController;
  late TextEditingController _noteController;
  String? _newAttachmentPath;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    _descriptionController = TextEditingController(text: _transaction.description ?? '');
    _noteController = TextEditingController(text: _transaction.note ?? '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isTransfer => _transaction.type == 'transfer';
  bool get _isIncome => _transaction.type == 'income';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CashBayAppBar(
        title: _typeLabel,
        actions: [
                if (!_isEditing)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') setState(() => _isEditing = true);
                      if (v == 'delete') _confirmDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'), dense: true)),
                      const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: AppTheme.black), title: Text('Hapus', style: TextStyle(color: AppTheme.black)), dense: true)),
                    ],
                  ),
                if (_isEditing) ...[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _descriptionController.text = _transaction.description ?? '';
                        _noteController.text = _transaction.note ?? '';
                        _newAttachmentPath = null;
                      });
                    },
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: _saveEdit,
                    child: const Text('Simpan'),
                  ),
                ],
        ],
      ),
      body: AppCard(
        radius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTypeBadge(),
                    const SizedBox(height: 20),
                    _buildAmountCard(),
                    const SizedBox(height: 16),
                    if (_transaction.attachmentPath != null || _isEditing) ...[
                      _buildPhotoSection(),
                      const SizedBox(height: 16),
                    ],
                    _buildDetailCard(),
                    const SizedBox(height: 16),
                    if (_isEditing) ...[
                      _buildEditCard(),
                      const SizedBox(height: 20),
                      _buildEditActions(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  String get _typeLabel {
    if (_transaction.isTagihan) return 'Detail Tagihan';
    if (_transaction.isPembayaranTagihan) return 'Detail Pembayaran';
    if (_transaction.isPenerimaanTagihan) return 'Detail Penerimaan';
    if (_isTransfer) return 'Detail Transfer';
    if (_isIncome) return 'Detail Pendapatan';
    return 'Detail Pengeluaran';
  }

  Color get _typeColor {
    if (_isIncome || _transaction.isPenerimaanTagihan) return AppTheme.black;
    if (_isTransfer) return AppTheme.textSecondary;
    return AppTheme.black;
  }

  String get _paymentMethodLabel =>
      _transaction.paymentMethod == 'ewallet' ? 'E-Wallet' : 'Cash';

  String _categoryName() {
    final tx = _transaction;
    if (tx.categoryId == null) return '-';
    final catProvider = context.read<CategoryProvider>();
    final all = [...catProvider.incomeCategories, ...catProvider.expenseCategories];
    for (final c in all) {
      if (c.id == tx.categoryId) return c.name;
    }
    return '-';
  }

  String _walletName(int? id) {
    if (id == null) return '-';
    final walletProvider = context.read<WalletProvider>();
    for (final w in walletProvider.wallets) {
      if (w.id == id) return w.name;
    }
    return 'ID: $id';
  }

  Widget _buildTypeBadge() {
    IconData icon;
    if (_transaction.isTagihan) icon = Icons.receipt_long;
    else if (_transaction.isPembayaranTagihan) icon = Icons.check_circle_outline;
    else if (_transaction.isPenerimaanTagihan) icon = Icons.file_download;
    else if (_isTransfer) icon = Icons.swap_horiz;
    else if (_isIncome) icon = Icons.arrow_downward;
    else icon = Icons.arrow_upward;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _typeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _typeColor, size: 18),
            const SizedBox(width: 6),
            Text(
              _typeLabel.replaceFirst('Detail ', ''),
              style: TextStyle(color: _typeColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    final title = _transaction.description?.trim() ?? '';
    final note = _transaction.note?.trim() ?? '';
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Text(
            title.isNotEmpty ? title : _typeLabel.replaceFirst('Detail ', ''),
            style: title.isNotEmpty
                ? const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)
                : TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          AnimatedBalance(
            value: _transaction.amount,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _typeColor,
            ),
            formatter: (v) => CurrencyFormatter.formatWithSign(v,
              showPlus: _isIncome || _transaction.isPenerimaanTagihan || _isTransfer,
            ),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              note,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    final path = _newAttachmentPath ?? _transaction.attachmentPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lampiran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: path != null ? () => _openImageViewer(path) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: path != null
                ? AspectRatio(
                    aspectRatio: 1,
                    child: (path.startsWith('http')
                        ? Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildNoPhoto())
                        : Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildNoPhoto())),
                  )
                : _buildNoPhoto(),
          ),
        ),
        if (_isEditing) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Ganti Foto'),
              ),
              if (path != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _newAttachmentPath = null),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Hapus Foto'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.black),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNoPhoto() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text('Tidak ada foto', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    final isIncomeOrExpense = !_isTransfer && !_transaction.isTagihanRelated;
    final categoryName = _categoryName();
    final sourceWallet = _walletName(_transaction.walletId);
    final isMainTagihan = _transaction.isTagihan;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          if (isIncomeOrExpense) ...[
            _detailRow('Kategori', categoryName),
            const Divider(height: 20),
          ],
          _detailRow('Tanggal', DateFormatter.formatDateTime(_transaction.date)),
          const Divider(height: 20),
          _detailRow('Metode', _paymentMethodLabel),
          if (_isTransfer) ...[
            const Divider(height: 20),
            _detailRow('Dompet Asal', sourceWallet),
            const Divider(height: 20),
            _detailRow('Dompet Tujuan', _walletName(_transaction.toWalletId)),
          ] else ...[
            const Divider(height: 20),
            _detailRow('Dompet', sourceWallet),
          ],
          if (_transaction.description?.trim().isNotEmpty == true) ...[
            const Divider(height: 20),
            _detailRow(isMainTagihan ? 'Nama Tagihan' : 'Deskripsi', _transaction.description!),
          ],
          if (_transaction.note?.trim().isNotEmpty == true) ...[
            const Divider(height: 20),
            _detailRow(isMainTagihan ? 'Nama Orang' : 'Catatan', _transaction.note!),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildEditCard() {
    return AppCard(
      border: Border.all(color: AppTheme.black.withOpacity(0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, size: 16, color: AppTheme.black),
              const SizedBox(width: 6),
              Text('Edit Informasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.black)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLength: InputValidation.maxDescription,
            decoration: InputDecoration(
              labelText: 'Deskripsi',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            maxLength: InputValidation.maxNote,
            decoration: InputDecoration(
              labelText: 'Catatan',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImage(path: path),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
                _descriptionController.text = _transaction.description ?? '';
                _noteController.text = _transaction.note ?? '';
                _newAttachmentPath = null;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Batal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveEdit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 80);
    if (picked != null) {
      final err = InputValidation.imageFile(picked.path);
      if (err != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppTheme.black));
        return;
      }
      setState(() => _newAttachmentPath = picked.path);
    }
  }

  Future<void> _saveEdit() async {
    setState(() => _isLoading = true);

    final provider = context.read<TransactionProvider>();
    final success = await provider.updateTransactionMetadata(
      _transaction.id!,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      attachmentPath: _newAttachmentPath,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
      if (success) {
        setState(() {
          _transaction = _transaction.copyWith(
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            attachmentPath: _newAttachmentPath,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Berhasil disimpan', style: TextStyle(color: Colors.black87)), backgroundColor: Colors.white, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan'), backgroundColor: AppTheme.black),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat?'),
        content: const Text('Riwayat ini akan disembunyikan dan tidak akan memengaruhi saldo saat ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doDelete();
            },
            child: const Text('Hapus', style: TextStyle(color: AppTheme.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _doDelete() async {
    setState(() => _isLoading = true);
    final provider = context.read<TransactionProvider>();
    final success = await provider.softDeleteTransaction(_transaction.id!);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Riwayat berhasil dihapus', style: TextStyle(color: Colors.black87)), backgroundColor: Colors.white, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus'), backgroundColor: AppTheme.black),
        );
      }
    }
  }
}

class _FullScreenImage extends StatelessWidget {
  final String path;
  const _FullScreenImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final image = path.startsWith('http')
        ? Image.network(path, fit: BoxFit.contain)
        : Image.file(File(path), fit: BoxFit.contain);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: image,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
