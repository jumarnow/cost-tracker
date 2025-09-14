import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/hive_service.dart';

class SettingsRepository {
  static const String kFirstDayOfMonth = 'first_day_of_month';

  final Box _box = HiveService.settings;

  ValueListenable<Box> listenable() => _box.listenable();

  int getFirstDayOfMonth() {
    final val = _box.get(kFirstDayOfMonth);
    if (val is int && val >= 1 && val <= 28) return val;
    return 1; // default
  }

  Future<void> setFirstDayOfMonth(int day) async {
    final d = day.clamp(1, 28);
    await _box.put(kFirstDayOfMonth, d);
  }
}
