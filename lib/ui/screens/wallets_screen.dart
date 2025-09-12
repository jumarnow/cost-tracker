import 'package:flutter/material.dart';

import '../../data/wallet_repository.dart';
import '../../models/wallet_model.dart';
import '../../utils/currency.dart';
import 'package:flutter/services.dart';

class WalletsScreen extends StatefulWidget {
  final WalletRepository repo;
  const WalletsScreen({super.key, required this.repo});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Wallets')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _openEditor(context),
      ),
      body: ValueListenableBuilder(
        valueListenable: widget.repo.listenable(),
        builder: (context, box, _) {
          final items = widget.repo.all();
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final w = items[index];
              return ListTile(
                title: Text(w.name),
                subtitle: Text('Balance: ' + formatRupiah(w.balance)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openEditor(context, existing: w, index: index),
                    ),
                    if (w.id != defaultWalletId)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete wallet?'),
                              content: const Text('Make sure no important transactions reference this wallet.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await widget.repo.deleteAt(index);
                          }
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {WalletModel? existing, int? index}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final balanceCtrl = TextEditingController(text: (existing?.balance ?? 0).toStringAsFixed(2));
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'New Wallet' : 'Edit Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceCtrl,
              decoration: const InputDecoration(labelText: 'Balance', prefixText: 'Rp '),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                RupiahThousandsFormatter(),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final balance = parseRupiahToDouble(balanceCtrl.text.trim());
              if (name.isEmpty) return;
              if (existing == null) {
                await widget.repo.add(WalletModel(id: WalletRepository.newId(), name: name, balance: balance));
              } else {
                await widget.repo.putAt(index!, existing.copyWith(name: name, balance: balance));
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
