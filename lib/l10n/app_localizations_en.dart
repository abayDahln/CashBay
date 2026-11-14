// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CashBay';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get history => 'History';

  @override
  String get analytics => 'Analytics';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileName => 'Name';

  @override
  String get profileNameRequired => 'Name cannot be empty';

  @override
  String get profileBio => 'Bio';

  @override
  String get profileGender => 'Gender';

  @override
  String get profileGenderMale => 'Male';

  @override
  String get profileGenderFemale => 'Female';

  @override
  String get profileGenderOther => 'Other';

  @override
  String get profileBirthDate => 'Date of Birth';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profileChangePhoto => 'Change Photo';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get close => 'Close';

  @override
  String get all => 'All';

  @override
  String get cash => 'Cash';

  @override
  String get ewallet => 'E-Wallet';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get transfer => 'Transfer';

  @override
  String get titipan => 'Deposit';

  @override
  String get titipanSaya => 'My Deposit';

  @override
  String get titipanOrang => 'Others\' Deposit';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get thisMonth => 'This Month';

  @override
  String get incomeLabel => 'Income';

  @override
  String get expenseLabel => 'Expense';

  @override
  String get titipanPiutang => 'Deposits & Receivables';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get transactionsLabel => 'Transactions';

  @override
  String get viewAll => 'View All';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get noTransactionsHint => 'Transactions you record will appear here';

  @override
  String idLabel(int id) {
    return 'ID: $id';
  }

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get detailMain => 'Main details';

  @override
  String get fundAndTime => 'Fund source & time';

  @override
  String get notesAndAttachment => 'Notes & attachment';

  @override
  String get titipanDirection => 'Deposit Direction';

  @override
  String get amountTransaction => 'Transaction amount';

  @override
  String get clearAmount => 'Clear amount';

  @override
  String get tagOptional => 'Tag (optional)';

  @override
  String get newTag => 'New tag';

  @override
  String get tagName => 'Tag name';

  @override
  String get tagNameHint => 'Example: Vacation';

  @override
  String get descriptionTransfer => 'Note (optional)';

  @override
  String get descriptionIncome => 'Income Source';

  @override
  String get descriptionExpense => 'Transaction Name';

  @override
  String get descriptionHintTransfer => 'Example: Move to E-Wallet';

  @override
  String get descriptionHintIncome => 'Example: Salary, Freelance';

  @override
  String get descriptionHintExpense => 'Example: Lunch, Fuel';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get swapWallet => 'Swap wallet';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get destinationFund => 'Destination Fund';

  @override
  String get sourceFund => 'Source Fund';

  @override
  String balanceLabel(String amount) {
    return 'Balance: $amount';
  }

  @override
  String get titipanName => 'Deposit Name';

  @override
  String get titipanNameHint => 'Example: Deposit money to Budi';

  @override
  String get titipanReceiver => 'Receiver Name';

  @override
  String get titipanGiver => 'Depositor Name';

  @override
  String get titipanReceiverHint => 'Who are you depositing to?';

  @override
  String get titipanGiverHint => 'Who is depositing?';

  @override
  String get nameLabel => 'Name';

  @override
  String get dueDate => 'Due Date';

  @override
  String get transactionDate => 'Transaction Date';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get noteHintTitipan => 'Deposit note...';

  @override
  String get noteHint => 'Add a note...';

  @override
  String get attachmentOptional => 'Photo Attachment (optional)';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get attachmentPhoto => 'Photo attachment';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get walletUnavailable => 'Wallet not available, reload the app';

  @override
  String walletNotFound(String name) {
    return '$name wallet not found';
  }

  @override
  String get walletMustDiffer => 'Source and destination wallets must differ';

  @override
  String transferExceedsBalance(String amount) {
    return 'Amount exceeds balance ($amount)';
  }

  @override
  String get allBalance => 'All';

  @override
  String transferTo(String name) {
    return 'Transfer to $name';
  }

  @override
  String get saved => 'Saved successfully';

  @override
  String get saveFailed => 'Failed to save';

  @override
  String get cashIn => 'Cash In';

  @override
  String get cashOut => 'Cash Out';

  @override
  String get searchTransaction => 'Search transactions...';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get notFound => 'Not found';

  @override
  String get tryOtherKeyword => 'Try another keyword';

  @override
  String get noTxForFilter => 'No transactions for this filter';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get filter => 'Filter';

  @override
  String get detailTitipan => 'Deposit Detail';

  @override
  String get detailTitipanOrang => 'Others\' Deposit Detail';

  @override
  String get detailPengembalian => 'Return Detail';

  @override
  String get detailPenerimaan => 'Receipt Detail';

  @override
  String get detailTransfer => 'Transfer Detail';

  @override
  String get detailIncome => 'Income Detail';

  @override
  String get detailExpense => 'Expense Detail';

  @override
  String get attachment => 'Attachment';

  @override
  String get date => 'Date';

  @override
  String get method => 'Method';

  @override
  String get sourceWallet => 'Source Wallet';

  @override
  String get destinationWallet => 'Destination Wallet';

  @override
  String get wallet => 'Wallet';

  @override
  String get description => 'Description';

  @override
  String get note => 'Note';

  @override
  String get information => 'Information';

  @override
  String get transactionInfo => 'Transaction information';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get deleteHistoryQ => 'Delete History?';

  @override
  String get deleteHistoryDesc =>
      'This history will be hidden and will not affect the current balance.';

  @override
  String get historyDeleted => 'History deleted';

  @override
  String get deleteFailed => 'Failed to delete';

  @override
  String get kindNotEditable => 'Transaction type cannot be changed.';

  @override
  String get titipanEditHint =>
      'Deposits are edited from the deposit detail screen.';

  @override
  String get amount => 'Amount';

  @override
  String get chooseWallet => 'Choose wallet';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get undoNewPhoto => 'Undo New Photo';

  @override
  String get noPhoto => 'No photo';

  @override
  String get filterTitipan => 'Filter deposits';

  @override
  String get status => 'Status';

  @override
  String get belumLunas => 'Unpaid';

  @override
  String get lunas => 'Paid';

  @override
  String get dateRange => 'Date Range';

  @override
  String get chooseDateRange => 'Choose date range';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get clearDateFilter => 'Clear date filter';

  @override
  String get addTitipan => 'Add deposit';

  @override
  String get remainingTitipanSaya => 'My remaining deposit';

  @override
  String get remainingTitipanOrang => 'Others\' remaining deposit';

  @override
  String get noActiveTitipan => 'No unpaid deposits';

  @override
  String activeTitipanCount(int count) {
    return '$count unpaid deposits';
  }

  @override
  String get thisWeek => 'This Week';

  @override
  String get previous => 'Earlier';

  @override
  String get noTitipanMatch => 'No matching deposits';

  @override
  String get changeOrResetFilter => 'Try changing or resetting the filter';

  @override
  String get resetFilter => 'Reset Filter';

  @override
  String get noTitipan => 'No deposits yet';

  @override
  String get noTitipanOrang => 'No others\' deposits yet';

  @override
  String get noTitipanHint => 'Record money you deposit to others';

  @override
  String get noTitipanOrangHint => 'Record money others entrusted to you';

  @override
  String get addTitipanOrang => 'Add Others\' Deposit';

  @override
  String get paid => 'paid';

  @override
  String get received => 'received';

  @override
  String paidFrom(String paid, String total) {
    return '$paid paid of $total';
  }

  @override
  String receivedFrom(String received, String total) {
    return '$received received of $total';
  }

  @override
  String get editTitipanAmount => 'Edit deposit amount';

  @override
  String get remaining => 'Remaining';

  @override
  String get totalTitipan => 'Total Deposit';

  @override
  String get totalTitipanOrang => 'Total Others\' Deposit';

  @override
  String get hasPaid => 'Paid';

  @override
  String get hasReceived => 'Received';

  @override
  String get dueDateLabel => 'Due date';

  @override
  String get noReturnHistory => 'No return history yet';

  @override
  String get returnHistory => 'Return History';

  @override
  String get receiveReturn => 'Receive Return';

  @override
  String get returnMoney => 'Return Money';

  @override
  String get returnRecorded => 'Return recorded';

  @override
  String get editTitipanAmountTitle => 'Edit Deposit Amount';

  @override
  String get editReturnTitle => 'Edit Return';

  @override
  String currentRemaining(String amount) {
    return 'Current remaining $amount';
  }

  @override
  String maxReturn(String amount) {
    return 'Maximum $amount';
  }

  @override
  String get titipanAmountUpdated => 'Deposit amount updated';

  @override
  String get returnUpdated => 'Return updated';

  @override
  String exceedsRemaining(String amount) {
    return 'Exceeds remaining deposit ($amount)';
  }

  @override
  String get returnDate => 'Return date';

  @override
  String saveFailedDetail(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get amountLabel => 'Amount';

  @override
  String remainingTitipan(String amount) {
    return 'Remaining deposit $amount';
  }

  @override
  String payOff(String amount) {
    return 'Pay off $amount';
  }

  @override
  String get walletIn => 'Into wallet';

  @override
  String get walletOut => 'Out of wallet';

  @override
  String get tagTransactions => 'Transaction Tags';

  @override
  String get addTag => 'Add tag';

  @override
  String noTag(String type) {
    return 'No $type tags yet';
  }

  @override
  String get addTagHint => 'Add a tag to group transactions';

  @override
  String get addTagLabel => 'Add Tag';

  @override
  String get defaultBadge => 'Default';

  @override
  String get tagOptions => 'Tag options';

  @override
  String get tagUpdated => 'Tag updated';

  @override
  String get tagAdded => 'Tag added';

  @override
  String tagInUse(String name) {
    return 'Tag \"$name\" is still used by transactions';
  }

  @override
  String checkTagFailed(String error) {
    return 'Failed to check tag: $error';
  }

  @override
  String get deleteTagQ => 'Delete Tag?';

  @override
  String deleteTagDefault(String name) {
    return 'Default tag \"$name\" will be permanently deleted.';
  }

  @override
  String deleteTagConfirm(String name) {
    return 'Tag \"$name\" will be permanently deleted.';
  }

  @override
  String get tagDeleted => 'Tag deleted';

  @override
  String get tagCannotDelete => 'Tag cannot be deleted (still in use)';

  @override
  String deleteTagFailed(String error) {
    return 'Failed to delete tag: $error';
  }

  @override
  String get tagNameField => 'Tag Name';

  @override
  String get tagNameSample => 'Example: Salary, Food, Transport';

  @override
  String tagDuplicate(String type) {
    return 'A $type tag with this name already exists';
  }

  @override
  String get tagSaveFailed => 'Failed to save tag';

  @override
  String tagSaveFailedDetail(String error) {
    return 'Failed to save tag: $error';
  }

  @override
  String get editTag => 'Edit Tag';

  @override
  String get iconSection => 'Icon';

  @override
  String get pendapatanLower => 'income';

  @override
  String get pengeluaranLower => 'expense';

  @override
  String get iconSalary => 'Salary';

  @override
  String get iconBusiness => 'Business';

  @override
  String get iconGift => 'Gift';

  @override
  String get iconInvestment => 'Investment';

  @override
  String get iconFood => 'Food';

  @override
  String get iconTransport => 'Transport';

  @override
  String get iconShopping => 'Shopping';

  @override
  String get iconHealth => 'Health';

  @override
  String get iconEducation => 'Education';

  @override
  String get iconEntertainment => 'Entertainment';

  @override
  String get iconOther => 'Other';

  @override
  String get chartCashFlow => 'Cash Flow Chart';

  @override
  String get noData => 'No data';

  @override
  String get noDataPeriod => 'No transactions in this period';

  @override
  String get modeDaily => 'Daily';

  @override
  String get modeMonthly => 'Month';

  @override
  String get modeYearly => 'Year';

  @override
  String get previousPeriod => 'Previous';

  @override
  String get nextPeriod => 'Next';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get customRange => 'Custom Range';

  @override
  String get customFilter => 'Filter';

  @override
  String get rangeStart => 'Start';

  @override
  String get rangeEnd => 'End';

  @override
  String get resetRange => 'Reset';

  @override
  String get applyRange => 'Apply';

  @override
  String get selectMonthStart => 'Select start month';

  @override
  String get selectMonthEnd => 'Select end month';

  @override
  String get selectYearStart => 'Select start year';

  @override
  String get selectYearEnd => 'Select end year';

  @override
  String get rangeMaxMonths => 'Maximum range is 12 months';

  @override
  String get rangeMaxYears => 'Maximum range is 12 years';

  @override
  String get rangeEndBeforeStart =>
      'The end month/year must be after the start';

  @override
  String get rangeFuture => 'Cannot go past the current month/year';

  @override
  String get allData => 'All data';

  @override
  String get allTime => 'All';

  @override
  String get difference => 'Difference';

  @override
  String get surplus => 'Surplus';

  @override
  String get deficit => 'Deficit';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get modeSystem => 'System';

  @override
  String get modeLight => 'Light';

  @override
  String get modeDark => 'Dark';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get customColor => 'Custom color';

  @override
  String get chooseCustomColor => 'Choose custom color';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get manageTags => 'Manage Transaction Tags';

  @override
  String get manageTagsSub => 'Add, edit, or delete transaction tags';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportSub => 'Save backup to a JSON file';

  @override
  String get importData => 'Import Data';

  @override
  String get importSub => 'Restore from a backup file';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get resetApp => 'Reset the app to its initial state';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'v1.0.0 - Personal Finance App';

  @override
  String get followSystem => 'Follow system';

  @override
  String get chooseAccentColor => 'Choose Accent Color';

  @override
  String get hue => 'Hue';

  @override
  String get saturation => 'Saturation';

  @override
  String get brightness => 'Brightness';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorRed => 'Red';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorTeal => 'Teal';

  @override
  String get appearanceTheme => 'Appearance & Theme';

  @override
  String get deleteAllQ => 'Delete All Data?';

  @override
  String get deleteAllDesc =>
      'All transaction, wallet, category, and deposit data will be deleted. This cannot be undone.';

  @override
  String get typeDeleteConfirm => 'Type CONFIRM to confirm';

  @override
  String get deleteAllConfirm => 'Delete All';

  @override
  String get allDeleted => 'All data deleted';

  @override
  String deleteAllFailed(String error) {
    return 'Failed to delete data: $error';
  }

  @override
  String exportSuccess(String path) {
    return 'Data exported to $path';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get importInvalid => 'Invalid backup file format';

  @override
  String get importSuccess => 'Data imported';

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get importQ => 'Import Data?';

  @override
  String importDesc(String when) {
    return 'Current data will be replaced with the backup file$when. This cannot be undone.';
  }

  @override
  String get replaceData => 'Replace Data';

  @override
  String get language => 'Language';

  @override
  String get languageIndonesian => 'Indonesian';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePicked => 'Language changed';

  @override
  String get chatGreeting =>
      'Hi! I\'m your finance assistant. Ask anything about your transactions and finances.';

  @override
  String get chatDeveloping => 'The chatbot feature is under development.';

  @override
  String get chatHint => 'Type a message...';

  @override
  String get sendMessage => 'Send message';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String chooseTag(Object type) {
    return 'A $type tag with this name already exists';
  }

  @override
  String backupExportedAt(String date) {
    return ' (created $date)';
  }

  @override
  String titipanOpenCount(int count) {
    return '$count Open';
  }

  @override
  String get addTitipanTitle => 'Add Deposit';

  @override
  String get personName => 'Person Name';

  @override
  String get progressPayment => 'Payment progress';

  @override
  String addAmountTooltip(String amount) {
    return 'Add $amount';
  }

  @override
  String get preset3Days => '3 Days';

  @override
  String get preset1Week => '1 Week';

  @override
  String get preset2Weeks => '2 Weeks';

  @override
  String get preset1Month => '1 Month';

  @override
  String get preset3Months => '3 Months';

  @override
  String get preset1Year => '1 Year';

  @override
  String transactionCount(int count) {
    return '$count transactions';
  }

  @override
  String get amountRequired => 'Amount is required';

  @override
  String get amountPositive => 'Amount must be greater than 0';

  @override
  String amountMin(String min) {
    return 'Minimum amount $min';
  }

  @override
  String get amountTooLarge => 'Amount is too large';

  @override
  String amountMax(String max) {
    return 'Maximum amount $max';
  }

  @override
  String get photoNotFound => 'Photo file not found';

  @override
  String get photoFormat => 'Photo format must be JPG or PNG';

  @override
  String get photoTooLarge => 'Maximum photo size is 10 MB';

  @override
  String fieldRequired(String field) {
    return '$field is required';
  }

  @override
  String fieldMinChars(String field, int n) {
    return '$field must be at least $n characters';
  }

  @override
  String fieldMaxChars(String field, int n) {
    return '$field must be at most $n characters';
  }

  @override
  String fieldNeedsLetterOrDigit(String field) {
    return '$field must contain a letter or digit';
  }

  @override
  String saveFailedError(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get tagExists => 'A tag with this name already exists';

  @override
  String totalBelowReturned(String amount) {
    return 'Total cannot be less than what was already returned ($amount)';
  }

  @override
  String get titipanIncomplete => 'Deposit data is incomplete';

  @override
  String returnExceedsTotal(String amount) {
    return 'Return cannot exceed the remaining deposit ($amount)';
  }

  @override
  String get returnIncomplete => 'Return data is incomplete';

  @override
  String get notifTitipanTitle => 'Deposit due';

  @override
  String notifTitipanBody(String name) {
    return 'The deposit with $name is due today.';
  }

  @override
  String get notifChannelName => 'Deposit Due';

  @override
  String get notifChannelDesc => 'Deposit due date reminders';
}
