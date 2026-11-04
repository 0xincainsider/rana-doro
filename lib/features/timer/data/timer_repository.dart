import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/timer_state.dart';

abstract interface class TimerRepository {
  Future<TimerState?> load();

  Future<void> save(TimerState state);
}

class SharedPreferencesTimerRepository implements TimerRepository {
  static const String storageKey = 'timer_state_v1';

  @override
  Future<TimerState?> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(storageKey);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return TimerState.fromJson(decoded.cast<String, Object?>());
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(TimerState state) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(storageKey, jsonEncode(state.toJson()));
    } on Object {
      return;
    }
  }
}
