import 'package:flutter/material.dart';

import '../../data/budget_repository.dart';
import '../../data/category_repository.dart';
import '../../data/transaction_repository.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency.dart';

class BudgetsScreen extends StatefulWidget {
  final BudgetRepository budgetRepo;
  final CategoryRepository categoryRepo;
  final TransactionRepository txRepo;

  const BudgetsScreen({super.key, required this.budgetRepo, required this.categoryRepo, required this.txRepo});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late final DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final year = _now.year;
    final month = _now.month;
    return Scaffold(
      appBar: AppBar(title: const Text('Category Budgets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
        child: const Icon(Icons.add_chart),
      ),
      body: ValueListenableBuilder(
        valueListenable: widget.budgetRepo.listenable(),
        builder: (context, box, _) {
          final all = box.values.toList();
          final items = all.where((b) => b.year == year && b.month == month).toList();
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No budgets set for this month. Tap + to add.'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final b = items[index];
              final category = widget.categoryRepo.getById(b.categoryId);
              final spent = _spentForCategoryThisMonth(b.categoryId);
              final progress = b.limit <= 0 ? 0.0 : (spent / b.limit).clamp(0.0, 1.0);
              final over = spent > b.limit;
              final boxIndex = all.indexOf(b);
              return ListTile(
                leading: CircleAvatar(child: Icon(category?.icon ?? Icons.category)),
                title: Text(category?.name ?? 'Unknown'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${formatRupiah(spent)} of ${formatRupiah(b.limit)}'),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          over ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openEditor(context, existing: b, boxIndex: boxIndex),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete budget?'),
                            content: const Text('This will remove the limit for this category this month.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await widget.budgetRepo.deleteAt(boxIndex);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  double _spentForCategoryThisMonth(String categoryId) {
    final monthStart = DateTime(_now.year, _now.month);
    final nextMonth = DateTime(_now.year, _now.month + 1);
    double total = 0;
    for (final e in widget.txRepo.getAll()) {
      final t = e.model;
      if (t.categoryId == categoryId &&
          t.type == TransactionType.expense &&
          t.date.isAfter(monthStart.subtract(const Duration(milliseconds: 1))) &&
          t.date.isBefore(nextMonth)) {
        total += t.amount;
      }
    }
    return total;
  }

  Future<void> _openEditor(BuildContext context, {BudgetModel? existing, int? boxIndex}) async {
    final isEditing = existing != null;
    final expenseCategories = widget
        .categoryRepo
        .all()
        .where((c) => c.type == CategoryType.expense)
        .toList();

    // Exclude already-budgeted categories when creating
    final now = DateTime.now();
    final budgetsThisMonth = widget.budgetRepo.forMonth(now.year, now.month);
    final usedIds = budgetsThisMonth.map((b) => b.categoryId).toSet();
    final availableCategories = isEditing
        ? expenseCategories
        : expenseCategories.where((c) => !usedIds.contains(c.id)).toList();

    CategoryModel? selectedCategory = isEditing
        ? widget.categoryRepo.getById(existing!.categoryId)
        : (availableCategories.isNotEmpty ? availableCategories.first : null);

    final limitCtrl = TextEditingController(
      text: isEditing ? formatRupiah(existing!.limit, includeSymbol: false) : '',
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Edit Budget' : 'New Budget'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<CategoryModel>(
                value: selectedCategory,
                items: [
                  for (final c in availableCategories)
                    DropdownMenuItem(value: c, child: Row(children: [Icon(c.icon), const SizedBox(width: 8), Text(c.name)])),
                ],
                onChanged: isEditing ? null : (v) => setState(() => selectedCategory = v),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitCtrl,
                decoration: const InputDecoration(labelText: 'Monthly limit (Rp)'),
                keyboardType: TextInputType.number,
                inputFormatters: [RupiahThousandsFormatter()],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (selectedCategory == null) return;
              final limit = parseRupiahToDouble(limitCtrl.text);
              if (limit <= 0) return;
              final id = BudgetRepository.idFor(selectedCategory!.id, now.year, now.month);
              final model = BudgetModel(
                id: id,
                categoryId: selectedCategory!.id,
                year: now.year,
                month: now.month,
                limit: limit,
              );
              if (isEditing) {
                await widget.budgetRepo.putAt(boxIndex!, model);
              } else {
                await widget.budgetRepo.upsertById(model);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
