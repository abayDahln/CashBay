import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../features/transactions/data/models/transaction.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'animated_balance.dart';

/// M3 two-line list item for a transaction: primary-tinted avatar,
/// title + supporting text, trailing amount.
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final String? categoryName;
  final bool showChevron;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.categoryName,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final isTagihan = transaction.isTagihanRelated;
    final isPlainExpense = transaction.type == 'expense' && !isTagihan;
    final description = transaction.description?.trim() ?? '';
    final note = transaction.note?.trim() ?? '';
    final (icon, label) = transaction.isTagihanRelated
        ? (
            Icons.receipt_long,
            transaction.description ?? t.titipan,
          )
        : isTransfer
        ? (Icons.swap_horiz, description.isNotEmpty ? description : t.transfer)
        : isIncome
        ? (
            Icons.south,
            description.isNotEmpty
                ? description
                : (note.isNotEmpty ? note : t.incomeLabel),
          )
        : (
            Icons.north,
            description.isNotEmpty
                ? description
                : (note.isNotEmpty ? note : t.expenseLabel),
          );
    final dateText = DateFormatter.formatDate(transaction.date);
    final subtitle = isTagihan && note.isNotEmpty
        ? '$note • $dateText'
        : (isIncome || isPlainExpense) && (categoryName?.isNotEmpty ?? false)
        ? '$categoryName • $dateText'
        : dateText;

    final finance = FinanceColors.of(context);
    final text = Theme.of(context).textTheme;
    final nominalColor = isTransfer
        ? finance.transfer
        : isIncome
        ? finance.income
        : finance.expense;

    return ListTile(
      onTap: onTap,
      minTileHeight: 72,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        child: Icon(icon, size: 20),
      ),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodyLarge?.copyWith(color: scheme.onSurface),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 132),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: AnimatedBalance(
                value: isIncome || isTransfer
                    ? transaction.amount
                    : -transaction.amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge?.copyWith(
                  color: nominalColor,
                  fontWeight: FontWeight.w600,
                ),
                formatter: (value) => CurrencyFormatter.formatWithSign(
                  value,
                  // Transfers neither add nor subtract: show the plain nominal.
                  showPlus: !isTransfer && (isIncome || isTagihan),
                ),
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
