import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'application/event_controller.dart';
import 'data/settings_repository.dart';
import 'ui/home/home_page.dart';
import 'ui/theme/app_theme.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({
    super.key,
    required this.eventController,
    required this.settingsRepository,
    required this.initialThemeMode,
  });

  final EventController eventController;
  final SettingsRepository settingsRepository;
  final ThemeMode initialThemeMode;

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late ThemeMode _themeMode = widget.initialThemeMode;

  @override
  void initState() {
    super.initState();
    if (!widget.eventController.hasLoaded) {
      unawaited(widget.eventController.load());
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    try {
      await widget.settingsRepository.saveThemeMode(mode);
    } catch (_) {
      // The visual choice still applies for this session if persistence fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '四象限待办',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: HomePage(
        controller: widget.eventController,
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
