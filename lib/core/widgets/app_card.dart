import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry radius;
  final EdgeInsetsGeometry padding;
  final bool showBorder;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.radius = const BorderRadius.all(Radius.circular(20)),
    this.padding = const EdgeInsets.all(16),
    this.showBorder = false,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = border ??
        (showBorder ? Border.all(color: Colors.grey.shade300, width: 1) : null);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: effectiveBorder != null ? radius : null,
          border: effectiveBorder,
          boxShadow: boxShadow,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
