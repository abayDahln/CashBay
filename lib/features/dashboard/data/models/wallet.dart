class Wallet {
  final int? id;
  final String name;
  final String type;
  final double balance;

  Wallet({
    this.id,
    required this.name,
    required this.type,
    this.balance = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      balance: (map['balance'] as num).toDouble(),
    );
  }

  Wallet copyWith({
    int? id,
    String? name,
    String? type,
    double? balance,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
    );
  }
}