import '../models/transaction.dart';
import '../../../../core/database/app_database.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

class TransactionRepository {
  final AppDatabase _db = AppDatabase();

  Future<List<Transaction>> getAllTransactions({
    int? walletId,
    String? type,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
    bool includeDeleted = false,
  }) async {
    final db = await _db.database;
    
    String where = '';
    List<dynamic> whereArgs = [];

    if (!includeDeleted) {
      where = 'is_deleted = 0';
    }

    if (walletId != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'wallet_id = ?';
      whereArgs.add(walletId);
    }

    if (type != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'type = ?';
      whereArgs.add(type);
    }

    if (categoryId != null) {
      if (where.isNotEmpty) where += ' AND ';
      where +=
          'id IN (SELECT transaction_id FROM transaction_tags WHERE category_id = ?)';
      whereArgs.add(categoryId);
    }

    if (startDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'transactions',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    return _withTags(db, maps.map((map) => Transaction.fromMap(map)).toList());
  }

  /// Loads each transaction's tag ids in one query.
  Future<List<Transaction>> _withTags(
    Database db,
    List<Transaction> transactions,
  ) async {
    if (transactions.isEmpty) return transactions;
    final ids = transactions.map((t) => t.id).whereType<int>().toList();
    final rows = await db.query(
      'transaction_tags',
      where: 'transaction_id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
    final byTransaction = <int, List<int>>{};
    for (final row in rows) {
      byTransaction
          .putIfAbsent(row['transaction_id'] as int, () => [])
          .add(row['category_id'] as int);
    }
    return [
      for (final t in transactions)
        t.copyWith(categoryIds: byTransaction[t.id] ?? const []),
    ];
  }

  Future<void> _replaceTags(Database db, int transactionId, List<int> categoryIds) async {
    await db.delete(
      'transaction_tags',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    for (final categoryId in categoryIds.toSet()) {
      await db.insert('transaction_tags', {
        'transaction_id': transactionId,
        'category_id': categoryId,
      });
    }
  }

  Future<Transaction?> getTransactionById(int id) async {
    final db = await _db.database;
    final maps = await db.query('transactions', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final loaded = await _withTags(db, [Transaction.fromMap(maps.first)]);
    return loaded.first;
  }

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await _db.database;
    final id = await db.insert('transactions', transaction.toMap());
    await _replaceTags(db, id, transaction.categoryIds);
    return id;
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await _db.database;
    final result = await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    if (transaction.id != null) {
      await _replaceTags(db, transaction.id!, transaction.categoryIds);
    }
    return result;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await _db.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTransactionMetadata(int id, {
    String? description,
    String? note,
    String? attachmentPath,
  }) async {
    final db = await _db.database;
    final values = <String, dynamic>{};
    if (description != null) values['description'] = description;
    if (note != null) values['note'] = note;
    if (attachmentPath != null) values['attachment_path'] = attachmentPath;
    if (values.isEmpty) return 0;
    return await db.update(
      'transactions',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> softDeleteTransaction(int id) async {
    final db = await _db.database;
    return await db.update(
      'transactions',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> _getTotalAmount({
    int? walletId,
    String? type,
    int? toWalletId,
    DateTime? startDate,
    DateTime? endDate,
    bool excludeTitipan = false,
  }) async {
    final db = await _db.database;
    
    String where = 'is_deleted = 0';
    List<dynamic> whereArgs = [];

    if (walletId != null) {
      where += ' AND wallet_id = ?';
      whereArgs.add(walletId);
    }

    if (type != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'type = ?';
      whereArgs.add(type);
    }

    if (toWalletId != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'to_wallet_id = ?';
      whereArgs.add(toWalletId);
    }

    if (excludeTitipan) {
      where += ' AND is_titipan = 0';
    }

    if (startDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions ${where.isEmpty ? "" : "WHERE $where"}',
      whereArgs,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Income total. Pass [excludeTitipan] for real income only; the wallet
  /// balance recalculation leaves it false so titipan still moves balances.
  Future<double> getTotalIncome({
    int? walletId,
    DateTime? startDate,
    DateTime? endDate,
    bool excludeTitipan = false,
  }) async {
    return _getTotalAmount(
      walletId: walletId,
      type: 'income',
      startDate: startDate,
      endDate: endDate,
      excludeTitipan: excludeTitipan,
    );
  }

  Future<double> getTotalExpense({
    int? walletId,
    DateTime? startDate,
    DateTime? endDate,
    bool excludeTitipan = false,
  }) async {
    return _getTotalAmount(
      walletId: walletId,
      type: 'expense',
      startDate: startDate,
      endDate: endDate,
      excludeTitipan: excludeTitipan,
    );
  }

  Future<double> getTotalTransferOut({
    int? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _getTotalAmount(walletId: walletId, type: 'transfer', startDate: startDate, endDate: endDate);
  }

  Future<double> getTotalTransferIn({
    int? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Only the destination column matters for money coming in; passing
    // walletId too would require source == destination, which never matches.
    return _getTotalAmount(toWalletId: walletId, type: 'transfer', startDate: startDate, endDate: endDate);
  }
}
