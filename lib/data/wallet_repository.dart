import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/wallet_model.dart';
import '../services/hive_service.dart';

class WalletRepository {
  final Box<WalletModel> _box = HiveService.wallets;

  ValueListenable<Box<WalletModel>> listenable() => _box.listenable();

  List<WalletModel> all() => _box.values.toList();
  WalletModel? getById(String id) => _box.values.firstWhere(
        (w) => w.id == id,
        orElse: () => const WalletModel(id: defaultWalletId, name: defaultWalletName, balance: 0),
      );

  Future<int> add(WalletModel w) => _box.add(w);
  Future<void> putAt(int index, WalletModel w) => _box.put(_box.keyAt(index) as int, w);
  Future<void> deleteAt(int index) => _box.delete(_box.keyAt(index) as int);

  Future<void> upsertById(WalletModel w) async {
    final idx = _box.values.toList().indexWhere((e) => e.id == w.id);
    if (idx >= 0) {
      await putAt(idx, w);
    } else {
      await add(w);
    }
  }

  static String newId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32);
    return 'wallet-$millis-$rand';
  }
}
