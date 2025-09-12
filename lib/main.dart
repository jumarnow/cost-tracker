import 'package:flutter/material.dart';

import 'data/transaction_repository.dart';
import 'services/hive_service.dart';
import 'data/category_repository.dart';
import 'data/wallet_repository.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final TransactionRepository _repo;
  late final CategoryRepository _categoryRepo;
  late final WalletRepository _walletRepo;
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _repo = TransactionRepository();
    _categoryRepo = CategoryRepository();
    _walletRepo = WalletRepository();
    _state = AppState(_repo, _walletRepo)..bind();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(state: _state, repo: _repo, categoryRepo: _categoryRepo, walletRepo: _walletRepo),
    );
  }
}
