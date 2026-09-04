import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/theme_storage.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadPersisted();
    return ThemeMode.system;
  }

  Future<void> _loadPersisted() async {
    final stored = await ref.read(themeStorageProvider).read();
    if (stored != null) state = stored;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(themeStorageProvider).save(mode);
  }
}
