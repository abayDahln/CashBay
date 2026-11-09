class Debt {
  final int? id;
  final String type;
  final String personName;
  final double amount;
  final double remainingAmount;
  final int walletId;
  final String status;
  final String? note;
  final DateTime date;
  final String? billName;
  final DateTime? dueDate;
  final bool reminderEnabled;
  final String paymentMethod;
  final String? attachmentPath;
  final int? openTxnId;

  Debt({
    this.id,
    required this.type,
    required this.personName,
    required this.amount,
    required this.remainingAmount,
    required this.walletId,
    required this.status,
    this.note,
    required this.date,
    this.billName,
    this.dueDate,
    this.reminderEnabled = false,
    this.paymentMethod = 'cash',
    this.attachmentPath,
    this.openTxnId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'person_name': personName,
      'amount': amount,
      'remaining_amount': remainingAmount,
      'wallet_id': walletId,
      'status': status,
      'note': note,
      'date': date.toIso8601String(),
      'bill_name': billName,
      'due_date': dueDate?.toIso8601String(),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'payment_method': paymentMethod,
      'attachment_path': attachmentPath,
      'open_txn_id': openTxnId,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as int?,
      type: map['type'] as String,
      personName: map['person_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      remainingAmount: (map['remaining_amount'] as num).toDouble(),
      walletId: map['wallet_id'] as int,
      status: map['status'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      billName: map['bill_name'] as String?,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      reminderEnabled: (map['reminder_enabled'] as int?) == 1,
      paymentMethod: (map['payment_method'] as String?) ?? 'cash',
      attachmentPath: map['attachment_path'] as String?,
      openTxnId: map['open_txn_id'] as int?,
    );
  }

  Debt copyWith({
    int? id,
    String? type,
    String? personName,
    double? amount,
    double? remainingAmount,
    int? walletId,
    String? status,
    String? note,
    DateTime? date,
    String? billName,
    DateTime? dueDate,
    bool? reminderEnabled,
    String? paymentMethod,
    String? attachmentPath,
    int? openTxnId,
  }) {
    return Debt(
      id: id ?? this.id,
      type: type ?? this.type,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      walletId: walletId ?? this.walletId,
      status: status ?? this.status,
      note: note ?? this.note,
      date: date ?? this.date,
      billName: billName ?? this.billName,
      dueDate: dueDate ?? this.dueDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      openTxnId: openTxnId ?? this.openTxnId,
    );
  }

  bool get isPaid => status == 'paid';
  bool get isDebt => type == 'debt';
  bool get isReceivable => type == 'receivable';

  @override
  String toString() {
    return 'Debt(id: $id, type: $type, personName: $personName, amount: $amount, remainingAmount: $remainingAmount, walletId: $walletId, status: $status, note: $note, date: $date, billName: $billName, dueDate: $dueDate, reminderEnabled: $reminderEnabled, paymentMethod: $paymentMethod)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Debt && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
