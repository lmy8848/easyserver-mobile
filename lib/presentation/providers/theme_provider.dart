import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../di/providers.dart';

/// 应用主题模式（跟随系统/浅色/深色），持久化到 SharedPreferences。
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'app_theme_mode';

  ThemeModeNotifier(this._ref) : super(ThemeMode.system) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final storage = _ref.read(settingsStorageProvider);
    await storage.init();
    final v = storage.getString(_key);
    if (!mounted) return;
    state = switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final storage = _ref.read(settingsStorageProvider);
    await storage.init();
    await storage.setString(
        _key,
        switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          _ => 'system'
        });
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref),
);
