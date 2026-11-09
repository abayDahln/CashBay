import 'package:flutter/foundation.dart';
import '../../data/models/debt.dart';
import '../../data/models/debt_payment.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/repositories/debt_repository.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../dashboard/data/repositories/wallet_repository.dart';
import '../../../../core/services/notification_service.dart';

class DebtProvider extends ChangeNotifier {
  final DebtRepository _repository = DebtRepository();
  final WalletRepository _walletRepository = WalletRepository();

  List<Debt> _debts = [];
  List<Debt> _receivables = [];
  List<DebtPayment> _selectedDebtPayments = [];
  bool _isLoading = false;
  String? _error;

  List<Debt> get debts => _debts;
  List<Debt> get receivables => _receivables;
  List<DebtPayment> get selectedDebtPayments => _selectedDebtPayments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalActiveDebt =>
      _debts.where((d) => d.status == 'active').fold(0.0, (sum, d) => sum + d.remainingAmount);

  double get totalActiveReceivable =>
      _receivables.where((d) => d.status == 'active').fold(0.0, (sum, d) => sum + d.remainingAmount);

  Future<void> loadDebts() async {
    _isLoading = true;
    _error = null;

    try {
      _debts = await _repository.getDebtsByType('debt');
      _receivables = await _repository.getDebtsByType('receivable');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadActiveDebts() async {
    _isLoading = true;
    _error = null;

    try {
      _debts = await _repository.getDebtsByType('debt', activeOnly: true);
      _receivables = await _repository.getDebtsByType('receivable', activeOnly: true);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllDebts() async {
    _isLoading = true;
    _error = null;

    try {
      _debts = await _repository.getDebtsByType('debt');
      _receivables = await _repository.getDebtsByType('receivable');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDebtPayments(int debtId) async {
    try {
      _selectedDebtPayments = await _repository.getPaymentsForDebt(debtId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> addDebt(Debt debt) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final txnRepo = TransactionRepository();
      // Leg "beri": moving the money in/out of the wallet at creation time.
      // Titipan Saya (debt): money leaves the wallet -> expense.
      // Titipan Orang (receivable): money enters the wallet -> income.
      final openTxnId = await txnRepo.insertTransaction(
        Transaction(
          type: debt.type == 'debt' ? 'expense' : 'income',
          amount: debt.amount,
          walletId: debt.walletId,
          note: debt.note,
          date: debt.date,
          createdAt: DateTime.now(),
          description: debt.type == 'debt'
              ? 'Titip keluar ${debt.personName}'
              : 'Titip masuk ${debt.personName}',
          paymentMethod: debt.paymentMethod,
        ),
      );

      final id = await _repository.insertDebt(debt.copyWith(openTxnId: openTxnId));
      if (id > 0) {
        final newDebt = debt.copyWith(id: id, openTxnId: openTxnId);
        if (debt.type == 'debt') {
          _debts.insert(0, newDebt);
        } else {
          _receivables.insert(0, newDebt);
        }
        await _walletRepository.recalculateWalletBalance(debt.walletId);
        if (newDebt.dueDate != null) {
          await NotificationService.instance.scheduleDueDate(
            titipanId: id,
            personName: newDebt.personName,
            dueDate: newDebt.dueDate!,
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

  Future<bool> updateDebt(Debt debt) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.updateDebt(debt);
      if (result > 0) {
        if (debt.type == 'debt') {
          final index = _debts.indexWhere((d) => d.id == debt.id);
          if (index != -1) _debts[index] = debt;
        } else {
          final index = _receivables.indexWhere((d) => d.id == debt.id);
          if (index != -1) _receivables[index] = debt;
        }
        await _walletRepository.recalculateWalletBalance(debt.walletId);
        await _syncReminder(debt);
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

  Future<bool> addPayment(DebtPayment payment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _repository.insertPayment(payment);
      if (id > 0) {
        final debt = _debts.firstWhere((d) => d.id == payment.debtId, orElse: () =>
            _receivables.firstWhere((d) => d.id == payment.debtId));
        final newRemaining = debt.remainingAmount - payment.amount;
        final updatedDebt = debt.copyWith(
          remainingAmount: newRemaining,
          status: newRemaining <= 0 ? 'paid' : 'active',
        );
        await updateDebt(updatedDebt);
        final txnRepo = TransactionRepository();
        // Leg "kembali": the money moves back the other way.
        // Titipan Saya (debt): the other person returns it -> income.
        // Titipan Orang (receivable): I return it -> expense.
        final txnId = await txnRepo.insertTransaction(
          Transaction(
            type: debt.type == 'debt' ? 'income' : 'expense',
            amount: payment.amount,
            walletId: payment.walletId,
            note: debt.note,
            date: payment.date,
            createdAt: DateTime.now(),
            description: debt.type == 'debt'
                ? 'Titip kembali dari ${debt.personName}'
                : 'Titip kembali ke ${debt.personName}',
            paymentMethod: debt.paymentMethod,
          ),
        );
        final newPayment = payment.copyWith(id: id, txnId: txnId);
        await _repository.updateDebtPayment(newPayment);
        _selectedDebtPayments.insert(0, newPayment);
        await _walletRepository.recalculateWalletBalance(payment.walletId);
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

  /// Keeps the due-date reminder in sync: cancelled once settled, else
  /// (re)scheduled when a due date exists.
  Future<void> _syncReminder(Debt debt) async {
    if (debt.id == null) return;
    if (debt.status == 'paid' || debt.dueDate == null) {
      await NotificationService.instance.cancel(debt.id!);
      return;
    }
    await NotificationService.instance.scheduleDueDate(
      titipanId: debt.id!,
      personName: debt.personName,
      dueDate: debt.dueDate!,
    );
  }

  Future<bool> deleteDebt(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final debt = _debts.firstWhere((d) => d.id == id, orElse: () =>
          _receivables.firstWhere((d) => d.id == id));
      // Roll back the money: drop the opening leg and every return leg.
      final txnRepo = TransactionRepository();
      if (debt.openTxnId != null) {
        await txnRepo.deleteTransaction(debt.openTxnId!);
      }
      final payments = await _repository.getPaymentsForDebt(id);
      for (final payment in payments) {
        if (payment.txnId != null) {
          await txnRepo.deleteTransaction(payment.txnId!);
        }
        await _repository.deleteDebtPayment(payment.id!);
      }
      final result = await _repository.deleteDebt(id);
      if (result > 0) {
        _debts.removeWhere((d) => d.id == id);
        _receivables.removeWhere((d) => d.id == id);
        await NotificationService.instance.cancel(id);
        await _walletRepository.recalculateWalletBalance(debt.walletId);
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
}
