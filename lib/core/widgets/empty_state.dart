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
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(color: Colors.grey[500]),
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
    );
  }
}
