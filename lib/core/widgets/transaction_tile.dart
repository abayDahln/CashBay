import 'package:flutter/material.dart';
import '../../features/transactions/data/models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'press_card.dart';
import 'animated_balance.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final String? categoryName;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final isTagihan = transaction.isTagihanRelated;
    final isPlainExpense = transaction.type == 'expense' && !isTagihan;

    IconData icon;
    Color color;
    String label;

    final desc = transaction.description?.trim() ?? '';
    final note = transaction.note?.trim() ?? '';

    if (isTagihan) {
      if (transaction.isTagihan) {
        icon = Icons.receipt_long;
        color = AppTheme.black;
        label = transaction.description ?? 'Tagihan';
      } else if (transaction.isPembayaranTagihan) {
        icon = Icons.check_circle_outline;
        color = AppTheme.black;
        label = transaction.description ?? 'Pembayaran';
      } else {
        icon = Icons.file_download;
        color = AppTheme.black;
        label = transaction.description ?? 'Penerimaan';
      }
    } else if (isTransfer) {
      icon = Icons.swap_horiz;
      color = AppTheme.black;
      label = desc.isNotEmpty ? desc : 'Transfer';
    } else if (isIncome) {
      icon = Icons.arrow_downward;
      color = AppTheme.black;
      label = desc.isNotEmpty ? desc : (note.isNotEmpty ? note : 'Pendapatan');
    } else {
      icon = Icons.arrow_upward;
      color = AppTheme.black;
      label = desc.isNotEmpty ? desc : (note.isNotEmpty ? note : 'Pengeluaran');
    }

    final dateText = DateFormatter.formatDate(transaction.date);
    final String subtitle;
    if (isTagihan && (transaction.note?.isNotEmpty ?? false)) {
      subtitle = '${transaction.note} • $dateText';
    } else if ((isIncome || isPlainExpense) && (categoryName?.isNotEmpty ?? false)) {
      subtitle = '$categoryName • $dateText';
    } else {
      subtitle = dateText;
    }

    return PressCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBalance(
              value: isIncome || isTransfer
                  ? transaction.amount
                  : -transaction.amount,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              formatter: (v) =>
                  CurrencyFormatter.formatWithSign(v, showPlus: isIncome || isTagihan || isTransfer),
            ),
          ],
        ),
      ),
    );
  }
}
