class AppConstants {
  static const String appName = 'CashBay';
  static const String databaseName = 'cashbay.db';
  static const int databaseVersion = 1;

  static const String walletTypeCash = 'cash';
  static const String walletTypeEwallet = 'ewallet';

  static const String transactionTypeIncome = 'income';
  static const String transactionTypeExpense = 'expense';
  static const String transactionTypeTransfer = 'transfer';

  static const String categoryTypeIncome = 'income';
  static const String categoryTypeExpense = 'expense';

  static const String debtTypeDebt = 'debt';
  static const String debtTypeReceivable = 'receivable';

  static const String debtStatusActive = 'active';
  static const String debtStatusPaid = 'paid';

  static const String defaultCashWalletName = 'Cash';
  static const String defaultEwalletWalletName = 'E-Wallet';

  static const List<String> defaultIncomeCategories = [
    'Gaji',
    'Bonus',
    'Hasil Jualan',
    'Lainnya',
  ];

  static const List<String> defaultExpenseCategories = [
    'Makan',
    'Transport',
    'Belanja',
    'Lainnya',
  ];
}