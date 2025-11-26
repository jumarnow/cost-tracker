import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';
import '../models/budget_model.dart';
import '../data/transaction_repository.dart';
import '../data/category_repository.dart';
import '../data/wallet_repository.dart';
import '../data/budget_repository.dart';

class ExportService {
  final TransactionRepository transactionRepo;
  final CategoryRepository categoryRepo;
  final WalletRepository walletRepo;
  final BudgetRepository budgetRepo;

  ExportService({
    required this.transactionRepo,
    required this.categoryRepo,
    required this.walletRepo,
    required this.budgetRepo,
  });

  /// Export all data to JSON
  /// Returns the file in temp directory - use share or save afterwards
  Future<File> exportToJson() async {
    final data = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'transactions': transactionRepo.getAll().map((e) => {
        'id': e.model.id,
        'amount': e.model.amount,
        'type': e.model.type.name,
        'categoryId': e.model.categoryId,
        'walletId': e.model.walletId,
        'note': e.model.note,
        'date': e.model.date.toIso8601String(),
      }).toList(),
      'categories': categoryRepo.all().map((c) => {
        'id': c.id,
        'name': c.name,
        'iconCodePoint': c.iconCodePoint,
        'type': c.type.name,
      }).toList(),
      'wallets': walletRepo.all().map((w) => {
        'id': w.id,
        'name': w.name,
        'balance': w.balance,
      }).toList(),
      'budgets': budgetRepo.all().map((b) => {
        'id': b.id,
        'categoryId': b.categoryId,
        'year': b.year,
        'month': b.month,
        'limit': b.limit,
      }).toList(),
    };

    // Create file in temporary directory first
    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/finance_tracker_backup_$timestamp.json');
    
    await file.writeAsString(jsonEncode(data));
    return file;
  }

  /// Export transactions to CSV
  /// Returns the file in temp directory - use share or save afterwards
  Future<File> exportTransactionsToCsv({DateTime? startDate, DateTime? endDate}) async {
    final entries = transactionRepo.getAll();
    final filtered = entries.where((e) {
      if (startDate != null && e.model.date.isBefore(startDate)) return false;
      if (endDate != null && e.model.date.isAfter(endDate)) return false;
      return true;
    }).toList();

    final csvLines = <String>[];
    csvLines.add('Date,Type,Category,Wallet,Amount,Note');

    for (final entry in filtered) {
      final model = entry.model;
      final category = categoryRepo.getById(model.categoryId);
      final wallet = walletRepo.getById(model.walletId);
      
      final line = [
        DateFormat('yyyy-MM-dd HH:mm').format(model.date),
        model.type.name,
        category?.name ?? 'Unknown',
        wallet?.name ?? 'Unknown',
        model.amount.toString(),
        (model.note ?? '').replaceAll(',', ';'), // Escape commas
      ].join(',');
      
      csvLines.add(line);
    }

    // Create file in temporary directory first
    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/transactions_$timestamp.csv');
    
    await file.writeAsString(csvLines.join('\n'));
    return file;
  }

  /// Import data from JSON
  Future<ImportResult> importFromJson(File file) async {
    try {
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      int transactionsImported = 0;
      int categoriesImported = 0;
      int walletsImported = 0;
      int budgetsImported = 0;

      // Import categories first
      if (data['categories'] != null) {
        for (final catData in data['categories'] as List) {
          final cat = CategoryModel(
            id: catData['id'],
            name: catData['name'],
            iconCodePoint: catData['iconCodePoint'],
            type: catData['type'] == 'income' ? CategoryType.income : CategoryType.expense,
          );
          
          // Check if category already exists
          final existing = categoryRepo.getById(cat.id);
          if (existing == null || existing.id == 'other-expense') {
            await categoryRepo.add(cat);
            categoriesImported++;
          }
        }
      }

      // Import wallets
      if (data['wallets'] != null) {
        for (final walletData in data['wallets'] as List) {
          final wallet = WalletModel(
            id: walletData['id'],
            name: walletData['name'],
            balance: (walletData['balance'] as num).toDouble(),
          );
          
          await walletRepo.upsertById(wallet);
          walletsImported++;
        }
      }

      // Import budgets
      if (data['budgets'] != null) {
        for (final budgetData in data['budgets'] as List) {
          final budget = BudgetModel(
            id: budgetData['id'],
            categoryId: budgetData['categoryId'],
            year: budgetData['year'],
            month: budgetData['month'],
            limit: (budgetData['limit'] as num).toDouble(),
          );
          
          await budgetRepo.upsertById(budget);
          budgetsImported++;
        }
      }

      // Import transactions
      if (data['transactions'] != null) {
        for (final txData in data['transactions'] as List) {
          final tx = TransactionModel(
            id: txData['id'],
            amount: (txData['amount'] as num).toDouble(),
            type: txData['type'] == 'income' ? TransactionType.income : TransactionType.expense,
            categoryId: txData['categoryId'],
            walletId: txData['walletId'],
            note: txData['note'],
            date: DateTime.parse(txData['date']),
          );
          
          await transactionRepo.add(tx);
          transactionsImported++;
        }
      }

      return ImportResult(
        success: true,
        transactionsImported: transactionsImported,
        categoriesImported: categoriesImported,
        walletsImported: walletsImported,
        budgetsImported: budgetsImported,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

class ImportResult {
  final bool success;
  final int transactionsImported;
  final int categoriesImported;
  final int walletsImported;
  final int budgetsImported;
  final String? error;

  ImportResult({
    required this.success,
    this.transactionsImported = 0,
    this.categoriesImported = 0,
    this.walletsImported = 0,
    this.budgetsImported = 0,
    this.error,
  });

  String get message {
    if (!success) return 'Import failed: $error';
    return 'Successfully imported:\n'
        '- $transactionsImported transactions\n'
        '- $categoriesImported categories\n'
        '- $walletsImported wallets\n'
        '- $budgetsImported budgets';
  }
}
