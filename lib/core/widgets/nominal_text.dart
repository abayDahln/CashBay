import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

/// Renders a currency amount with a smaller "Rp" prefix (in the theme's primary
/// colour) followed by the figure in the nominal font. The sign sits after "Rp"
/// (e.g. "Rp -9.274.500") as part of the figure.
class NominalText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final Color? symbolColor;

  /// Show a leading "+" for non-negative amounts (used for signed values).
  final bool showPlus;

  /// Use the short form (e.g. "Rp 2,06 Jt") instead of the full figure.
  final bool short;
  final int? maxLines;
  final TextOverflow? overflow;

  const NominalText({
    super.key,
    required this.amount,
    this.style,
    this.symbolColor,
    this.showPlus = false,
    this.short = false,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = AppTheme.nominal(style);
    final symbol = base.copyWith(
      fontSize: (base.fontSize ?? 14) * 0.6,
      color: symbolColor ?? scheme.primary,
      fontWeight: FontWeight.w500,
    );
    final String digits;
    if (short) {
      // formatMedium already carries the sign ("-Rp 11,34 Jt"); strip both the
      // leading sign and "Rp " so neither duplicates.
      digits = CurrencyFormatter.formatMedium(amount)
          .replaceFirst(RegExp(r'^[-+]?Rp '), '');
    } else {
      digits = _group(amount.abs().round());
    }
    final sign = amount < 0
        ? '-'
        : (showPlus ? '+' : '');
    return RichText(
      maxLines: maxLines ?? 1,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: 'Rp ', style: symbol),
          // Sign belongs with the figure, so it keeps the numeric style.
          TextSpan(text: '$sign$digits'),
        ],
      ),
    );
  }

  static String _group(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
