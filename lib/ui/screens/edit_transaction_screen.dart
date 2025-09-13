import 'package:flutter/material.dart';

import '../../data/category_repository.dart';
import '../../data/transaction_repository.dart';
import '../../data/wallet_repository.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../models/wallet_model.dart';
import '../../state/app_state.dart';
import 'categories_screen.dart';
import '../../utils/currency.dart';
import 'package:flutter/services.dart';

class EditTransactionScreen extends StatefulWidget {
  final AppState state;
  final CategoryRepository categoryRepo;
  final WalletRepository walletRepo;
  final int? keyId; // if null, create new
  final TransactionModel? initial;

  const EditTransactionScreen({
    super.key,
    required this.state,
    required this.categoryRepo,
    required this.walletRepo,
    this.keyId,
    this.initial,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _type;
  late String _categoryId;
  late String _walletId;
  late DateTime _date;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _type = t?.type ?? TransactionType.expense;
    _categoryId = t?.categoryId ?? _defaultCategoryForType(_type);
    _walletId = t?.walletId ?? defaultWalletId;
    _date = t?.date ?? DateTime.now();
    // Pre-fill amount without decimals and with thousands separators
    _amountController.text = t != null ? formatRupiah(t.amount, includeSymbol: false) : '';
    _noteController.text = t?.note ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    setState(() {
      _date = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseRupiahToDouble(_amountController.text.trim());
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final model = TransactionModel(
      id: widget.initial?.id ?? TransactionRepository.newId(),
      amount: amount,
      type: _type,
      categoryId: _categoryId,
      walletId: _walletId,
      date: _date,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    if (widget.keyId == null) {
      await widget.state.addTransaction(model);
    } else {
      await widget.state.updateTransaction(widget.keyId!, model, widget.initial!);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.keyId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          IconButton(
            tooltip: 'Manage Categories',
            icon: const Icon(Icons.category),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CategoriesScreen(repo: widget.categoryRepo, state: widget.state, walletRepo: widget.walletRepo),
              ));
              setState(() {}); // refresh dropdown after returning
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.remove)),
                ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.add)),
              ],
              selected: {_type},
              onSelectionChanged: (s) {
                setState(() {
                  _type = s.first;
                  // Reset category if mismatched
                  final cat = widget.categoryRepo.getById(_categoryId);
                  if (cat == null || !_matchesType(cat.type, _type)) {
                    _categoryId = _defaultCategoryForType(_type);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                RupiahThousandsFormatter(),
              ],
              decoration: const InputDecoration(labelText: 'Amount', prefixText: 'Rp '),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Amount is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoryId,
              items: widget.categoryRepo
                  .all()
                  .where((c) => _matchesType(c.type, _type))
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (c) => setState(() => _categoryId = c ?? _defaultCategoryForType(_type)),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _walletId,
              items: widget.walletRepo
                  .all()
                  .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                  .toList(),
              onChanged: (w) => setState(() => _walletId = w ?? defaultWalletId),
              decoration: const InputDecoration(labelText: 'Wallet'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date & Time'),
              subtitle: Text('${_date.year}-${_two(_date.month)}-${_two(_date.day)} ${_two(_date.hour)}:${_two(_date.minute)}'),
              trailing: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDate),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save')),
          ],
        ),
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

bool _matchesType(CategoryType catType, TransactionType txType) {
  return (catType == CategoryType.income && txType == TransactionType.income) ||
      (catType == CategoryType.expense && txType == TransactionType.expense);
}

String _defaultCategoryForType(TransactionType t) {
  return t == TransactionType.income ? 'other-income' : 'other-expense';
}
