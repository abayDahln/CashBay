import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// M3 navigation bar for the four root destinations.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _destinations = <(IconData, IconData)>[
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
    (Icons.receipt_long_outlined, Icons.receipt_long),
    (Icons.insights_outlined, Icons.insights),
    (Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final labels = [t.dashboard, t.history, t.analytics, t.profile];
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        for (var i = 0; i < _destinations.length; i++)
          NavigationDestination(
            icon: Icon(_destinations[i].$1),
            selectedIcon: Icon(_destinations[i].$2),
            label: labels[i],
          ),
      ],
    );
  }
}
