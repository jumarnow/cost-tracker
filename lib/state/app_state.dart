import 'package:flutter/foundation.dart';

import '../data/transaction_repository.dart';
import '../data/wallet_repository.dart';
import '../models/transaction_model.dart';
import '../models/transaction_model.dart';

class AppState extends ChangeNotifier {
  final TransactionRepository repo;
  final WalletRepository walletRepo;

  AppState(this.repo, this.walletRepo);

  List<TransactionEntry> _entries = const [];
  List<TransactionEntry> get entries => _entries;

  double _balance = 0;
  double get balance => _balance;

  double _today = 0;
  double get today => _today;

  double _month = 0;
  double get month => _month;

  void load() {
    _entries = repo.getAll();
    _recompute();
  }

  void bind() {
    repo.listenable().addListener(() {
      load();
      notifyListeners();
    });
    load();
  }

  Future<void> addTransaction(TransactionModel m) async {
    await repo.add(m);
    await _applyWalletDelta(newTx: m);
  }

  Future<void> updateTransaction(int key, TransactionModel newTx, TransactionModel oldTx) async {
    await repo.update(key, newTx);
    await _applyWalletDelta(newTx: newTx, oldTx: oldTx);
  }

  Future<void> deleteTransaction(TransactionEntry entry) async {
    await repo.delete(entry.key);
    await _applyWalletDelta(oldTx: entry.model, reverseOnly: true);
  }

  Future<void> _applyWalletDelta({TransactionModel? newTx, TransactionModel? oldTx, bool reverseOnly = false}) async {
    // Undo old transaction effect
    if (oldTx != null) {
      final oldWallet = walletRepo.getById(oldTx.walletId)!;
      final delta = oldTx.type == TransactionType.income ? -oldTx.amount : oldTx.amount;
      await walletRepo.upsertById(oldWallet.copyWith(balance: oldWallet.balance + delta));
    }
    if (reverseOnly) return;
    if (newTx != null) {
      final newWallet = walletRepo.getById(newTx.walletId)!;
      final delta = newTx.type == TransactionType.income ? newTx.amount : -newTx.amount;
      await walletRepo.upsertById(newWallet.copyWith(balance: newWallet.balance + delta));
    }
  }

  void _recompute() {
    _balance = repo.totalBalance();
    final now = DateTime.now();
    _today = repo.totalForDay(now);
    _month = repo.totalForMonth(now);
  }
}
