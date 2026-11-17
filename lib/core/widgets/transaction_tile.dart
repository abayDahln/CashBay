import 'package:material_ui/material_ui.dart';
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
  final bool showChevron;

  /// Overrides the default subtitle (the transaction date). History passes the
  /// time and payment method, since the group header already shows the date.
  final String? subtitleOverride;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.showChevron = true,
    this.subtitleOverride,
  });

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final isTagihan = transaction.isTagihanRelated;
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
    final subtitle =
        subtitleOverride ??
        (isTagihan && note.isNotEmpty ? '$note • $dateText' : dateText);

    final finance = FinanceColors.of(context);
    final text = Theme.of(context).textTheme;
    final nominalColor = transaction.isTagihanRelated
        ? finance.titipan
        : isTransfer
        ? finance.transfer
        : isIncome
        ? finance.income
        : finance.expense;
    // Icon accent per case: titipan amber, its return legs green.
    final iconColor = transaction.isPembayaranTagihan ||
            transaction.isPenerimaanTagihan
        ? finance.income
        : transaction.isTagihan
        ? finance.titipan
        : nominalColor;

    return ListTile(
      onTap: onTap,
      minTileHeight: 72,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor.withValues(alpha: 0.06),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Icon(icon, size: 20, color: iconColor),
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
