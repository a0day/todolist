import 'package:flutter/material.dart';
import 'package:todolist/data/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  ThemeMode themeMode = ThemeMode.system;

  @override
  Future<ThemeMode> loadThemeMode() async => themeMode;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    themeMode = mode;
  }
}
