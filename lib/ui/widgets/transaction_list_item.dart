import 'package:flutter/material.dart';

import '../../data/transaction_repository.dart';
import '../../data/category_repository.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../utils/currency.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionEntry entry;
  final CategoryRepository categoryRepo;
  final VoidCallback? onTap;

  const TransactionListItem({super.key, required this.entry, required this.categoryRepo, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = entry.model;
    final CategoryModel? cat = categoryRepo.getById(t.categoryId);
    final color = t.type == TransactionType.income
        ? Colors.green
        : Theme.of(context).colorScheme.error;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        child: Icon((cat?.icon) ?? Icons.category, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        t.note?.isNotEmpty == true ? t.note! : (cat?.name ?? 'Category'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_formatDate(t.date)),
      trailing: Text(
        (t.type == TransactionType.income ? '+ ' : '- ') + formatRupiah(t.amount),
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
