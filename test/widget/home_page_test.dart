import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/app.dart';
import 'package:todolist/application/event_controller.dart';
import 'package:todolist/domain/event.dart';

import '../support/event_factory.dart';
import '../support/fake_event_repository.dart';
import '../support/fake_settings_repository.dart';

Future<EventController> pumpTodoApp(
  WidgetTester tester, {
  required FakeEventRepository repository,
  FakeSettingsRepository? settings,
}) async {
  final controller = EventController(
    repository: repository,
    clock: () => DateTime.utc(2026, 10, 10, 12),
    idGenerator: () => 'generated-1',
  );
  await tester.pumpWidget(
    TodoApp(
      eventController: controller,
      settingsRepository: settings ?? FakeSettingsRepository(),
      initialThemeMode: ThemeMode.light,
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> setPhoneSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  final base = DateTime.utc(2026, 10, 1);

  late FakeEventRepository repository;
  late List<Event> events;

  setUp(() {
    final scheduled = makeEvent(
      id: 'q1-scheduled',
      title: '提交报告',
      important: true,
      urgent: true,
      createdAt: base,
      schedule: makeSchedule(
        startAt: base.add(const Duration(hours: 10)),
        endAt: base.add(const Duration(hours: 11)),
        location: '办公室',
      ),
    );
    final task = makeEvent(
      id: 'q1-task',
      title: '回复邮件',
      important: true,
      urgent: true,
      createdAt: base.add(const Duration(hours: 2)),
    );
    final doneOld = makeEvent(
      id: 'q1-done-old',
      title: '已完成一',
      important: true,
      urgent: true,
      createdAt: base,
      completedAt: base.add(const Duration(hours: 3)),
    );
    final doneMiddle = makeEvent(
      id: 'q1-done-middle',
      title: '已完成二',
      important: true,
      urgent: true,
      createdAt: base,
      completedAt: base.add(const Duration(hours: 5)),
    );
    final doneLatest = makeEvent(
      id: 'q1-done-latest',
      title: '已完成三',
      important: true,
      urgent: true,
      createdAt: base,
      completedAt: base.add(const Duration(hours: 7)),
    );
    events = [scheduled, task, doneOld, doneMiddle, doneLatest];
    repository = FakeEventRepository(events);
  });

  testWidgets('renders one labeled axis and all quadrant actions', (
    tester,
  ) async {
    await setPhoneSize(tester);
    await pumpTodoApp(tester, repository: repository);

    expect(find.text('重要'), findsOneWidget);
    expect(find.text('紧急'), findsOneWidget);
    expect(find.byKey(const ValueKey('axis-important')), findsOneWidget);
    expect(find.byKey(const ValueKey('axis-urgent')), findsOneWidget);

    for (final quadrant in ['q1', 'q2', 'q3', 'q4']) {
      expect(find.byKey(ValueKey('quadrant-$quadrant')), findsOneWidget);
      expect(find.byKey(ValueKey('quadrant-all-$quadrant')), findsOneWidget);
      expect(find.byKey(ValueKey('quadrant-add-$quadrant')), findsOneWidget);
    }
    expect(find.text('添加'), findsNWidgets(4));
    expect(find.text('全部'), findsNWidgets(4));
  });

  testWidgets('shows unfinished events before completed ones', (tester) async {
    await setPhoneSize(tester);
    await pumpTodoApp(tester, repository: repository);

    final unfinishedPosition = tester
        .getTopLeft(find.byKey(const ValueKey('event-title-q1-task')))
        .dy;
    final completedPosition = tester
        .getTopLeft(find.byKey(const ValueKey('event-title-q1-done-latest')))
        .dy;

    expect(unfinishedPosition, lessThan(completedPosition));
    expect(find.text('回复邮件'), findsOneWidget);
  });

  testWidgets('folds older completed events and can expand them', (
    tester,
  ) async {
    await setPhoneSize(tester);
    await pumpTodoApp(tester, repository: repository);

    expect(find.text('已完成三'), findsOneWidget);
    expect(find.text('已完成二'), findsOneWidget);
    expect(find.text('已完成一'), findsNothing);
    expect(find.text('还有 1 项已完成 · 展开'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('quadrant-completed-toggle-q1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('已完成一'), findsOneWidget);
  });

  testWidgets('checkbox only toggles completion and never opens details', (
    tester,
  ) async {
    await setPhoneSize(tester);
    await pumpTodoApp(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('event-checkbox-q1-task')));
    await tester.pumpAndSettle();

    expect(find.text('事件详情'), findsNothing);
    final title = tester.widget<Text>(
      find.byKey(const ValueKey('event-title-q1-task')),
    );
    expect(title.style?.decoration, TextDecoration.lineThrough);
    expect(
      repository.events
          .firstWhere((event) => event.id == 'q1-task')
          .isCompleted,
      isTrue,
    );
  });

  testWidgets('tapping the content opens the detail page', (tester) async {
    await setPhoneSize(tester);
    await pumpTodoApp(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('event-open-q1-task')));
    await tester.pumpAndSettle();

    expect(find.text('事件详情'), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-title')), findsOneWidget);
    expect(find.text('回复邮件'), findsOneWidget);
  });

  testWidgets('adds an event into the chosen quadrant', (tester) async {
    await setPhoneSize(tester);
    final controller = await pumpTodoApp(
      tester,
      repository: FakeEventRepository(),
    );

    await tester.tap(find.byKey(const ValueKey('quadrant-add-q2')));
    await tester.pumpAndSettle();

    expect(find.text('新建事件'), findsOneWidget);
    expect(find.text('当前归类：尽快做'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('title-field')), '买牛奶');
    await tester.tap(find.byKey(const ValueKey('save-event')));
    await tester.pumpAndSettle();

    expect(find.text('新建事件'), findsNothing);
    expect(find.text('买牛奶'), findsOneWidget);
    expect(controller.allEvents, hasLength(1));
    expect(controller.allEvents.single.important, isFalse);
    expect(controller.allEvents.single.urgent, isTrue);
  });

  testWidgets('deletes an event after confirmation', (tester) async {
    await setPhoneSize(tester);
    final controller = await pumpTodoApp(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('event-open-q1-task')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-event')));
    await tester.pumpAndSettle();

    expect(find.text('删除事件？'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-delete')));
    await tester.pumpAndSettle();

    expect(find.text('事件详情'), findsNothing);
    expect(controller.eventById('q1-task'), isNull);
    expect(find.text('回复邮件'), findsNothing);
  });

  testWidgets('switches theme mode and persists the choice', (tester) async {
    await setPhoneSize(tester);
    final settings = FakeSettingsRepository();
    await pumpTodoApp(
      tester,
      repository: FakeEventRepository(),
      settings: settings,
    );

    await tester.tap(find.byKey(const ValueKey('theme-menu')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<ThemeMode>, '深色'),
    );
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.dark);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
  });

  testWidgets('stays usable on a small screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpTodoApp(tester, repository: repository);

    expect(tester.takeException(), isNull);
    expect(find.text('重要'), findsOneWidget);
    expect(find.text('紧急'), findsOneWidget);
    for (final quadrant in ['q1', 'q2', 'q3', 'q4']) {
      expect(find.byKey(ValueKey('quadrant-$quadrant')), findsOneWidget);
    }
  });

  testWidgets('survives large text scaling without layout errors', (
    tester,
  ) async {
    await setPhoneSize(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpTodoApp(tester, repository: repository);

    expect(tester.takeException(), isNull);
    expect(find.text('重要'), findsOneWidget);
    expect(find.text('紧急'), findsOneWidget);
  });
}
