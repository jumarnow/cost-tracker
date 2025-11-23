import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/transaction_repository.dart';
import '../../data/category_repository.dart';
import '../../data/wallet_repository.dart';
import '../../state/app_state.dart';
import '../../utils/date_period.dart';
import '../widgets/transaction_list_item.dart';
import 'edit_transaction_screen.dart';

class CategoryTransactionsScreen extends StatelessWidget {
  final String categoryId;
  final MonthPeriod period;

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryId,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final txRepo = context.read<TransactionRepository>();
    final categoryRepo = context.read<CategoryRepository>();

    final category = categoryRepo.getById(categoryId);
    final title = category?.name ?? 'Category';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ValueListenableBuilder(
        valueListenable: txRepo.listenable(),
        builder: (context, _, __) {
          final filtered = txRepo.getAll().where((entry) {
            final t = entry.model;
            if (t.categoryId != categoryId) return false;
            if (t.date.isBefore(period.start) || !t.date.isBefore(period.end)) return false;
            return true;
          }).toList();
          if (filtered.isEmpty) {
            return const Center(child: Text('No transactions found for this category.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = filtered[index];
              return TransactionListItem(
                entry: entry,
                categoryRepo: categoryRepo,
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EditTransactionScreen(
                      keyId: entry.key,
                      initial: entry.model,
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
