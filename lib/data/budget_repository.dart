import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/budget_model.dart';
import '../services/hive_service.dart';

class BudgetRepository {
  final Box<BudgetModel> _box = HiveService.budgets;

  ValueListenable<Box<BudgetModel>> listenable() => _box.listenable();

  List<BudgetModel> all() => _box.values.toList();

  List<BudgetModel> forMonth(int year, int month) {
    return _box.values
        .where((b) => b.year == year && b.month == month)
        .toList();
  }

  BudgetModel? getByCategory(int year, int month, String categoryId) {
    for (final b in _box.values) {
      if (b.year == year && b.month == month && b.categoryId == categoryId) {
        return b;
      }
    }
    return null;
  }

  Future<int> add(BudgetModel b) => _box.add(b);

  Future<void> putAt(int index, BudgetModel b) async {
    final key = _box.keyAt(index) as int;
    await _box.put(key, b);
  }

  Future<void> deleteAt(int index) async {
    final key = _box.keyAt(index) as int;
    await _box.delete(key);
  }

  Future<void> upsertById(BudgetModel b) async {
    final idx = _box.values.toList().indexWhere((e) => e.id == b.id);
    if (idx >= 0) {
      await putAt(idx, b);
    } else {
      await add(b);
    }
  }

  static String idFor(String categoryId, int year, int month) {
    final mm = month.toString().padLeft(2, '0');
    return 'budget-$categoryId-$year$mm';
  }
}
