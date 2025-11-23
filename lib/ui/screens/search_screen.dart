import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/transaction_repository.dart';
import '../../data/category_repository.dart';
import '../../data/wallet_repository.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../models/wallet_model.dart';
import '../../state/app_state.dart';
import '../widgets/transaction_list_item.dart';
import 'edit_transaction_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<TransactionEntry> _filteredEntries = [];
  
  // Filters
  TransactionType? _typeFilter;
  String? _categoryFilter;
  String? _walletFilter;
  DateTimeRange? _dateRange;

  late final TransactionRepository _txRepo;
  late final CategoryRepository _categoryRepo;
  late final WalletRepository _walletRepo;
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _txRepo = context.read<TransactionRepository>();
    _categoryRepo = context.read<CategoryRepository>();
    _walletRepo = context.read<WalletRepository>();
    _state = context.read<AppState>();
    _filteredEntries = _txRepo.getAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final allEntries = _txRepo.getAll();
    final searchQuery = _searchController.text.toLowerCase();

    setState(() {
      _filteredEntries = allEntries.where((entry) {
        final model = entry.model;
        
        // Text search in note
        if (searchQuery.isNotEmpty) {
          final note = (model.note ?? '').toLowerCase();
          final amount = model.amount.toString();
          if (!note.contains(searchQuery) && !amount.contains(searchQuery)) {
            return false;
          }
        }

        // Type filter
        if (_typeFilter != null && model.type != _typeFilter) {
          return false;
        }

        // Category filter
        if (_categoryFilter != null && model.categoryId != _categoryFilter) {
          return false;
        }

        // Wallet filter
        if (_walletFilter != null && model.walletId != _walletFilter) {
          return false;
        }

        // Date range filter
        if (_dateRange != null) {
          if (model.date.isBefore(_dateRange!.start) || 
              model.date.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _typeFilter = null;
      _categoryFilter = null;
      _walletFilter = null;
      _dateRange = null;
      _filteredEntries = _txRepo.getAll();
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      _applyFilters();
    }
  }

  int get _activeFilterCount {
    int count = 0;
    if (_typeFilter != null) count++;
    if (_categoryFilter != null) count++;
    if (_walletFilter != null) count++;
    if (_dateRange != null) count++;
    if (_searchController.text.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Transactions'),
        actions: [
          if (_activeFilterCount > 0)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear all filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by amount or note...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Type filter
                FilterChip(
                  label: Text(_typeFilter == null 
                    ? 'Type' 
                    : _typeFilter == TransactionType.income ? 'Income' : 'Expense'),
                  selected: _typeFilter != null,
                  onSelected: (selected) async {
                    if (!selected) {
                      setState(() => _typeFilter = null);
                      _applyFilters();
                      return;
                    }

                    final type = await showDialog<TransactionType>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Type'),
                        children: [
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, TransactionType.income),
                            child: const Text('Income'),
                          ),
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, TransactionType.expense),
                            child: const Text('Expense'),
                          ),
                        ],
                      ),
                    );

                    if (type != null) {
                      setState(() => _typeFilter = type);
                      _applyFilters();
                    }
                  },
                ),
                
                const SizedBox(width: 8),

                // Category filter
                FilterChip(
                  label: Text(_categoryFilter == null
                      ? 'Category'
                      : _categoryRepo.getById(_categoryFilter!)?.name ?? 'Category'),
                  selected: _categoryFilter != null,
                  onSelected: (selected) async {
                    if (!selected) {
                      setState(() => _categoryFilter = null);
                      _applyFilters();
                      return;
                    }

                    final categories = _categoryRepo.all();
                    final category = await showDialog<CategoryModel>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Category'),
                        children: categories
                            .map((c) => SimpleDialogOption(
                                  onPressed: () => Navigator.pop(context, c),
                                  child: Row(
                                    children: [
                                      Icon(c.icon, size: 20),
                                      const SizedBox(width: 12),
                                      Text(c.name),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    );

                    if (category != null) {
                      setState(() => _categoryFilter = category.id);
                      _applyFilters();
                    }
                  },
                ),

                const SizedBox(width: 8),

                // Wallet filter
                FilterChip(
                  label: Text(_walletFilter == null
                      ? 'Wallet'
                      : _walletRepo.getById(_walletFilter!)?.name ?? 'Wallet'),
                  selected: _walletFilter != null,
                  onSelected: (selected) async {
                    if (!selected) {
                      setState(() => _walletFilter = null);
                      _applyFilters();
                      return;
                    }

                    final wallets = _walletRepo.all();
                    final wallet = await showDialog<WalletModel>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Select Wallet'),
                        children: wallets
                            .map((w) => SimpleDialogOption(
                                  onPressed: () => Navigator.pop(context, w),
                                  child: Text(w.name),
                                ))
                            .toList(),
                      ),
                    );

                    if (wallet != null) {
                      setState(() => _walletFilter = wallet.id);
                      _applyFilters();
                    }
                  },
                ),

                const SizedBox(width: 8),

                // Date range filter
                FilterChip(
                  label: Text(_dateRange == null
                      ? 'Date Range'
                      : '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'),
                  selected: _dateRange != null,
                  onSelected: (selected) {
                    if (!selected) {
                      setState(() => _dateRange = null);
                      _applyFilters();
                    } else {
                      _selectDateRange();
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _filteredEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_activeFilterCount > 0) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredEntries.length + 1,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            '${_filteredEntries.length} transaction${_filteredEntries.length == 1 ? '' : 's'} found',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        );
                      }

                      final entry = _filteredEntries[index - 1];
                      return Dismissible(
                        key: ValueKey(entry.key),
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 16),
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Icon(Icons.delete,
                              color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Icon(Icons.delete,
                              color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                        confirmDismiss: (direction) async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete transaction?'),
                              content: const Text('This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          return ok ?? false;
                        },
                        onDismissed: (_) {
                          _state.deleteTransaction(entry);
                          _applyFilters();
                        },
                        child: TransactionListItem(
                          entry: entry,
                          categoryRepo: _categoryRepo,
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => EditTransactionScreen(
                                keyId: entry.key,
                                initial: entry.model,
                              ),
                            ));
                            _applyFilters();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
