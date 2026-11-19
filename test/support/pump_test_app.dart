import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/ui/theme/app_theme.dart';

Future<void> pumpTestApp(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light(),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}
