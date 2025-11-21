import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/hive_service.dart';

class SettingsRepository {
  static const String kFirstDayOfMonth = 'first_day_of_month';

  final Box _box = HiveService.settings;

  ValueListenable<Box> listenable() => _box.listenable();

  int getFirstDayOfMonth() {
    return _box.get(kFirstDayOfMonth, defaultValue: 1) as int;
  }

  Future<void> setFirstDayOfMonth(int day) async {
    final d = day.clamp(1, 28);
    await _box.put(kFirstDayOfMonth, d);
  }
}
