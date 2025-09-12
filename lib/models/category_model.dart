import 'package:flutter/material.dart';
import '../icons/category_icons.dart';

enum CategoryType { income, expense }

class CategoryModel {
  final String id;
  final String name;
  final int iconCodePoint; // Material Icons code point
  final CategoryType type;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.type,
  });

  IconData get icon => categoryIconFromCodePoint(iconCodePoint);

  CategoryModel copyWith({String? id, String? name, int? iconCodePoint, CategoryType? type}) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      type: type ?? this.type,
    );
  }
}

// Default categories (mix of expense and income)
List<CategoryModel> defaultCategories() => const [
      // Expense
      CategoryModel(id: 'food', name: 'Food', iconCodePoint: 0xe56c, type: CategoryType.expense), // Icons.restaurant
      CategoryModel(id: 'transport', name: 'Transport', iconCodePoint: 0xe531, type: CategoryType.expense), // Icons.directions_bus
      CategoryModel(id: 'bills', name: 'Bills', iconCodePoint: 0xef5b, type: CategoryType.expense), // Icons.receipt_long
      CategoryModel(id: 'shopping', name: 'Shopping', iconCodePoint: 0xe59c, type: CategoryType.expense), // Icons.shopping_bag
      CategoryModel(id: 'entertainment', name: 'Entertainment', iconCodePoint: 0xe02c, type: CategoryType.expense), // Icons.movie
      CategoryModel(id: 'health', name: 'Health', iconCodePoint: 0xe0d0, type: CategoryType.expense), // Icons.health_and_safety
      CategoryModel(id: 'other-expense', name: 'Other (Expense)', iconCodePoint: 0xe574, type: CategoryType.expense), // Icons.category
      // Income
      CategoryModel(id: 'salary', name: 'Salary', iconCodePoint: 0xe227, type: CategoryType.income), // Icons.attach_money
      CategoryModel(id: 'bonus', name: 'Bonus', iconCodePoint: 0xe227, type: CategoryType.income), // Icons.attach_money
      CategoryModel(id: 'interest', name: 'Interest', iconCodePoint: 0xe04b, type: CategoryType.income), // Icons.audio_file
      CategoryModel(id: 'other-income', name: 'Other (Income)', iconCodePoint: 0xe574, type: CategoryType.income), // Icons.category
    ];
