class DebtPayment {
  final int? id;
  final int debtId;
  final double amount;
  final int walletId;
  final DateTime date;

  DebtPayment({
    this.id,
    required this.debtId,
    required this.amount,
    required this.walletId,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debt_id': debtId,
      'amount': amount,
      'wallet_id': walletId,
      'date': date.toIso8601String(),
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'] as int?,
      debtId: map['debt_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      walletId: map['wallet_id'] as int,
      date: DateTime.parse(map['date'] as String),
    );
  }

  DebtPayment copyWith({
    int? id,
    int? debtId,
    double? amount,
    int? walletId,
    DateTime? date,
  }) {
    return DebtPayment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'DebtPayment(id: $id, debtId: $debtId, amount: $amount, walletId: $walletId, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebtPayment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}