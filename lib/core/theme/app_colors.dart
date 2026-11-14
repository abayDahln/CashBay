import 'package:flutter/material.dart';

/// Finance-specific colour roles, following M3 role pairing
/// (`x` for text/icons, `xContainer` + `onXContainer` for tonal fills).
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  final Color income;
  final Color incomeContainer;
  final Color onIncomeContainer;
  final Color expense;
  final Color expenseContainer;
  final Color onExpenseContainer;
  final Color transfer;
  final Color transferContainer;
  final Color onTransferContainer;

  const FinanceColors({
    required this.income,
    required this.incomeContainer,
    required this.onIncomeContainer,
    required this.expense,
    required this.expenseContainer,
    required this.onExpenseContainer,
    required this.transfer,
    required this.transferContainer,
    required this.onTransferContainer,
  });

  static const light = FinanceColors(
    income: Color(0xFF146C2E),
    incomeContainer: Color(0xFFB7F1BC),
    onIncomeContainer: Color(0xFF002109),
    expense: Color(0xFFBA1A1A),
    expenseContainer: Color(0xFFFFDAD6),
    onExpenseContainer: Color(0xFF410002),
    transfer: Color(0xFF00629E),
    transferContainer: Color(0xFFCFE5FF),
    onTransferContainer: Color(0xFF001D34),
  );

  static const dark = FinanceColors(
    income: Color(0xFF7DDC8B),
    incomeContainer: Color(0xFF005320),
    onIncomeContainer: Color(0xFFB7F1BC),
    expense: Color(0xFFFFB4AB),
    expenseContainer: Color(0xFF93000A),
    onExpenseContainer: Color(0xFFFFDAD6),
    transfer: Color(0xFF99CBFF),
    transferContainer: Color(0xFF004A78),
    onTransferContainer: Color(0xFFCFE5FF),
  );

  static FinanceColors forBrightness(Brightness b) =>
      b == Brightness.dark ? dark : light;

  static FinanceColors of(BuildContext context) =>
      Theme.of(context).extension<FinanceColors>() ??
      forBrightness(Theme.of(context).brightness);

  /// Colour for an amount of the given transaction type
  /// (`income`, `expense`, `transfer`).
  Color forType(String type) => switch (type) {
    'income' => income,
    'transfer' => transfer,
    _ => expense,
  };

  @override
  FinanceColors copyWith() => this;

  @override
  FinanceColors lerp(FinanceColors? other, double t) {
    if (other == null) return this;
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      onIncomeContainer:
          Color.lerp(onIncomeContainer, other.onIncomeContainer, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseContainer:
          Color.lerp(expenseContainer, other.expenseContainer, t)!,
      onExpenseContainer:
          Color.lerp(onExpenseContainer, other.onExpenseContainer, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      transferContainer:
          Color.lerp(transferContainer, other.transferContainer, t)!,
      onTransferContainer:
          Color.lerp(onTransferContainer, other.onTransferContainer, t)!,
    );
  }
}

/// Typeface note: the app uses Flutter's default font (Roboto on Android,
/// SF Pro on iOS) so the M3 type scale stays untouched. Sizes/weights come
/// from `Theme.of(context).textTheme`.
class AppTypography {
  const AppTypography._();
}
