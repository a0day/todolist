import 'package:flutter/material.dart';

import 'app.dart';
import 'application/event_controller.dart';
import 'core/beijing_time.dart';
import 'data/app_database.dart';
import 'data/settings_repository.dart';
import 'data/sqlite_event_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BeijingTime.initialize();

  final database = AppDatabase();
  final eventController = EventController(
    repository: SqliteEventRepository(database),
  );
  final settingsRepository = SharedPreferencesSettingsRepository();

  var themeMode = ThemeMode.system;
  try {
    themeMode = await settingsRepository.loadThemeMode();
  } catch (_) {
    // Fall back to the system theme if preferences cannot be read.
  }

  runApp(
    TodoApp(
      eventController: eventController,
      settingsRepository: settingsRepository,
      initialThemeMode: themeMode,
    ),
  );
}
