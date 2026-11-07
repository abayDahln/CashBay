import 'package:flutter/material.dart';

/// M3 navigation bar for the four root destinations.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _destinations = <(IconData, IconData, String)>[
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Dashboard'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Riwayat'),
    (Icons.insights_outlined, Icons.insights, 'Analytics'),
    (Icons.settings_outlined, Icons.settings, 'Pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        for (final (outlined, filled, label) in _destinations)
          NavigationDestination(
            icon: Icon(outlined),
            selectedIcon: Icon(filled),
            label: label,
          ),
      ],
    );
  }
}
