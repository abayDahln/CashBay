import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart'
    show CurrencyFormatter, DateFormatter, InputValidation;
import '../../../../core/widgets/widgets.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_provider.dart';
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
    _descriptionController = TextEditingController(
      text: _transaction.description ?? '',
    );
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
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Hapus',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
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
              child: Text('Batal'),
            ),
            TextButton(onPressed: _saveEdit, child: const Text('Simpan')),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(),
                  const SizedBox(height: 24),
                  if (_transaction.attachmentPath != null || _isEditing) ...[
                    _buildPhotoSection(),
                    const SizedBox(height: 20),
                  ],
                  _buildDetailCard(),
                  const SizedBox(height: 24),
                  if (_isEditing) ...[
                    _buildEditCard(),
                    const SizedBox(height: 20),
                    _buildEditActions(),
                  ] else
                    _buildActions(),
                ],
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

  Color get _amountColor {
    if (_isTransfer) return Theme.of(context).colorScheme.onSurface;
    return _isIncome || _transaction.isPenerimaanTagihan
        ? AppTheme.income
        : AppTheme.expense;
  }

  IconData get _typeIcon {
    if (_transaction.isTagihan) return Icons.receipt_long;
    if (_transaction.isPembayaranTagihan) return Icons.check_circle_outline;
    if (_transaction.isPenerimaanTagihan) return Icons.file_download;
    if (_isTransfer) return Icons.swap_horiz;
    if (_isIncome) return Icons.arrow_downward;
    return Icons.arrow_upward;
  }

  String get _paymentMethodLabel =>
      _transaction.paymentMethod == 'ewallet' ? 'E-Wallet' : 'Cash';

  String _walletName(int? id) {
    if (id == null) return '-';
    final walletProvider = context.read<WalletProvider>();
    for (final w in walletProvider.wallets) {
      if (w.id == id) return w.name;
    }
    return 'ID: $id';
  }

  Widget _buildHero() {
    final title = _transaction.description?.trim() ?? '';
    final note = _transaction.note?.trim() ?? '';
    final scheme = Theme.of(context).colorScheme;
    final statusLabel = _transaction.isTagihan
        ? 'Tagihan'
        : _transaction.isTagihanRelated
        ? 'Berhasil'
        : _isTransfer
        ? 'Transfer'
        : 'Berhasil';
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_typeIcon, color: scheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                _typeLabel.replaceFirst('Detail ', '').toUpperCase(),
                style: AppTypography.caption2.copyWith(
                  color: scheme.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title.isNotEmpty ? title : _typeLabel.replaceFirst('Detail ', ''),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.title1.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 6),
        AnimatedBalance(
          value: _transaction.amount,
          style: AppTypography.largeTitle.copyWith(color: _amountColor),
          formatter: (v) => CurrencyFormatter.formatWithSign(
            v,
            showPlus:
                _isIncome || _transaction.isPenerimaanTagihan || _isTransfer,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 16, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              statusLabel,
              style: AppTypography.subheadline.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            note,
            textAlign: TextAlign.center,
            style: AppTypography.caption1.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoSection() {
    final path = _newAttachmentPath ?? _transaction.attachmentPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lampiran',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: path != null ? () => _openImageViewer(path) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: path != null
                ? AspectRatio(
                    aspectRatio: 1,
                    child: (path.startsWith('http')
                        ? Image.network(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildNoPhoto(),
                          )
                        : Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildNoPhoto(),
                          )),
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
                icon: Icon(Icons.camera_alt, size: 16),
                label: const Text('Ganti Foto'),
              ),
              if (path != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _newAttachmentPath = null),
                  icon: Icon(Icons.delete_outline, size: 16),
                  label: const Text('Hapus Foto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 4),
            Text(
              'Tidak ada foto',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    final sourceWallet = _walletName(_transaction.walletId);
    final isMainTagihan = _transaction.isTagihan;
    final scheme = Theme.of(context).colorScheme;

    final rows = <Widget>[
      _detailRow(
        Icons.calendar_today_outlined,
        scheme.primary,
        'Tanggal',
        DateFormatter.formatDateTime(_transaction.date),
      ),
      _detailRow(
        Icons.credit_card_outlined,
        scheme.primary,
        'Metode',
        _paymentMethodLabel,
      ),
      if (_isTransfer) ...[
        _detailRow(
          Icons.wallet_outlined,
          scheme.primary,
          'Dompet Asal',
          sourceWallet,
        ),
        _detailRow(
          Icons.wallet_outlined,
          scheme.primary,
          'Dompet Tujuan',
          _walletName(_transaction.toWalletId),
        ),
      ] else
        _detailRow(
          Icons.wallet_outlined,
          scheme.primary,
          'Dompet',
          sourceWallet,
        ),
      if (_transaction.description?.trim().isNotEmpty == true)
        _detailRow(
          Icons.notes_outlined,
          scheme.primary,
          isMainTagihan ? 'Nama Tagihan' : 'Deskripsi',
          _transaction.description!,
        ),
      if (_transaction.note?.trim().isNotEmpty == true)
        _detailRow(
          Icons.notes_outlined,
          scheme.primary,
          isMainTagihan ? 'Nama Orang' : 'Catatan',
          _transaction.note!,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'INFORMASI TRANSAKSI',
            style: AppTypography.caption1.copyWith(
              color: scheme.outline,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        AppCard(
          showBorder: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    indent: 58,
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
    IconData icon,
    Color iconColor,
    String label,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.subheadline.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.subheadline.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () => setState(() => _isEditing = true),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: scheme.primary,
            side: BorderSide(color: scheme.outlineVariant),
          ),
          icon: const Icon(Icons.edit, size: 20),
          label: const Text('Ubah Transaksi'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _confirmDelete,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.outlineVariant),
          ),
          icon: const Icon(Icons.delete_outline, size: 20),
          label: const Text('Hapus Transaksi'),
        ),
      ],
    );
  }

  Widget _buildEditCard() {
    return AppCard(
      border: Border.all(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                'Edit Informasi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLength: InputValidation.maxDescription,
            decoration: const InputDecoration(labelText: 'Deskripsi'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            maxLength: InputValidation.maxNote,
            decoration: const InputDecoration(
              labelText: 'Catatan',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (picked != null) {
      final err = InputValidation.imageFile(picked.path);
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
      setState(() => _newAttachmentPath = picked.path);
    }
  }

  Future<void> _saveEdit() async {
    setState(() => _isLoading = true);

    final provider = context.read<TransactionProvider>();
    final success = await provider.updateTransactionMetadata(
      _transaction.id!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
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
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            attachmentPath: _newAttachmentPath,
          );
        });
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat?'),
        content: const Text(
          'Riwayat ini akan disembunyikan dan tidak akan memengaruhi saldo saat ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doDelete();
            },
            child: Text('Hapus', style: TextStyle()),
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
          SnackBar(
            content: Text(
              'Riwayat berhasil dihapus',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus'),
            backgroundColor: Theme.of(context).colorScheme.onSurface,
          ),
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
              tooltip: 'Kembali',
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
