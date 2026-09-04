import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferencesAsync>((ref) {
  return SharedPreferencesAsync();
});

final themeStorageProvider = Provider<ThemeStorage>((ref) {
  return ThemeStorage(ref.watch(sharedPreferencesProvider));
});

/// Wraps shared preferences for the persisted theme mode choice.
class ThemeStorage {
  ThemeStorage(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _themeModeKey = 'godelivery.themeMode';

  Future<ThemeMode?> read() async {
    final value = await _prefs.getString(_themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => null,
    };
  }

  Future<void> save(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.name);
  }
}
