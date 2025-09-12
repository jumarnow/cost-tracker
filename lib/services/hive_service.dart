import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io' show Directory;

import '../data/transaction_adapter.dart';
import '../data/category_adapter.dart';
import '../data/wallet_adapter.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

class HiveService {
  static const String transactionsBox = 'transactions_box_v1';
  static const String categoriesBox = 'categories_box_v1';
  static const String walletsBox = 'wallets_box_v1';

  static Future<void> init() async {
    // Use default platform-specific location (works for mobile, desktop, web).
    // If plugins aren't registered yet (e.g., after hot reload adding deps or in unit tests),
    // fall back to a temporary directory to avoid MissingPluginException.
    try {
      await Hive.initFlutter();
    } on MissingPluginException {
      final tmp = Directory.systemTemp.createTempSync('finance_tracker_hive_');
      Hive.init(tmp.path);
    }

    Hive
      ..registerAdapter(TransactionTypeAdapter())
      ..registerAdapter(TransactionModelAdapter())
      ..registerAdapter(CategoryModelAdapter())
      ..registerAdapter(WalletModelAdapter());

    await Hive.openBox<TransactionModel>(transactionsBox);
    await Hive.openBox<CategoryModel>(categoriesBox);
    await Hive.openBox<WalletModel>(walletsBox);

    // Seed default categories if empty
    final cBox = Hive.box<CategoryModel>(categoriesBox);
    if (cBox.isEmpty) {
      for (final c in defaultCategories()) {
        await cBox.add(c);
      }
    }

    // Seed default wallet if empty
    final wBox = Hive.box<WalletModel>(walletsBox);
    if (wBox.isEmpty) {
      await wBox.add(const WalletModel(id: defaultWalletId, name: defaultWalletName, balance: 0));
    }
  }

  static Box<TransactionModel> get transactions =>
      Hive.box<TransactionModel>(transactionsBox);

  static Box<CategoryModel> get categories =>
      Hive.box<CategoryModel>(categoriesBox);

  static Box<WalletModel> get wallets =>
      Hive.box<WalletModel>(walletsBox);
}
