import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_preferences_provider.dart';
import 'core/constants/app_constants.dart';
import 'features/dashboard/presentation/providers/wallet_provider.dart';
import 'features/transactions/presentation/providers/transaction_provider.dart';
import 'features/debts/presentation/providers/debt_provider.dart';
import 'features/categories/presentation/providers/category_provider.dart';
import 'features/report/presentation/providers/report_provider.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

class CashBayApp extends StatelessWidget {
  final ThemePreferencesProvider? themePreferences;

  const CashBayApp({super.key, this.themePreferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              themePreferences ?? (ThemePreferencesProvider()..load()),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider()..ensureDefaultWallets(),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider()..loadTransactions(limit: 10),
        ),
        ChangeNotifierProvider(
          create: (_) => DebtProvider()..loadActiveDebts(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider()..loadCategories(),
        ),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: Consumer<ThemePreferencesProvider>(
        builder: (context, preferences, child) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightThemeFor(preferences.seedColor),
            darkTheme: AppTheme.darkThemeFor(preferences.seedColor),
            themeMode: preferences.themeMode,
            debugShowCheckedModeBanner: false,
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}
