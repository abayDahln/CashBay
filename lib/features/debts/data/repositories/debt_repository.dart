import '../models/debt.dart';
import '../models/debt_payment.dart';
import '../../../../core/database/app_database.dart';

class DebtRepository {
  final AppDatabase _db = AppDatabase();

  Future<List<Debt>> getAllDebts({String? type, String? status}) async {
    final db = await _db.database;
    
    String where = '';
    List<dynamic> whereArgs = [];

    if (type != null) {
      where += 'type = ?';
      whereArgs.add(type);
    }

    if (status != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'status = ?';
      whereArgs.add(status);
    }

    final maps = await db.query(
      'debts',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map((map) => Debt.fromMap(map)).toList();
  }

  Future<List<Debt>> getDebtsByType(String type, {bool activeOnly = false}) async {
    final db = await _db.database;
    
    String where = 'type = ?';
    List<dynamic> whereArgs = [type];

    if (activeOnly) {
      where += ' AND status = ?';
      whereArgs.add('active');
    }

    final maps = await db.query(
      'debts',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map((map) => Debt.fromMap(map)).toList();
  }

  Future<Debt?> getDebtById(int id) async {
    final db = await _db.database;
    final maps = await db.query('debts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Debt.fromMap(maps.first);
  }

  Future<int> insertDebt(Debt debt) async {
    final db = await _db.database;
    return await db.insert('debts', debt.toMap());
  }

  Future<int> updateDebt(Debt debt) async {
    final db = await _db.database;
    return await db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<int> deleteDebt(int id) async {
    final db = await _db.database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DebtPayment>> getDebtPayments(int debtId) async {
    final db = await _db.database;
    final maps = await db.query(
      'debt_payments',
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => DebtPayment.fromMap(map)).toList();
  }

  Future<List<DebtPayment>> getPaymentsForDebt(int debtId) async {
    return getDebtPayments(debtId);
  }

  Future<int> insertDebtPayment(DebtPayment payment) async {
    final db = await _db.database;
    return await db.insert('debt_payments', payment.toMap());
  }

  Future<int> insertPayment(DebtPayment payment) async {
    return insertDebtPayment(payment);
  }

  Future<int> updateDebtPayment(DebtPayment payment) async {
    final db = await _db.database;
    return await db.update(
      'debt_payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deleteDebtPayment(int id) async {
    final db = await _db.database;
    return await db.delete('debt_payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalActiveDebtAmount({String? type}) async {
    final db = await _db.database;
    
    String where = 'status = ?';
    List<dynamic> whereArgs = ['active'];

    if (type != null) {
      where += ' AND type = ?';
      whereArgs.add(type);
    }

    final result = await db.rawQuery(
      'SELECT SUM(remaining_amount) as total FROM debts WHERE $where',
      whereArgs,
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
