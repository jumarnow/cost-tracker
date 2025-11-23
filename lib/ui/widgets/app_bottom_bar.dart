import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/budget_repository.dart';
import '../../data/category_repository.dart';
import '../../data/transaction_repository.dart';
import '../../data/wallet_repository.dart';
import '../../state/app_state.dart';
import '../screens/budgets_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';

enum AppSection { home, budgets, reports, settings }

class AppBottomBar extends StatelessWidget {
  final AppSection current;
  final bool withNotch;

  const AppBottomBar({
    super.key,
    required this.current,
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
                              builder: (_) => const BudgetsScreen(),
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
                              builder: (_) => const ReportsScreen(),
                            ),
                          ),
                ),
              ),
              Expanded(
                child: _BarAction(
                  icon: Icons.settings,
                  label: 'Settings',
                  active: current == AppSection.settings,
                  onTap: current == AppSection.settings
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
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
