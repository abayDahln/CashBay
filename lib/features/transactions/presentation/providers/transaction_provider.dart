import 'package:flutter/foundation.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../../dashboard/data/repositories/wallet_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();
  final WalletRepository _walletRepository = WalletRepository();

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTransactions({
    int? walletId,
    int? categoryId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    _isLoading = true;
    _error = null;

    try {
      _transactions = await _repository.getAllTransactions(
        walletId: walletId,
        categoryId: categoryId,
        type: type,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTransaction(Transaction transaction) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _repository.insertTransaction(transaction);
      if (id > 0) {
        _transactions.insert(0, transaction.copyWith(id: id));
        await _walletRepository.recalculateWalletBalance(transaction.walletId);
        if (transaction.type == 'transfer' && transaction.toWalletId != null) {
          await _walletRepository.recalculateWalletBalance(transaction.toWalletId!);
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.updateTransaction(transaction);
      if (result > 0) {
        final index = _transactions.indexWhere((t) => t.id == transaction.id);
        if (index != -1) _transactions[index] = transaction;
        await _walletRepository.recalculateWalletBalance(transaction.walletId);
        if (transaction.type == 'transfer' && transaction.toWalletId != null) {
          await _walletRepository.recalculateWalletBalance(transaction.toWalletId!);
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTransaction(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.deleteTransaction(id);
      if (result > 0) {
        _transactions.removeWhere((t) => t.id == id);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> softDeleteTransaction(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.softDeleteTransaction(id);
      if (result > 0) {
        _transactions.removeWhere((t) => t.id == id);
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTransactionMetadata(int id, {
    String? description,
    String? note,
    String? attachmentPath,
  }) async {
    _isLoading = true;
    _error = null;

    try {
      final result = await _repository.updateTransactionMetadata(id,
        description: description,
        note: note,
        attachmentPath: attachmentPath,
      );
      if (result > 0) {
        final index = _transactions.indexWhere((t) => t.id == id);
        if (index != -1) {
          _transactions[index] = _transactions[index].copyWith(
            description: description,
            note: note,
            attachmentPath: attachmentPath,
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Transaction?> getTransactionById(int id) async {
    return await _repository.getTransactionById(id);
  }
}
