import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart'
    show CurrencyFormatter, InputValidation, RupiahInputFormatter;
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
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
    final t = L.of(context);
    if (_transaction.isTagihan) return t.detailTitipan;
    if (_transaction.isPembayaranTagihan) return t.detailPengembalian;
    if (_transaction.isPenerimaanTagihan) return t.detailPenerimaan;
    if (_isTransfer) return t.detailTransfer;
    if (_isIncome) return t.detailIncome;
    return t.detailExpense;
  }

  /// Plain type name used when a transaction has no description.
  String _typeLabelFallback(L t) {
    if (_transaction.isTagihan ||
        _transaction.isPembayaranTagihan ||
        _transaction.isPenerimaanTagihan) {
      return t.titipan;
    }
    if (_isTransfer) return t.transfer;
    if (_isIncome) return t.incomeLabel;
    return t.expenseLabel;
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
      _transaction.paymentMethod == 'ewallet'
      ? L.of(context).ewallet
      : L.of(context).cash;

  String _walletName(int? id) {
    if (id == null) return '-';
    final walletProvider = context.read<WalletProvider>();
    for (final w in walletProvider.wallets) {
      if (w.id == id) return w.name;
    }
    return L.of(context).idLabel(id);
  }

  Widget _buildHero() {
    final t = L.of(context);
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
            title.isNotEmpty ? title : _typeLabelFallback(t),
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
        _sectionLabel(L.of(context).attachment),
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
    final t = L.of(context);
    final sourceWallet = _walletName(_transaction.walletId);
    final isMainTagihan = _transaction.isTagihan;
    final scheme = Theme.of(context).colorScheme;

    final rows = <Widget>[
      _detailRow(
        Icons.calendar_today_outlined,
        t.date,
        DateFormat(
          'dd MMM yyyy HH:mm',
          Localizations.localeOf(context).toLanguageTag(),
        ).format(_transaction.date),
      ),
      _detailRow(Icons.credit_card_outlined, t.method, _paymentMethodLabel),
      if (_isTransfer) ...[
        _detailRow(Icons.wallet_outlined, t.sourceWallet, sourceWallet),
        _detailRow(
          Icons.wallet_outlined,
          t.destinationWallet,
          _walletName(_transaction.toWalletId),
        ),
      ] else
        _detailRow(Icons.wallet_outlined, t.wallet, sourceWallet),
      if (_transaction.description?.trim().isNotEmpty == true)
        _detailRow(
          Icons.notes_outlined,
          isMainTagihan ? t.titipanName : t.description,
          _transaction.description!,
        ),
      if (_transaction.note?.trim().isNotEmpty == true)
        _detailRow(
          isMainTagihan ? Icons.person_outline : Icons.sticky_note_2_outlined,
          isMainTagihan ? t.personName : t.note,          _transaction.note!,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(t.transactionInfo),
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
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          onPressed: _openEditSheet,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.edit_outlined),
          label: Text(t.editTransaction),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _confirmDelete,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: scheme.error,
          ),
          icon: const Icon(Icons.delete_outline),
          label: Text(t.deleteTransaction),
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
    final t = L.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: const Icon(Icons.delete_outline),
          title: Text(t.deleteHistoryQ),
          content: Text(t.deleteHistoryDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.delete),
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
      ToastWidget.success(context, L.of(context).historyDeleted);
      Navigator.pop(context);
    } else {
      setState(() => _isDeleting = false);
      ToastWidget.error(context, L.of(context).deleteFailed);
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
  late final TextEditingController _amountController;
  int? _walletId;
  String? _newAttachmentPath;
  bool _isSaving = false;
  bool _submitted = false;

  Transaction get _transaction => widget.transaction;

  /// Titipan legs are edited from the titipan detail screen, not here.
  bool get _canEditAmount => !_transaction.isTagihanRelated;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: _transaction.description ?? '',
    );
    _noteController = TextEditingController(text: _transaction.note ?? '');
    _amountController = TextEditingController(
      text: RupiahInputFormatter.formatValue(_transaction.amount),
    );
    _walletId = _transaction.walletId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _noteController.dispose();
    _amountController.dispose();
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
    final err = InputValidation.imageFile(picked.path, l10n: L.of(context));
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
    final newAmount = InputValidation.parseAmount(_amountController.text);
    final amountChanged =
        _canEditAmount &&
        newAmount != null &&
        newAmount != _transaction.amount;
    final walletChanged = _canEditAmount && _walletId != _transaction.walletId;
    final metaChanged =
        (description != null && description != _transaction.description) ||
        (note != null && note != _transaction.note) ||
        _newAttachmentPath != null;

    final provider = context.read<TransactionProvider>();
    setState(() => _isSaving = true);

    final Transaction updated;
    bool success;
    if (amountChanged || walletChanged) {
      // Full-row update: amount and/or wallet moved with description/note/photo.
      updated = _transaction.copyWith(
        amount: newAmount,
        walletId: _walletId,
        description: description,
        note: note,
        attachmentPath: _newAttachmentPath,
      );
      success = await provider.updateTransaction(updated);
    } else if (metaChanged) {
      updated = _transaction.copyWith(
        description: description,
        note: note,
        attachmentPath: _newAttachmentPath,
      );
      success = await provider.updateTransactionMetadata(
        _transaction.id!,
        description: description,
        note: note,
        attachmentPath: _newAttachmentPath,
      );
    } else {
      Navigator.pop(context);
      return;
    }

    if (!mounted) return;
    if (success) {
      // Keep the dashboard totals in sync with the new amount/wallet.
      await context.read<WalletProvider>().refreshBalances();
      if (!mounted) return;
      ToastWidget.success(context, L.of(context).saved);
      Navigator.pop(context, updated);
    } else {
      setState(() => _isSaving = false);
      ToastWidget.error(context, L.of(context).saveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
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
              Text(t.editTransaction, style: text.titleLarge),
              const SizedBox(height: 4),
              Text(
                _canEditAmount ? t.kindNotEditable : t.titipanEditHint,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (_canEditAmount) ...[
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [RupiahInputFormatter()],
                  decoration: InputDecoration(
                    labelText: t.amount,
                    prefixText: 'Rp ',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    errorMaxLines: 2,
                  ),
                  validator: (v) =>
                      InputValidation.amountInRange(v, l10n: L.of(context)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _walletId,
                  isExpanded: true,
                  items: [
                    for (final w in context.watch<WalletProvider>().wallets)
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
                    labelText: _transaction.type == 'transfer'
                        ? t.sourceWallet
                        : t.wallet,
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (v) => v == null ? t.chooseWallet : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _descriptionController,
                maxLength: InputValidation.maxDescription,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: t.description,
                  prefixIcon: const Icon(Icons.edit_note),
                ),
                validator: (v) => InputValidation.maxLength(
                  v,
                  t.description,
                  InputValidation.maxDescription,
                  l10n: t,
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
                decoration: InputDecoration(
                  labelText: t.note,
                  alignLabelWithHint: true,
                ),
                validator: (v) => InputValidation.maxLength(
                  v,
                  t.note,
                  InputValidation.maxNote,
                  l10n: t,
                ),
              ),
              const SizedBox(height: 8),
              Text(t.attachment, style: text.labelLarge),
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
                    label: Text(photo == null ? t.addPhoto : t.changePhoto),
                  ),
                  if (_newAttachmentPath != null)
                    TextButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => setState(() => _newAttachmentPath = null),
                      icon: const Icon(Icons.undo),
                      label: Text(t.undoNewPhoto),
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
                    : Text(t.save),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(t.cancel),
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
                L.of(context).noPhoto,
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
            semanticLabel: L.of(context).attachmentPhoto,
            errorBuilder: fallback,
          )
        : Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            semanticLabel: L.of(context).attachmentPhoto,
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
              tooltip: L.of(context).back,
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
