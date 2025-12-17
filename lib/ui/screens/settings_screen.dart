import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/settings_repository.dart';
import '../../state/app_state.dart';
import '../widgets/app_bottom_bar.dart';
import 'categories_screen.dart';
import 'wallets_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsRepo = SettingsRepository();
  late int _firstDayOfMonth;
  bool _isExporting = false;
  bool _isImporting = false;

  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = context.read<AppState>();
    _firstDayOfMonth = _settingsRepo.getFirstDayOfMonth();
  }

  Future<void> _exportJson() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur Coming Soon'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportCsv() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur Coming Soon'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _importJson() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur Coming Soon'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      bottomNavigationBar: const AppBottomBar(
        current: AppSection.settings,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('General'),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('First Day of Month'),
            subtitle: Text('Day $_firstDayOfMonth'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFirstDayPicker(),
          ),
          const Divider(),
          _buildSectionHeader('Manage'),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            subtitle: const Text('Manage income and expense categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CategoriesScreen(),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Wallets'),
            subtitle: const Text('Manage your wallets and accounts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const WalletsScreen(),
              ));
            },
          ),
          const Divider(),
          _buildSectionHeader('Data Management'),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export All Data (JSON)'),
            subtitle:
                const Text('Backup all transactions, categories, and wallets'),
            trailing: _isExporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isExporting ? null : _exportJson,
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Transactions (CSV)'),
            subtitle:
                const Text('Export transactions for spreadsheet analysis'),
            trailing: _isExporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isExporting ? null : _exportCsv,
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import Data (JSON)'),
            subtitle: const Text('Restore from backup file'),
            trailing: _isImporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isImporting ? null : _importJson,
          ),
          const Divider(),
          _buildSectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Future<void> _showFirstDayPicker() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('First Day of Month'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 28,
            itemBuilder: (context, index) {
              final day = index + 1;
              return RadioListTile<int>(
                title: Text('Day $day'),
                value: day,
                groupValue: _firstDayOfMonth,
                onChanged: (value) => Navigator.pop(context, value),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null && selected != _firstDayOfMonth) {
      await _settingsRepo.setFirstDayOfMonth(selected);
      setState(() => _firstDayOfMonth = selected);
      _state.load(); // Refresh calculations

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('First day of month set to day $selected'),
          ),
        );
      }
    }
  }
}
