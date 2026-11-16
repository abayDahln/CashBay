import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart'
    show DateFormatter, InputValidation, RupiahInputFormatter;
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../../../dashboard/presentation/providers/wallet_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../debts/data/models/debt.dart';
import '../../../debts/data/repositories/debt_repository.dart';
import '../../../debts/presentation/providers/debt_provider.dart';

class HistoryDetailScreen extends StatefulWidget {
  final Transaction transaction;
  const HistoryDetailScreen({super.key, required this.transaction});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late Transaction _transaction;
  bool _isDeleting = false;

  /// Titipan linked to this transaction, for the person name and due date.
  Debt? _debt;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    _loadDebt();
  }

  Future<void> _loadDebt() async {
    if (!_transaction.isTagihanRelated || _transaction.id == null) return;
    final debt = await DebtRepository().getDebtByOpenTxnId(_transaction.id!);
    if (mounted && debt != null) setState(() => _debt = debt);
  }

  bool get _isTransfer => _transaction.type == 'transfer';
  bool get _isIncome => _transaction.type == 'income';

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CashBayAppBar(
        title: _typeLabel,
        actions: [
          IconButton(
            tooltip: t.deleteTransaction,
            onPressed: _isDeleting ? null : _confirmDelete,
            icon: Icon(Icons.delete_outline, color: scheme.error),
          ),
        ],
      ),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_transaction.attachmentPath?.isNotEmpty ?? false) ...[
                    _buildPhotoSection(_transaction.attachmentPath!),
                    const SizedBox(height: 24),
                  ],
                  _buildHero(),
                  const SizedBox(height: 24),
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

  /// The hero shows the plain transaction type; the description (source of
  /// income, expense name, deposit person) lives in the info card instead.
  String _heroTitle(L t) {
    if (_transaction.isTagihan) {
      return _transaction.description?.startsWith('Titip masuk') == true
          ? t.titipanIn
          : t.titipanOut;
    }
    if (_transaction.isPembayaranTagihan) return t.detailPengembalian;
    if (_transaction.isPenerimaanTagihan) return t.detailPenerimaan;
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

  /// Names of the tags attached to this transaction, in tag order.
  ///
  /// Watches [CategoryProvider] so the row appears as soon as categories finish
  /// loading — the provider is filled asynchronously at startup, so on a cold
  /// first visit the names may not be in memory yet.
  List<String> _tagNames() {
    final ids = _transaction.categoryIds;
    if (ids.isEmpty) return const [];
    final provider = context.watch<CategoryProvider>();
    final names = {
      for (final c in [...provider.incomeCategories, ...provider.expenseCategories])
        c.id: c.name,
    };
    return ids.map((id) => names[id]).whereType<String>().toList();
  }

  Widget _buildHero() {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final finance = FinanceColors.of(context);
    // Matches the list tiles: titipan amber, its return legs green, else the
    // finance role of the amount.
    final iconColor =
        _transaction.isPembayaranTagihan ||
            _transaction.isPenerimaanTagihan
        ? finance.income
        : _transaction.isTagihan
        ? finance.titipan
        : finance.forType(_colorType);
    // Titipan and its return legs all read in the titipan accent.
    final amountColor = _transaction.isTagihanRelated
        ? finance.titipan
        : finance.forType(_colorType);
    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.06),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(_typeIcon, size: 28, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            _heroTitle(t),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: NominalText(
              amount: _transaction.amount,
              showPlus:
                  !_isTransfer &&
                  (_isIncome || _transaction.isPenerimaanTagihan),
              symbolColor: amountColor,
              style: text.headlineMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w600,
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
          child: SizedBox(
            height: 170,
            width: double.infinity,
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
    final tagNames = _tagNames();
    final note = _transaction.note?.trim() ?? '';
    final isEwallet = _transaction.paymentMethod == 'ewallet';
    final description = _transaction.description?.trim() ?? '';

    final rows = <Widget>[
      // Titipan legs show the person and due date from the linked Debt; plain
      // income/expense show the description under its own label.
      if (isMainTagihan && _debt != null) ...[
        _detailRow(
          Icons.person_outline,
          t.personName,
          Text(_debt!.personName, style: _valueStyle),
        ),
        if (_debt!.dueDate != null)
          _detailRow(
            Icons.event_outlined,
            t.dueDateLabel,
            Text(_formatDate(_debt!.dueDate!), style: _valueStyle),
          ),
      ] else if (!isMainTagihan && !_transaction.isTagihanRelated && description.isNotEmpty)
        _detailRow(
          _isIncome ? Icons.savings_outlined : Icons.notes_outlined,
          _isIncome ? t.descriptionIncome : t.description,
          Text(description, style: _valueStyle),
        ),
      _detailRow(
        Icons.calendar_today_outlined,
        t.date,
        Text(_formatDate(_transaction.date), style: _valueStyle),
      ),
      _detailRow(
        Icons.credit_card_outlined,
        t.method,
        Text(_paymentMethodLabel, style: _valueStyle),
      ),
      if (_isTransfer) ...[
        _detailRow(
          Icons.wallet_outlined,
          t.sourceWallet,
          Text(sourceWallet, style: _valueStyle),
        ),
        _detailRow(
          Icons.wallet_outlined,
          t.destinationWallet,
          Text(_walletName(_transaction.toWalletId), style: _valueStyle),
        ),
      ] else if (isEwallet)
        _detailRow(
          Icons.wallet_outlined,
          t.wallet,
          Text(sourceWallet, style: _valueStyle),
        ),
      if (note.isNotEmpty)
        _detailRow(
          isMainTagihan ? Icons.notes_outlined : Icons.sticky_note_2_outlined,
          isMainTagihan ? t.titipanName : t.note,
          Text(note, style: _valueStyle),
        ),
      if (tagNames.isNotEmpty)
        _detailRow(Icons.sell_outlined, t.tag, _tagChips(tagNames)),
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

  TextStyle get _valueStyle {
    final text = Theme.of(context).textTheme;
    return text.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface);
  }

  /// "16 Nov 2026 22:24" in the active locale.
  String _formatDate(DateTime date) => DateFormat(
    'dd MMM yyyy HH:mm',
    Localizations.localeOf(context).toLanguageTag(),
  ).format(date);

  /// Mini chips so a tag reads as an attribute, not body text.
  Widget _tagChips(List<String> names) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final name in names)
          Chip(
            label: Text(name),
            labelStyle: Theme.of(context).textTheme.labelMedium,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    ),
  );

  Widget _detailRow(IconData icon, String label, Widget value) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(icon, size: 24, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                value,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final t = L.of(context);
    return FilledButton.tonalIcon(
      onPressed: _openEditScreen,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      icon: const Icon(Icons.edit_outlined),
      label: Text(t.editTransaction),
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

  Future<void> _openEditScreen() async {
    final updated = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditTransactionScreen(transaction: _transaction),
      ),
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

/// Full-screen form for editing description, note, amount, wallet, tags and
/// photo. Mirrors the add-transaction layout, without the type selector.
/// Pops with the updated [Transaction] on success.
class _EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;
  const _EditTransactionScreen({required this.transaction});

  @override
  State<_EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<_EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteController;
  late final TextEditingController _amountController;
  late final TextEditingController _personNameController;
  int? _walletId;
  late DateTime _date;
  DateTime? _dueDate;
  Debt? _debt;
  String? _newAttachmentPath;
  bool _isSaving = false;
  bool _submitted = false;
  late final Set<int> _selectedCategoryIds;

  Transaction get _transaction => widget.transaction;

  /// Titipan amount/wallet are edited from the titipan detail screen, but the
  /// person, due date and date are editable here.
  bool get _canEditAmount => !_transaction.isTagihanRelated;

  bool get _isTitipan => _transaction.isTagihan;

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
    _personNameController = TextEditingController();
    _walletId = _transaction.walletId;
    _date = _transaction.date;
    _selectedCategoryIds = {..._transaction.categoryIds};
    _loadDebt();
  }

  Future<void> _loadDebt() async {
    if (!_transaction.isTagihanRelated || _transaction.id == null) return;
    final debt = await DebtRepository().getDebtByOpenTxnId(_transaction.id!);
    if (!mounted || debt == null) return;
    setState(() {
      _debt = debt;
      _personNameController.text = debt.personName;
      _dueDate = debt.dueDate;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    _personNameController.dispose();
    super.dispose();
  }

  String? _trimmedOrNull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  /// Order-insensitive comparison of two id collections.
  bool _sameIds(Set<int> a, List<int> b) =>
      a.length == b.length && b.every(a.contains);

  Future<void> _pickImage(AttachmentSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source == AttachmentSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
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

  Widget _buildTagPicker() {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final provider = context.watch<CategoryProvider>();
    final categories = _transaction.type == 'income'
        ? provider.incomeCategories
        : provider.expenseCategories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.tagOptional,
          style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in categories)
              FilterChip(
                label: Text(category.name),
                selected: _selectedCategoryIds.contains(category.id),
                onSelected: _isSaving
                    ? null
                    : (selected) => setState(() {
                        if (selected) {
                          _selectedCategoryIds.add(category.id!);
                        } else {
                          _selectedCategoryIds.remove(category.id);
                        }
                      }),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(t.newTag),
              onPressed: _isSaving ? null : _addCustomTag,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addCustomTag() async {
    final t = L.of(context);
    final provider = context.read<CategoryProvider>();
    final type = _transaction.type == 'income' ? 'income' : 'expense';
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.newTag),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: InputValidation.maxCategory,
          decoration: InputDecoration(
            labelText: t.tagName,
            hintText: t.tagNameHint,
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (name == null || !mounted) return;

    final trimmed = name.trim();
    final err =
        InputValidation.name(
          trimmed,
          t.tagName,
          max: InputValidation.maxCategory,
          l10n: t,
        ) ??
        provider.hasCategoryNamed(trimmed, type, l10n: t);
    if (err != null) {
      ToastWidget.error(context, err);
      return;
    }

    final id = await provider.addCategory(name: trimmed, type: type);
    if (id != null && mounted) {
      setState(() => _selectedCategoryIds.add(id));
    }
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
    final tagsChanged = !_sameIds(_selectedCategoryIds, _transaction.categoryIds);
    final dateChanged = !_date.isAtSameMomentAs(_transaction.date);
    final metaChanged =
        (description != null && description != _transaction.description) ||
        (note != null && note != _transaction.note) ||
        _newAttachmentPath != null ||
        dateChanged;
    final provider = context.read<TransactionProvider>();
    setState(() => _isSaving = true);

    final Transaction updated;
    bool success;
    if (amountChanged || walletChanged || tagsChanged) {
      // Full-row update: a moved amount/wallet also carries description, note,
      // photo, date and tags (updateTransaction replaces the tag rows). A
      // tags-only edit must leave amount/wallet untouched, so only forward them
      // when they are editable for this transaction.
      updated = _transaction.copyWith(
        amount: _canEditAmount ? newAmount : _transaction.amount,
        walletId: _canEditAmount ? _walletId : _transaction.walletId,
        description: description,
        note: note,
        attachmentPath: _newAttachmentPath,
        date: _date,
        categoryIds: _selectedCategoryIds.toList(),
      );
      success = await provider.updateTransaction(updated);
    } else if (metaChanged) {
      updated = _transaction.copyWith(
        description: description,
        note: note,
        attachmentPath: _newAttachmentPath,
        date: _date,
      );
      success = await provider.updateTransactionMetadata(
        _transaction.id!,
        description: description,
        note: note,
        attachmentPath: _newAttachmentPath,
        date: _date,
      );
    } else {
      Navigator.pop(context);
      return;
    }

    if (!mounted) return;
    if (success && _debt != null) {
      await _saveDebt();
      if (!mounted) return;
    }
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

  Future<void> _saveDebt() async {
    final name = _personNameController.text.trim();
    if (name.isEmpty && _dueDate == null) return;
    final debt = _debt!;
    final provider = context.read<DebtProvider>();
    await provider.updateDebt(
      debt.copyWith(
        personName: name.isEmpty ? debt.personName : name,
        dueDate: _dueDate,
      ),
    );
  }

  Widget _buildDateField() {
    final t = L.of(context);
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: t.transactionDate,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          DateFormatter.formatDateTime(_date),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildDueDateField() {
    final t = L.of(context);
    return InkWell(
      onTap: _pickDueDate,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: t.dueDateLabel,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _dueDate == null ? '-' : DateFormatter.formatDate(_dueDate!),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time?.hour ?? _date.hour,
        time?.minute ?? _date.minute,
      );
      // Keep the due date on or after the (possibly moved) transaction date.
      if (_dueDate != null && _dueDate!.isBefore(_date)) _dueDate = _date;
    });
  }

  Future<void> _pickDueDate() async {
    // Bounded by the transaction date: moving that forward pushes this with it.
    final first = DateTime(_date.year, _date.month, _date.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: (_dueDate ?? first).isBefore(first) ? first : _dueDate!,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
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

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final photo = _newAttachmentPath ?? _transaction.attachmentPath;
    return Scaffold(
      appBar: CashBayAppBar(title: t.editTransaction),
      body: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInsetGroup(t.detailMain, [
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
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    validator: (v) => v == null ? t.chooseWallet : null,
                  ),
                  const SizedBox(height: 16),
                ],
                // Titipan descriptions are generated; the person is the field
                // worth editing.
                if (_isTitipan) ...[
                  TextFormField(
                    controller: _personNameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t.personName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  TextFormField(
                    controller: _descriptionController,
                    maxLength: InputValidation.maxDescription,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: _transaction.type == 'income'
                        ? t.descriptionIncome
                        : t.description,
                      prefixIcon: const Icon(Icons.edit_note),
                    ),
                    validator: (v) => InputValidation.maxLength(
                      v,
                      t.description,
                      InputValidation.maxDescription,
                      l10n: t,
                    ),
                  ),
              ]),
              const SizedBox(height: 24),
              _buildInsetGroup(t.fundAndTime, [
                _buildDateField(),
                if (_isTitipan && _debt != null) ...[
                  const SizedBox(height: 16),
                  _buildDueDateField(),
                ],
              ]),
              const SizedBox(height: 24),
              _buildInsetGroup(t.notesAndAttachment, [
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
                const SizedBox(height: 16),
                _buildTagPicker(),
                const SizedBox(height: 16),
                Text(
                  t.attachment,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                AttachmentPicker(
                  path: photo,
                  isNew: _newAttachmentPath?.isNotEmpty ?? false,
                  onPick: _pickImage,
                  onRemove: () => setState(() {
                    // A new pick is discarded (null); a saved photo is marked
                    // for removal with an empty path.
                    _newAttachmentPath = _newAttachmentPath == null
                        ? ''
                        : null;
                  }),
                ),
              ]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
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
