import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/category_model.dart';
import '../services/hive_service.dart';

class CategoryRepository {
  final Box<CategoryModel> _box = HiveService.categories;

  ValueListenable<Box<CategoryModel>> listenable() => _box.listenable();

  List<CategoryModel> all() => _box.values.toList();

  CategoryModel? getById(String id) => _box.values.firstWhere(
        (c) => c.id == id,
        orElse: () => const CategoryModel(id: 'other-expense', name: 'Other (Expense)', iconCodePoint: 0xe574, type: CategoryType.expense),
      );

  Future<int> add(CategoryModel c) => _box.add(c);
  Future<void> putAt(int key, CategoryModel c) => _box.put(key, c);
  Future<void> deleteAt(int key) => _box.delete(key);

  static String newId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32);
    return 'cat-$millis-$rand';
  }
}
