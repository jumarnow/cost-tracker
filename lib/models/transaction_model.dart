/// Transaction type: income adds to balance, expense subtracts.
enum TransactionType { income, expense }

class TransactionModel {
  final String id; // uuid-like string for stability across edits
  final double amount; // positive amount
  final TransactionType type;
  final String categoryId; // references CategoryModel.id
  final String walletId; // references WalletModel.id
  final String? note;
  final DateTime date;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    required this.date,
    this.note,
  });

  TransactionModel copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? walletId,
    String? note,
    DateTime? date,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }
}
