import 'package:flutter/foundation.dart';
import '../../data/models/wallet.dart';
import '../../data/repositories/wallet_repository.dart';

class WalletProvider extends ChangeNotifier {
  final WalletRepository _repository = WalletRepository();

  List<Wallet> _wallets = [];
  double _totalBalance = 0;
  bool _isLoading = false;

  List<Wallet> get wallets => _wallets;
  double get totalBalance => _totalBalance;
  bool get isLoading => _isLoading;

  Wallet? get cashWallet => _wallets.where((w) => w.type == 'cash').firstOrNull;
  Wallet? get ewalletWallet => _wallets.where((w) => w.type == 'ewallet').firstOrNull;

  Future<void> loadWallets() async {
    _isLoading = true;

    _wallets = await _repository.getAllWallets();
    _totalBalance = await _repository.getTotalBalance();

    _isLoading = false;
    notifyListeners();
  }

  /// Guarantees the two default wallets exist, recreating any that are missing
  /// (e.g. after an import from an older backup). Returns true if it changed.
  Future<bool> ensureDefaultWallets() async {
    var changed = false;
    if (cashWallet == null) {
      await _repository.insertWallet(
        Wallet(name: 'Cash', type: 'cash', balance: 0),
      );
      changed = true;
    }
    if (ewalletWallet == null) {
      await _repository.insertWallet(
        Wallet(name: 'E-Wallet', type: 'ewallet', balance: 0),
      );
      changed = true;
    }
    if (changed) await loadWallets();
    return changed;
  }

  Future<void> refreshBalances() async {
    for (final wallet in _wallets) {
      await _repository.recalculateWalletBalance(wallet.id!);
    }
    _wallets = await _repository.getAllWallets();
    _totalBalance = await _repository.getTotalBalance();
    notifyListeners();
  }

  Future<bool> adjustBalance(int walletId, double amount) async {
    final result = await _repository.adjustWalletBalance(walletId, amount);
    if (result > 0) {
      await loadWallets();
      return true;
    }
    return false;
  }
}
