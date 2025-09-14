import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/transaction_model.dart';
import '../services/hive_service.dart';

class TransactionEntry {
  final int key; // Hive key
  final TransactionModel model;
  const TransactionEntry(this.key, this.model);
}

class TransactionRepository {
  final Box<TransactionModel> _box = HiveService.transactions;

  ValueListenable<Box<TransactionModel>> listenable() => _box.listenable();

  List<TransactionEntry> getAll() {
    return _box.keys
        .whereType<int>()
        .map((k) => TransactionEntry(k, _box.get(k)!))
        .toList()
      ..sort((a, b) => b.model.date.compareTo(a.model.date));
  }

  Future<int> add(TransactionModel model) async {
    return _box.add(model);
  }

  Future<void> update(int key, TransactionModel model) async {
    await _box.put(key, model);
  }

  Future<void> delete(int key) async {
    await _box.delete(key);
  }

  // Helpers
  static String newId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32);
    return '$millis-$rand';
  }

  double totalBalance() {
    double income = 0, expense = 0;
    for (final t in _box.values) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return income - expense;
  }

  double totalForDay(DateTime day) {
    final d0 = DateTime(day.year, day.month, day.day);
    final d1 = d0.add(const Duration(days: 1));
    double income = 0, expense = 0;
    for (final t in _box.values) {
      if (t.date.isAfter(d0.subtract(const Duration(milliseconds: 1))) &&
          t.date.isBefore(d1)) {
        if (t.type == TransactionType.income) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
    }
    return income - expense;
  }

  double totalForMonth(DateTime day) {
    final m0 = DateTime(day.year, day.month);
    final m1 = DateTime(day.year, day.month + 1);
    double income = 0, expense = 0;
    for (final t in _box.values) {
      if (t.date.isAfter(m0.subtract(const Duration(milliseconds: 1))) &&
          t.date.isBefore(m1)) {
        if (t.type == TransactionType.income) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
    }
    return income - expense;
  }

  double totalForRange(DateTime start, DateTime end) {
    double income = 0, expense = 0;
    for (final t in _box.values) {
      if (t.date.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          t.date.isBefore(end)) {
        if (t.type == TransactionType.income) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
    }
    return income - expense;
  }
}
