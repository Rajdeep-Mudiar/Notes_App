import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/storage/storage_service.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeModeNotifier(this._storage) : super(_loadInitialTheme(_storage));

  static ThemeMode _loadInitialTheme(StorageService storage) {
    final saved = storage.getThemeMode();
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    String modeString = 'system';
    if (mode == ThemeMode.light) modeString = 'light';
    if (mode == ThemeMode.dark) modeString = 'dark';
    await _storage.saveThemeMode(modeString);
  }

  Future<void> toggleTheme(BuildContext context) async {
    final currentBrightness = Theme.of(context).brightness;
    if (state == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      // If currently system, flip opposite to platform brightness
      if (currentBrightness == Brightness.dark) {
        await setThemeMode(ThemeMode.light);
      } else {
        await setThemeMode(ThemeMode.dark);
      }
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storage);
});
