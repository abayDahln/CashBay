import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/dashboard/presentation/providers/wallet_provider.dart';
import 'features/transactions/presentation/providers/transaction_provider.dart';
import 'features/debts/presentation/providers/debt_provider.dart';
import 'features/categories/presentation/providers/category_provider.dart';
import 'features/report/presentation/providers/report_provider.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

class CashBayApp extends StatelessWidget {
  const CashBayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()..loadWallets()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()..loadTransactions(limit: 10)),
        ChangeNotifierProvider(create: (_) => DebtProvider()..loadActiveDebts()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..loadCategories()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const DashboardScreen(),
      ),
    );
  }
}
