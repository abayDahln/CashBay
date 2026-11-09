import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
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
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
  }

  bool get _isTransfer => _transaction.type == 'transfer';
  bool get _isIncome => _transaction.type == 'income';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CashBayAppBar(title: _typeLabel),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(),
                  const SizedBox(height: 24),
                  if (_transaction.attachmentPath != null) ...[
                    _buildPhotoSection(_transaction.attachmentPath!),
                    const SizedBox(height: 24),
                  ],
                  _buildDetailCard(),
                  const SizedBox(height: 24),
                  _buildActions(),
                ],
              ),
            ),
    );
  }

  String get _typeLabel {
    if (_transaction.isTagihan) return 'Detail Titipan';
    if (_transaction.isPembayaranTagihan) return 'Detail Pengembalian';
    if (_transaction.isPenerimaanTagihan) return 'Detail Penerimaan';
    if (_isTransfer) return 'Detail Transfer';
    if (_isIncome) return 'Detail Pendapatan';
    return 'Detail Pengeluaran';
  }

  /// Colour type used for FinanceColors: penerimaan tagihan counts as income.
  String get _colorType => _isTransfer
      ? 'transfer'
      : _isIncome || _transaction.isPenerimaanTagihan
      ? 'income'
      : 'expense';

  IconData get _typeIcon {
    if (_transaction.isTagihan) return Icons.receipt_long;
    if (_transaction.isPembayaranTagihan) return Icons.check_circle_outline;
    if (_transaction.isPenerimaanTagihan) return Icons.file_download;
    if (_isTransfer) return Icons.swap_horiz;
    if (_isIncome) return Icons.south;
    return Icons.north;
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final finance = FinanceColors.of(context);
    final (container, onContainer) = switch (_colorType) {
      'income' => (finance.incomeContainer, finance.onIncomeContainer),
      'transfer' => (finance.transferContainer, finance.onTransferContainer),
      _ => (finance.expenseContainer, finance.onExpenseContainer),
    };
    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: container,
            foregroundColor: onContainer,
            child: Icon(_typeIcon, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title.isNotEmpty ? title : _typeLabel.replaceFirst('Detail ', ''),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedBalance(
              value: _transaction.amount,
              maxLines: 1,
              style: text.headlineMedium?.copyWith(
                color: finance.forType(_colorType),
                fontWeight: FontWeight.w600,
              ),
              formatter: (v) => CurrencyFormatter.formatWithSign(
                v,
                showPlus:
                    _isIncome ||
                    _transaction.isPenerimaanTagihan ||
                    _isTransfer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  Widget _buildPhotoSection(String path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('Lampiran'),
        AppCard(
          variant: AppCardVariant.outlined,
          padding: EdgeInsets.zero,
          onTap: () => _openImageViewer(path),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: _AttachmentImage(path: path),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard() {
    final sourceWallet = _walletName(_transaction.walletId);
    final isMainTagihan = _transaction.isTagihan;
    final scheme = Theme.of(context).colorScheme;

    final rows = <Widget>[
      _detailRow(
        Icons.calendar_today_outlined,
        'Tanggal',
        DateFormatter.formatDateTime(_transaction.date),
      ),
      _detailRow(Icons.credit_card_outlined, 'Metode', _paymentMethodLabel),
      if (_isTransfer) ...[
        _detailRow(Icons.wallet_outlined, 'Dompet Asal', sourceWallet),
        _detailRow(
          Icons.wallet_outlined,
          'Dompet Tujuan',
          _walletName(_transaction.toWalletId),
        ),
      ] else
        _detailRow(Icons.wallet_outlined, 'Dompet', sourceWallet),
      if (_transaction.description?.trim().isNotEmpty == true)
        _detailRow(
          Icons.notes_outlined,
          isMainTagihan ? 'Nama Titipan' : 'Deskripsi',
          _transaction.description!,
        ),
      if (_transaction.note?.trim().isNotEmpty == true)
        _detailRow(
          isMainTagihan ? Icons.person_outline : Icons.sticky_note_2_outlined,
          isMainTagihan ? 'Nama Orang' : 'Catatan',          _transaction.note!,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('Informasi transaksi'),
        AppCard(
          variant: AppCardVariant.outlined,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, indent: 56, color: scheme.outlineVariant),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(
        label,
        style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      subtitle: Text(
        value,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: text.bodyLarge?.copyWith(color: scheme.onSurface),
      ),
    );
  }

  Widget _buildActions() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          onPressed: _openEditSheet,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Ubah Transaksi'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _confirmDelete,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: scheme.error,
          ),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Hapus Transaksi'),
        ),
      ],
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

  Future<void> _openEditSheet() async {
    final updated = await showModalBottomSheet<Transaction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _EditTransactionSheet(transaction: _transaction),
    );
    if (updated != null && mounted) {
      setState(() => _transaction = updated);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: const Icon(Icons.delete_outline),
          title: const Text('Hapus Riwayat?'),
          content: const Text(
            'Riwayat ini akan disembunyikan dan tidak akan memengaruhi saldo saat ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) await _doDelete();
  }

  Future<void> _doDelete() async {
    setState(() => _isDeleting = true);
    final provider = context.read<TransactionProvider>();
    final success = await provider.softDeleteTransaction(_transaction.id!);
    if (!mounted) return;
    if (success) {
      ToastWidget.success(context, 'Riwayat berhasil dihapus');
      Navigator.pop(context);
    } else {
      setState(() => _isDeleting = false);
      ToastWidget.error(context, 'Gagal menghapus');
    }
  }
}

/// M3 bottom-sheet form for editing description, note and photo.
/// Pops with the updated [Transaction] on success.
class _EditTransactionSheet extends StatefulWidget {
  final Transaction transaction;
  const _EditTransactionSheet({required this.transaction});

  @override
  State<_EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<_EditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteController;
  String? _newAttachmentPath;
  bool _isSaving = false;
  bool _submitted = false;

  Transaction get _transaction => widget.transaction;

  @override
  void initState() {
    super.initState();
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

  String? _trimmedOrNull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    final err = InputValidation.imageFile(picked.path);
    if (err != null) {
      ToastWidget.error(context, err);
      return;
    }
    setState(() => _newAttachmentPath = picked.path);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    if (!_submitted) setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final description = _trimmedOrNull(_descriptionController);
    final note = _trimmedOrNull(_noteController);
    // Null means "unchanged" in updateTransactionMetadata.
    final changed =
        (description != null && description != _transaction.description) ||
        (note != null && note != _transaction.note) ||
        _newAttachmentPath != null;
    if (!changed) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);
    final success = await context
        .read<TransactionProvider>()
        .updateTransactionMetadata(
          _transaction.id!,
          description: description,
          note: note,
          attachmentPath: _newAttachmentPath,
        );
    if (!mounted) return;
    if (success) {
      ToastWidget.success(context, 'Berhasil disimpan');
      Navigator.pop(
        context,
        _transaction.copyWith(
          description: description,
          note: note,
          attachmentPath: _newAttachmentPath,
        ),
      );
    } else {
      setState(() => _isSaving = false);
      ToastWidget.error(context, 'Gagal menyimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final photo = _newAttachmentPath ?? _transaction.attachmentPath;
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
              Text('Ubah Transaksi', style: text.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Nominal, jenis, dan dompet tidak dapat diubah.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLength: InputValidation.maxDescription,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                validator: (v) => InputValidation.maxLength(
                  v,
                  'Deskripsi',
                  InputValidation.maxDescription,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                maxLength: InputValidation.maxNote,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  alignLabelWithHint: true,
                ),
                validator: (v) => InputValidation.maxLength(
                  v,
                  'Catatan',
                  InputValidation.maxNote,
                ),
              ),
              const SizedBox(height: 8),
              Text('Lampiran', style: text.labelLarge),
              const SizedBox(height: 8),
              if (photo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
                    child: _AttachmentImage(path: photo),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(photo == null ? 'Tambah Foto' : 'Ganti Foto'),
                  ),
                  if (_newAttachmentPath != null)
                    TextButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => setState(() => _newAttachmentPath = null),
                      icon: const Icon(Icons.undo),
                      label: const Text('Batalkan Foto Baru'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
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
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentImage extends StatelessWidget {
  final String path;
  const _AttachmentImage({required this.path});

  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext context, Object _, StackTrace? _) {
      final scheme = Theme.of(context).colorScheme;
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_outlined,
                size: 32,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                'Tidak ada foto',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return path.startsWith('http')
        ? Image.network(
            path,
            fit: BoxFit.cover,
            width: double.infinity,
            semanticLabel: 'Lampiran foto',
            errorBuilder: fallback,
          )
        : Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            semanticLabel: 'Lampiran foto',
            errorBuilder: fallback,
          );
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

    // Photo viewer intentionally uses a black backdrop regardless of theme.
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
            top: MediaQuery.paddingOf(context).top + 8,
            left: 8,
            child: IconButton(
              tooltip: 'Kembali',
              color: Colors.white,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
