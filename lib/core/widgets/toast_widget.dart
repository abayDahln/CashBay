import 'package:flutter/material.dart';

enum ToastType { info, success, error }

/// M3 snackbar helper: floats above the bottom navigation bar and FAB.
class ToastWidget {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (type) {
      ToastType.success => Icons.check_circle_outline,
      ToastType.error => Icons.error_outline,
      ToastType.info => null,
    };
    final iconColor = type == ToastType.error
        ? scheme.errorContainer
        : scheme.inversePrimary;
    // Float above the bottom navigation bar when the current screen has one,
    // so it never covers the nav bar, the FAB or the last list items.
    final hasBottomNav =
        context.findAncestorWidgetOfExactType<Scaffold>()?.bottomNavigationBar !=
        null;
    final bottomMargin = hasBottomNav ? 88.0 : 16.0;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 12, 16, bottomMargin),
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(child: Text(message)),
            ],
          ),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: ToastType.error);
}
