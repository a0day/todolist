import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsRepository {
  Future<ThemeMode> loadThemeMode();

  Future<void> saveThemeMode(ThemeMode mode);
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  static const String _themeModeKey = 'theme_mode';

  @override
  Future<ThemeMode> loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return switch (preferences.getString(_themeModeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await preferences.setString(_themeModeKey, value);
  }
}
