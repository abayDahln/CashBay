import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/locale_provider.dart';
import 'core/theme/theme_preferences_provider.dart';
import 'core/constants/app_constants.dart';
import 'l10n/app_localizations.dart';
import 'features/dashboard/presentation/providers/wallet_provider.dart';
import 'features/transactions/presentation/providers/transaction_provider.dart';
import 'features/debts/presentation/providers/debt_provider.dart';
import 'features/categories/presentation/providers/category_provider.dart';
import 'features/report/presentation/providers/report_provider.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

class CashBayApp extends StatelessWidget {
  final ThemePreferencesProvider? themePreferences;
  final LocaleProvider? localeProvider;

  const CashBayApp({super.key, this.themePreferences, this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              themePreferences ?? (ThemePreferencesProvider()..load()),
        ),
        ChangeNotifierProvider(
          create: (_) => localeProvider ?? (LocaleProvider()..load()),
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
      child: Consumer2<ThemePreferencesProvider, LocaleProvider>(
        builder: (context, preferences, locale, child) {
          final app = MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightThemeFor(preferences.seedColor),
            darkTheme: AppTheme.darkThemeFor(preferences.seedColor),
            themeMode: preferences.themeMode,
            locale: locale.locale,
            supportedLocales: LocaleProvider.supported,
            localizationsDelegates: const [
              L.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            home: const DashboardScreen(),
          );
          // Windows-only backstop for the engine's ui::AXTree desync bug: an
          // empty semantics tree can never desync. Other platforms keep full
          // accessibility.
          return Platform.isWindows ? ExcludeSemantics(child: app) : app;
        },
      ),
    );
  }
}
