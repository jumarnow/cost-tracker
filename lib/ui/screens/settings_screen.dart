import 'package:flutter/material.dart';

import '../../data/transaction_repository.dart';
import '../../data/category_repository.dart';
import '../../data/wallet_repository.dart';
import '../../data/budget_repository.dart';
import '../../data/settings_repository.dart';
import '../../services/export_service.dart';
import '../../state/app_state.dart';
import '../widgets/app_bottom_bar.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;
  final TransactionRepository txRepo;
  final CategoryRepository categoryRepo;
  final WalletRepository walletRepo;
  final BudgetRepository budgetRepo;

  const SettingsScreen({
    super.key,
    required this.state,
    required this.txRepo,
    required this.categoryRepo,
    required this.walletRepo,
    required this.budgetRepo,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsRepo = SettingsRepository();
  late int _firstDayOfMonth;
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _firstDayOfMonth = _settingsRepo.getFirstDayOfMonth();
  }

  Future<void> _exportJson() async {
    setState(() => _isExporting = true);
    
    try {
      final exportService = ExportService(
        transactionRepo: widget.txRepo,
        categoryRepo: widget.categoryRepo,
        walletRepo: widget.walletRepo,
        budgetRepo: widget.budgetRepo,
      );
      
      final file = await exportService.exportToJson();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to:\n${file.path}'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    
    try {
      final exportService = ExportService(
        transactionRepo: widget.txRepo,
        categoryRepo: widget.categoryRepo,
        walletRepo: widget.walletRepo,
        budgetRepo: widget.budgetRepo,
      );
      
      final file = await exportService.exportTransactionsToCsv();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transactions exported to:\n${file.path}'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importJson() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'Import feature coming soon!\n\n'
          'You can export your data to JSON format, '
          'and in a future update you will be able to import it back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      bottomNavigationBar: AppBottomBar(
        current: AppSection.settings,
        walletRepo: widget.walletRepo,
        categoryRepo: widget.categoryRepo,
        txRepo: widget.txRepo,
        state: widget.state,
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
          _buildSectionHeader('Data Management'),
          
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export All Data (JSON)'),
            subtitle: const Text('Backup all transactions, categories, and wallets'),
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
            subtitle: const Text('Export transactions for spreadsheet analysis'),
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
      widget.state.load(); // Refresh calculations
      
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
