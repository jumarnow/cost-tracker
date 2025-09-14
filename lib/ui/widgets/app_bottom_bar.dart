import 'package:flutter/material.dart';

import '../../data/budget_repository.dart';
import '../../data/category_repository.dart';
import '../../data/transaction_repository.dart';
import '../../data/wallet_repository.dart';
import '../../state/app_state.dart';
import '../screens/budgets_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/wallets_screen.dart';
import '../../data/settings_repository.dart';

enum AppSection { home, budgets, reports, settings }

class AppBottomBar extends StatelessWidget {
  final AppSection current;
  final WalletRepository walletRepo;
  final CategoryRepository categoryRepo;
  final TransactionRepository txRepo;
  final bool withNotch;
  final AppState state;

  const AppBottomBar({
    super.key,
    required this.current,
    required this.walletRepo,
    required this.categoryRepo,
    required this.txRepo,
    required this.state,
    this.withNotch = false,
  });

  @override
  Widget build(BuildContext context) {
    final bar = BottomAppBar(
      shape: withNotch ? const CircularNotchedRectangle() : null,
      notchMargin: withNotch ? 8 : 0,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _BarAction(
                  icon: Icons.home_filled,
                  label: 'Home',
                  active: current == AppSection.home,
                  onTap: current == AppSection.home
                      ? null
                      : () => Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              ),
              Expanded(
                child: _BarAction(
                  icon: Icons.pie_chart,
                  label: 'Budgets',
                  active: current == AppSection.budgets,
                  onTap: current == AppSection.budgets
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BudgetsScreen(
                                budgetRepo: BudgetRepository(),
                                categoryRepo: categoryRepo,
                                txRepo: txRepo,
                                state: state,
                                walletRepo: walletRepo,
                              ),
                            ),
                          ),
                ),
              ),
              if (withNotch) const SizedBox(width: 80),
              Expanded(
                child: _BarAction(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports',
                  active: current == AppSection.reports,
                  onTap: current == AppSection.reports
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportsScreen(state: state, txRepo: txRepo, categoryRepo: categoryRepo, walletRepo: walletRepo),
                            ),
                          ),
                ),
              ),
              Expanded(
                child: _BarAction(
                  icon: Icons.settings,
                  label: 'Settings',
                  active: current == AppSection.settings,
                  onTap: () async {
                    await showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      builder: (ctx) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.account_balance_wallet),
                                title: const Text('Wallets'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  if (current != AppSection.settings) {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => WalletsScreen(repo: walletRepo, state: state, categoryRepo: categoryRepo),
                                    ));
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.category),
                                title: const Text('Categories'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  if (current != AppSection.settings) {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => CategoriesScreen(repo: categoryRepo, state: state, walletRepo: walletRepo),
                                    ));
                                  }
                                },
                              ),
                              const Divider(height: 0),
                              _FirstDayOfMonthTile(),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return bar;
  }
}

class _BarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _BarAction({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = active ? cs.primary : cs.onSurfaceVariant;
    final weight = active ? FontWeight.w700 : FontWeight.w500;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: weight),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FirstDayOfMonthTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = SettingsRepository();
    final current = repo.getFirstDayOfMonth();
    return ListTile(
      leading: const Icon(Icons.calendar_today),
      title: const Text('First day of month'),
      subtitle: Text('Currently: $current'),
      onTap: () async {
        Navigator.of(context).pop();
        int selected = current;
        await showDialog(
          context: context,
          builder: (_) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('First day of month'),
                content: DropdownButtonFormField<int>(
                  value: selected,
                  items: [
                    for (int d = 1; d <= 28; d++)
                      DropdownMenuItem(value: d, child: Text(d.toString())),
                  ],
                  onChanged: (v) => setStateDialog(() => selected = v ?? selected),
                  decoration: const InputDecoration(helperText: 'Used for reports and budgets period'),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  FilledButton(
                    onPressed: () async {
                      await repo.setFirstDayOfMonth(selected);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
