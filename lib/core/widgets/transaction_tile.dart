import 'package:flutter/material.dart';
import '../../features/transactions/data/models/transaction.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'animated_balance.dart';

/// A single row inside an "inset grouped" list, matching the `ui/*.html`
/// history rows: round tinted icon, title + subtitle, amount + chevron.
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
    final scheme = Theme.of(context).colorScheme;
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final isTagihan = transaction.isTagihanRelated;
    final isPlainExpense = transaction.type == 'expense' && !isTagihan;
    final description = transaction.description?.trim() ?? '';
    final note = transaction.note?.trim() ?? '';
    final nominalColor = isIncome ? AppColors.income : AppColors.expense;
    final (icon, label) = transaction.isTagihan
        ? (Icons.receipt_long, transaction.description ?? 'Tagihan')
        : transaction.isPembayaranTagihan
        ? (Icons.check_circle_outline, transaction.description ?? 'Pembayaran')
        : transaction.isPenerimaanTagihan
        ? (Icons.file_download, transaction.description ?? 'Penerimaan')
        : isTransfer
        ? (Icons.swap_horiz, description.isNotEmpty ? description : 'Transfer')
        : isIncome
        ? (
            Icons.south,
            description.isNotEmpty
                ? description
                : (note.isNotEmpty ? note : 'Pendapatan'),
          )
        : (
            Icons.north,
            description.isNotEmpty
                ? description
                : (note.isNotEmpty ? note : 'Pengeluaran'),
          );
    final dateText = DateFormatter.formatDate(transaction.date);
    final subtitle = isTagihan && note.isNotEmpty
        ? '$note • $dateText'
        : (isIncome || isPlainExpense) && (categoryName?.isNotEmpty ?? false)
        ? '$categoryName • $dateText'
        : dateText;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headline.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption1.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBalance(
              value: isIncome || isTransfer
                  ? transaction.amount
                  : -transaction.amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headline.copyWith(color: nominalColor),
              formatter: (value) => CurrencyFormatter.formatWithSign(
                value,
                showPlus: isIncome || isTagihan || isTransfer,
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: scheme.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
