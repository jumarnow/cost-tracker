import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/transaction_repository.dart';
import 'data/category_repository.dart';
import 'data/wallet_repository.dart';
import 'data/budget_repository.dart';
import 'data/settings_repository.dart';
import 'services/hive_service.dart';
import 'services/export_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  // Initialize repositories
  final transactionRepository = TransactionRepository();
  final categoryRepository = CategoryRepository();
  final walletRepository = WalletRepository();
  final budgetRepository = BudgetRepository();
  final settingsRepository = SettingsRepository();

  // Initialize services
  final exportService = ExportService(
    transactionRepo: transactionRepository,
    categoryRepo: categoryRepository,
    walletRepo: walletRepository,
    budgetRepo: budgetRepository,
  );

  // Initialize AppState
  final appState = AppState(transactionRepository, walletRepository)..bind();

  runApp(
    MultiProvider(
      providers: [
        // Repositories
        Provider<TransactionRepository>.value(value: transactionRepository),
        Provider<CategoryRepository>.value(value: categoryRepository),
        Provider<WalletRepository>.value(value: walletRepository),
        Provider<BudgetRepository>.value(value: budgetRepository),
        Provider<SettingsRepository>.value(value: settingsRepository),
        
        // Services
        Provider<ExportService>.value(value: exportService),
        
        // App State
        ChangeNotifierProvider<AppState>.value(value: appState),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
