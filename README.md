# Finance Tracker (Flutter)

Lightweight personal finance tracker built with Flutter and Material 3.

Features:
- Add/Edit/Delete transactions (income and expenses)
- Categories (food, transport, bills, shopping, salary, entertainment, health, other)
- Total balance and daily/monthly summaries
- Offline-first local storage via Hive
- Clean, minimal UI and modular code structure

Run locally:
1) Ensure Flutter SDK is installed and on PATH.
2) Fetch deps: `flutter pub get`
3) Run on Android: `flutter run -d android`

Release builds (smallest size):
- Configure signing: copy `android/key.properties.example` to `android/key.properties` and fill your keystore values.
- Build via script: `bash tool/build_release.sh`
  - Produces an AAB and split-per-ABI APKs with shrinking, icon tree shaking, and obfuscation.
  - Outputs are under `build/app/outputs/`.

Project structure (key parts):
- `lib/models/transaction_model.dart` – data model and enums
- `lib/data/transaction_adapter.dart` – Hive type adapters (manual)
- `lib/services/hive_service.dart` – Hive initialization and box management
- `lib/data/transaction_repository.dart` – CRUD + summary helpers
- `lib/state/app_state.dart` – simple ChangeNotifier app state
- `lib/ui/screens/home_screen.dart` – dashboard and transaction list
- `lib/ui/screens/edit_transaction_screen.dart` – add/edit form
- `lib/ui/widgets/transaction_list_item.dart` – list row widget
- `lib/theme/app_theme.dart` – Material 3 theme

Extendability ideas:
- Budgets: add `BudgetModel`, repository, and a new screen to track category limits.
- Export CSV: iterate `TransactionRepository.getAll()` and write to file via `path_provider`.
- Filters/Charts: add date/category filters and basic charts using a lightweight chart lib.
# cost-tracker
