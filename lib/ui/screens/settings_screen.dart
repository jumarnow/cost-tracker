import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../data/transaction_repository.dart';
import '../../data/category_repository.dart';
import '../../data/wallet_repository.dart';
import '../../data/budget_repository.dart';
import '../../data/settings_repository.dart';
import '../../services/export_service.dart';
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
  late final TransactionRepository _txRepo;
  late final CategoryRepository _categoryRepo;
  late final WalletRepository _walletRepo;
  late final BudgetRepository _budgetRepo;
  late final ExportService _exportService;

  @override
  void initState() {
    super.initState();
    _state = context.read<AppState>();
    _txRepo = context.read<TransactionRepository>();
    _categoryRepo = context.read<CategoryRepository>();
    _walletRepo = context.read<WalletRepository>();
    _budgetRepo = context.read<BudgetRepository>();
    _exportService = context.read<ExportService>();
    _firstDayOfMonth = _settingsRepo.getFirstDayOfMonth();
  }

  Future<void> _exportJson() async {
    // Show dialog to choose export method
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Backup'),
        content: const Text('Pilih cara menyimpan file backup:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'share'),
            child: const Text('Bagikan'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Simpan ke File'),
          ),
        ],
      ),
    );

    if (choice == null || choice == 'cancel') return;

    setState(() => _isExporting = true);
    
    try {
      final file = await _exportService.exportToJson();
      
      if (!mounted) return;

      if (choice == 'share') {
        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Finance Tracker Backup',
          text: 'Backup data Finance Tracker',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File backup siap dibagikan'),
            ),
          );
        }
      } else {
        // Save to user-selected location
        final fileName = file.path.split('/').last;
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan Backup',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (savePath != null) {
          // Copy file to selected location
          final content = await file.readAsBytes();
          await File(savePath).writeAsBytes(content);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Backup disimpan ke:\n$savePath'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export gagal: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCsv() async {
    // Show dialog to choose export method
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Transaksi'),
        content: const Text('Pilih cara menyimpan file CSV:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'share'),
            child: const Text('Bagikan'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Simpan ke File'),
          ),
        ],
      ),
    );

    if (choice == null || choice == 'cancel') return;

    setState(() => _isExporting = true);
    
    try {
      final file = await _exportService.exportTransactionsToCsv();
      
      if (!mounted) return;

      if (choice == 'share') {
        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Finance Tracker Transactions',
          text: 'Export transaksi Finance Tracker',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File CSV siap dibagikan'),
            ),
          );
        }
      } else {
        // Save to user-selected location
        final fileName = file.path.split('/').last;
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan Transaksi CSV',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );

        if (savePath != null) {
          // Copy file to selected location
          final content = await file.readAsBytes();
          await File(savePath).writeAsBytes(content);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('CSV disimpan ke:\n$savePath'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export gagal: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'This will import all data from the selected file. '
          'Existing data will be preserved, but duplicates may occur. '
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isImporting = true);

    try {
      final file = File(result.files.first.path!);
      final importResult = await _exportService.importFromJson(file);

      if (mounted) {
        if (importResult.success) {
          _state.load(); // Refresh data
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(importResult.message),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(importResult.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
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
