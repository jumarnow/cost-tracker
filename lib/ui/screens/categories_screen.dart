import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../icons/category_icons.dart';

import '../../data/category_repository.dart';
import '../../data/wallet_repository.dart';
import '../../data/transaction_repository.dart';
import '../widgets/app_bottom_bar.dart';
import '../../state/app_state.dart';
import 'edit_transaction_screen.dart';
import '../../models/category_model.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final CategoryRepository _repo;
  late final AppState _state;
  late final WalletRepository _walletRepo;

  @override
  void initState() {
    super.initState();
    _repo = context.read<CategoryRepository>();
    _state = context.read<AppState>();
    _walletRepo = context.read<WalletRepository>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            tooltip: 'New Category',
            icon: const Icon(Icons.add),
            onPressed: () async {
              await _openEditor(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-add-tx',
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const EditTransactionScreen(),
          ));
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: ValueListenableBuilder(
        valueListenable: _repo.listenable(),
        builder: (context, box, _) {
          final items = _repo.all();
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final c = items[index];
              return ListTile(
                leading: CircleAvatar(child: Icon(c.icon)),
                title: Text(c.name),
                subtitle: Text(c.type == CategoryType.income ? 'Income' : 'Expense'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await _openEditor(context, existing: c, index: index);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete category?'),
                            content: const Text('Transactions will still reference this id; ensure to reassign if needed.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          final key = box.keyAt(index);
                          await _repo.deleteAt(key as int);
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
      bottomNavigationBar: const AppBottomBar(
        current: AppSection.settings,
        withNotch: true,
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {CategoryModel? existing, int? index}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    int selectedIcon = existing?.iconCodePoint ?? allowedCategoryIcons.first.codePoint;
    CategoryType selectedType = existing?.type ?? CategoryType.expense;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(existing == null ? 'New Category' : 'Edit Category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Icon'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final icon in allowedCategoryIcons)
                        ChoiceChip(
                          label: Icon(
                            icon,
                            color: selectedIcon == icon.codePoint
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : null,
                          ),
                          selected: selectedIcon == icon.codePoint,
                          selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          showCheckmark: false,
                          onSelected: (_) => setStateDialog(() => selectedIcon = icon.codePoint),
                        )
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Type'),
                  const SizedBox(height: 8),
                  SegmentedButton<CategoryType>(
                    segments: const [
                      ButtonSegment(value: CategoryType.expense, label: Text('Expense'), icon: Icon(Icons.remove)),
                      ButtonSegment(value: CategoryType.income, label: Text('Income'), icon: Icon(Icons.add)),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (s) => setStateDialog(() => selectedType = s.first),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  if (existing == null) {
                    final c = CategoryModel(id: CategoryRepository.newId(), name: name, iconCodePoint: selectedIcon, type: selectedType);
                    await _repo.add(c);
                  } else {
                    final updated = existing.copyWith(name: name, iconCodePoint: selectedIcon, type: selectedType);
                    final key = _repo.listenable().value.keyAt(index!);
                    await _repo.putAt(key as int, updated);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// A small set of icon choices for simplicity
// Icon options are defined in ../icons/category_icons.dart
