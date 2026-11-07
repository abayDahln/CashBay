import 'package:flutter/material.dart';

enum AppCardVariant { filled, outlined, elevated }

/// M3 card. `filled` (default) uses `surfaceContainerHighest`, `outlined`
/// uses `surface` + `outlineVariant`, `elevated` uses `surfaceContainerLow`.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final AppCardVariant variant;
  final BorderRadiusGeometry? radius;
  final VoidCallback? onTap;
  final Color? color;

  /// Kept for backwards compatibility: `true` is the same as
  /// `variant: AppCardVariant.outlined`.
  final bool showBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.variant = AppCardVariant.filled,
    this.radius,
    this.onTap,
    this.color,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = showBorder ? AppCardVariant.outlined : variant;
    final shape = RoundedRectangleBorder(
      borderRadius: radius ?? BorderRadius.circular(12),
      side: v == AppCardVariant.outlined
          ? BorderSide(color: scheme.outlineVariant)
          : BorderSide.none,
    );
    final content = Padding(padding: padding, child: child);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: v == AppCardVariant.elevated ? 1 : 0,
      color: color ??
          switch (v) {
            AppCardVariant.filled => scheme.surfaceContainerHighest,
            AppCardVariant.outlined => scheme.surface,
            AppCardVariant.elevated => scheme.surfaceContainerLow,
          },
      shape: shape,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
