import '../models/transaction.dart';
import '../../../../core/database/app_database.dart';

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
      where += 'category_id = ?';
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

    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<Transaction?> getTransactionById(int id) async {
    final db = await _db.database;
    final maps = await db.query('transactions', where: 'id = ? AND is_deleted = 0', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await _db.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await _db.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
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

  Future<double> getTotalIncome({
    int? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _getTotalAmount(walletId: walletId, type: 'income', startDate: startDate, endDate: endDate);
  }

  Future<double> getTotalExpense({
    int? walletId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _getTotalAmount(walletId: walletId, type: 'expense', startDate: startDate, endDate: endDate);
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
    return _getTotalAmount(walletId: walletId, type: 'transfer', toWalletId: walletId, startDate: startDate, endDate: endDate);
  }
}
