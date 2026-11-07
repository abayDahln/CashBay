import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final String? buttonLabel;
  final IconData? buttonIcon;
  final VoidCallback? onButtonTap;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.buttonLabel,
    this.buttonIcon,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (buttonLabel != null && onButtonTap != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onButtonTap,
              icon: Icon(buttonIcon ?? Icons.add),
              label: Text(buttonLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}
