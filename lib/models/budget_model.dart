class BudgetModel {
  final String id; // unique per category+year+month
  final String categoryId;
  final int year;
  final int month; // 1-12
  final double limit;

  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.limit,
  });

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    int? year,
    int? month,
    double? limit,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      year: year ?? this.year,
      month: month ?? this.month,
      limit: limit ?? this.limit,
    );
  }
}

