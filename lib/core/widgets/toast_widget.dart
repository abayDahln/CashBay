import 'package:flutter/material.dart';

enum ToastType { info, success, error }

/// M3 snackbar helper: a floating rounded card inset from the edges, resting
/// just above the bottom navigation bar (when the screen has one). The
/// Scaffold lifts the floating action button while it is visible.
class ToastWidget {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
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
    // The floating snackbar is measured from the top of the bottom navigation
    // bar (or the screen edge), so a small gap lifts it just clear of the bar
    // and the floating action button.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: ToastType.error);
}
