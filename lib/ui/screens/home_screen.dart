import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/transaction_repository.dart';
import '../../data/category_repository.dart';
import '../../data/wallet_repository.dart';
import '../../state/app_state.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency.dart';
import '../widgets/transaction_list_item.dart';
import 'edit_transaction_screen.dart';
import 'search_screen.dart';
import '../widgets/app_bottom_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeScreenContent();
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final repo = context.read<TransactionRepository>();
    final categoryRepo = context.read<CategoryRepository>();
    final walletRepo = context.read<WalletRepository>();

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Finance Tracker'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search transactions',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SearchScreen(),
                ));
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab-add',
          tooltip: 'Add transaction',
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const EditTransactionScreen(),
            ));
          },
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: const AppBottomBar(
          current: AppSection.home,
          withNotch: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async => state.load(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(state: state),
              const SizedBox(height: 16),
              Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (state.entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text('No transactions yet. Tap + to add.')),
                )
              else
                ..._buildGroupedEntries(context, state, categoryRepo, walletRepo),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedEntries(BuildContext context, AppState state, CategoryRepository categoryRepo, WalletRepository walletRepo) {
    final groups = <DateTime, List<TransactionEntry>>{};
    for (final e in state.entries) {
      final d = DateTime(e.model.date.year, e.model.date.month, e.model.date.day);
      groups.putIfAbsent(d, () => []).add(e);
    }
    final sortedDates = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final widgets = <Widget>[];
    for (final date in sortedDates) {
      final dayEntries = groups[date]!;
      double net = 0;
      for (final entry in dayEntries) {
        final model = entry.model;
        net += model.type == TransactionType.income ? model.amount : -model.amount;
      }
      final totalLabel = net == 0
          ? formatRupiah(0)
          : net > 0
              ? '+${formatRupiah(net)}'
              : '-${formatRupiah(net.abs())}';
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(_formatSectionDate(date), style: Theme.of(context).textTheme.titleSmall)),
            const SizedBox(width: 12),
            Text(
              totalLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: net >= 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ));
      widgets.addAll(dayEntries.map((e) => Dismissible(
            key: ValueKey(e.key),
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
            ),
            confirmDismiss: (direction) async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete transaction?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              return ok ?? false;
            },
            onDismissed: (_) => state.deleteTransaction(e),
            child: TransactionListItem(
              entry: e,
              categoryRepo: categoryRepo,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => EditTransactionScreen(
                    keyId: e.key,
                    initial: e.model,
                  ),
                ));
              },
            ),
          )));
    }
    return widgets;
  }

  String _formatSectionDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dd = DateTime(d.year, d.month, d.day);
    if (dd == today) return 'Today';
    if (dd == yesterday) return 'Yesterday';
    return '${_weekday(dd.weekday)}, ${_two(dd.day)} ${_month(dd.month)} ${dd.year}';
  }

  String _weekday(int w) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(w - 1) % names.length];
    }

  String _month(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[(m - 1) % names.length];
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

class _SummaryCard extends StatelessWidget {
  final AppState state;
  const _SummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Calculate income and expense
    double income = 0;
    double expense = 0;
    for (final entry in state.entries) {
      if (entry.model.type == TransactionType.income) {
        income += entry.model.amount;
      } else {
        expense += entry.model.amount;
      }
    }
    final balance = income - expense;
    
    return Card(
      elevation: 0,
      color: cs.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.account_balance_wallet, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ringkasan Keuangan', 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: balance >= 0 
                    ? [Colors.green.shade50, Colors.green.shade100]
                    : [Colors.red.shade50, Colors.red.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: balance >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(balance),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: balance >= 0 ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: balance >= 0 ? Colors.green[700] : Colors.red[700],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      balance >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.south_west, color: Colors.green[700], size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pendapatan',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formatRupiah(income),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.north_east, color: Colors.red[700], size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pengeluaran',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formatRupiah(expense),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
