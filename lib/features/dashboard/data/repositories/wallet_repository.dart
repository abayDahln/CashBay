import '../models/wallet.dart';
import '../../../../core/database/app_database.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';

class WalletRepository {
  final AppDatabase _db = AppDatabase();
  final TransactionRepository _transactionRepo = TransactionRepository();

  Future<List<Wallet>> getAllWallets() async {
    final db = await _db.database;
    final maps = await db.query('wallets', orderBy: 'id ASC');
    return maps.map((map) => Wallet.fromMap(map)).toList();
  }

  Future<Wallet?> getWalletById(int id) async {
    final db = await _db.database;
    final maps = await db.query('wallets', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Wallet.fromMap(maps.first);
  }

  Future<Wallet?> getWalletByType(String type) async {
    final db = await _db.database;
    final maps = await db.query(
      'wallets',
      where: 'type = ?',
      whereArgs: [type],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Wallet.fromMap(maps.first);
  }

  Future<int> insertWallet(Wallet wallet) async {
    final db = await _db.database;
    return await db.insert('wallets', wallet.toMap());
  }

  Future<int> updateWallet(Wallet wallet) async {
    final db = await _db.database;
    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<int> deleteWallet(int id) async {
    final db = await _db.database;
    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateWalletBalance(int walletId, double newBalance) async {
    final db = await _db.database;
    return await db.update(
      'wallets',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }

  Future<int> adjustWalletBalance(int walletId, double amount) async {
    final wallet = await getWalletById(walletId);
    if (wallet == null) return 0;
    final newBalance = wallet.balance + amount;
    return await updateWalletBalance(walletId, newBalance);
  }

  Future<double> recalculateWalletBalance(int walletId) async {
    final income = await _transactionRepo.getTotalIncome(walletId: walletId);
    final expense = await _transactionRepo.getTotalExpense(walletId: walletId);
    final transferOut = await _transactionRepo.getTotalTransferOut(walletId: walletId);
    final transferIn = await _transactionRepo.getTotalTransferIn(walletId: walletId);

    double balance = income - expense - transferOut + transferIn;

    await updateWalletBalance(walletId, balance);
    return balance;
  }

  Future<void> recalculateAllBalances() async {
    final wallets = await getAllWallets();
    for (final wallet in wallets) {
      if (wallet.id != null) {
        await recalculateWalletBalance(wallet.id!);
      }
    }
  }

  Future<double> getTotalBalance() async {
    final wallets = await getAllWallets();
    return wallets.fold<double>(0.0, (sum, wallet) => sum + (wallet.balance));
  }
}
