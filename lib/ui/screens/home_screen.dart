import 'package:flutter/material.dart';

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
  final AppState state;
  final TransactionRepository repo;
  final CategoryRepository categoryRepo;
  final WalletRepository walletRepo;

  const HomeScreen({super.key, required this.state, required this.repo, required this.categoryRepo, required this.walletRepo});

  @override
  Widget build(BuildContext context) {
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
                  builder: (_) => SearchScreen(
                    state: state,
                    txRepo: repo,
                    categoryRepo: categoryRepo,
                    walletRepo: walletRepo,
                  ),
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
              builder: (_) => EditTransactionScreen(state: state, categoryRepo: categoryRepo, walletRepo: walletRepo),
            ));
          },
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AppBottomBar(
          current: AppSection.home,
          walletRepo: walletRepo,
          categoryRepo: categoryRepo,
          txRepo: repo,
          state: state,
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
                ..._buildGroupedEntries(context, state),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedEntries(BuildContext context, AppState state) {
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
                    state: state,
                    categoryRepo: categoryRepo,
                    walletRepo: walletRepo,
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              formatRupiah(state.balance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Kpi(
                    label: 'Today',
                    value: formatRupiah(state.today),
                    color: cs.primaryContainer,
                    onColor: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Kpi(
                    label: 'This Month',
                    value: formatRupiah(state.month),
                    color: cs.secondaryContainer,
                    onColor: cs.onSecondaryContainer,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color onColor;

  const _Kpi({required this.label, required this.value, required this.color, required this.onColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: onColor)),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: onColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
