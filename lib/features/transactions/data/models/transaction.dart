class Transaction {
  final int? id;
  final String type;
  final double amount;
  final int walletId;
  final int? toWalletId;
  final List<int> categoryIds;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final String? description;
  final String paymentMethod;
  final String? attachmentPath;
  final bool isDeleted;
  final bool isTitipan;

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.walletId,
    this.toWalletId,
    this.categoryIds = const [],
    this.note,
    required this.date,
    required this.createdAt,
    this.description,
    this.paymentMethod = 'cash',
    this.attachmentPath,
    this.isDeleted = false,
    this.isTitipan = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'wallet_id': walletId,
      'to_wallet_id': toWalletId,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'payment_method': paymentMethod,
      'attachment_path': attachmentPath,
      'is_deleted': isDeleted ? 1 : 0,
      'is_titipan': isTitipan ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      walletId: map['wallet_id'] as int,
      toWalletId: map['to_wallet_id'] as int?,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      description: map['description'] as String?,
      paymentMethod: (map['payment_method'] as String?) ?? 'cash',
      attachmentPath: map['attachment_path'] as String?,
      isDeleted: (map['is_deleted'] as int?) == 1,
      isTitipan: (map['is_titipan'] as int?) == 1,
    );
  }

  Transaction copyWith({
    int? id,
    String? type,
    double? amount,
    int? walletId,
    int? toWalletId,
    List<int>? categoryIds,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    String? description,
    String? paymentMethod,
    String? attachmentPath,
    bool? isDeleted,
    bool? isTitipan,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      categoryIds: categoryIds ?? this.categoryIds,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      isDeleted: isDeleted ?? this.isDeleted,
      isTitipan: isTitipan ?? this.isTitipan,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, walletId: $walletId, toWalletId: $toWalletId, categoryIds: $categoryIds, note: $note, date: $date, createdAt: $createdAt, description: $description, paymentMethod: $paymentMethod, attachmentPath: $attachmentPath)';
  }

  // Legacy "Tagihan" descriptions and the newer "Titip" ones both count as a
  // titipan-related transaction so old data keeps rendering correctly.
  bool get isTagihan => description?.startsWith('Tagihan') == true ||
      description?.startsWith('Titip keluar') == true ||
      description?.startsWith('Titip masuk') == true;
  // Return leg: legacy "Pembayaran"/"Penerimaan" or the newer "Titip kembali".
  bool get isPembayaranTagihan =>
      description?.startsWith('Pembayaran') == true ||
      description?.startsWith('Penerimaan') == true ||
      description?.startsWith('Titip kembali') == true;
  bool get isPenerimaanTagihan => description?.startsWith('Penerimaan') == true;
  bool get isTagihanRelated => isTagihan || isPembayaranTagihan;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
