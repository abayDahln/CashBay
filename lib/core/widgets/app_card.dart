import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showBorder;
  final BorderRadiusGeometry? radius;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.showBorder = false,
    this.radius,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final side =
        border?.top ??
        (showBorder
            ? BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))
            : null);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: radius ?? BorderRadius.circular(16),
        side: side ?? BorderSide.none,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
