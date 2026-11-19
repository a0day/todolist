import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/app.dart';
import 'package:todolist/application/event_controller.dart';
import 'package:todolist/domain/event.dart';

import '../support/event_factory.dart';
import '../support/fake_event_repository.dart';
import '../support/fake_settings_repository.dart';

Future<EventController> pumpAppWith(
  WidgetTester tester,
  List<Event> events,
) async {
  final repository = FakeEventRepository(events);
  final controller = EventController(
    repository: repository,
    clock: () => DateTime.utc(2026, 10, 10, 12),
    idGenerator: () => 'generated-1',
  );
  await tester.pumpWidget(
    TodoApp(
      eventController: controller,
      settingsRepository: FakeSettingsRepository(),
      initialThemeMode: ThemeMode.light,
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('detail shows schedule data and toggles completion', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final event = makeEvent(
      id: 'schedule',
      title: '项目评审',
      description: '带上原型',
      important: true,
      urgent: false,
      schedule: makeSchedule(
        startAt: DateTime.utc(2026, 10, 1, 1),
        endAt: DateTime.utc(2026, 10, 1, 2),
        location: '三号会议室',
      ),
    );
    final controller = await pumpAppWith(tester, [event]);

    await tester.tap(find.byKey(const ValueKey('event-open-schedule')));
    await tester.pumpAndSettle();

    expect(find.text('项目评审'), findsOneWidget);
    expect(find.text('计划做'), findsOneWidget);
    expect(find.text('三号会议室'), findsOneWidget);
    expect(find.text('2026-10-01 09:00 – 2026-10-01 10:00'), findsOneWidget);
    expect(find.text('带上原型'), findsOneWidget);
    expect(find.text('未完成'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggle-completion')));
    await tester.pumpAndSettle();

    expect(find.text('已完成'), findsOneWidget);
    expect(find.text('标记为未完成'), findsOneWidget);
    expect(controller.eventById('schedule')?.isCompleted, isTrue);

    await tester.tap(find.byKey(const ValueKey('toggle-completion')));
    await tester.pumpAndSettle();

    expect(find.text('未完成'), findsOneWidget);
    expect(find.text('标记为完成'), findsOneWidget);
    expect(controller.eventById('schedule')?.isCompleted, isFalse);
  });

  testWidgets('detail cancel keeps an event, confirm deletes it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final event = makeEvent(id: 'task', title: '保留的事件');
    final controller = await pumpAppWith(tester, [event]);

    await tester.tap(find.byKey(const ValueKey('event-open-task')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('delete-event')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('事件详情'), findsOneWidget);
    expect(controller.eventById('task'), isNotNull);

    await tester.tap(find.byKey(const ValueKey('delete-event')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-delete')));
    await tester.pumpAndSettle();

    expect(find.text('事件详情'), findsNothing);
    expect(controller.eventById('task'), isNull);
  });

  testWidgets('per-quadrant list shows every completed event without folding', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final base = DateTime.utc(2026, 10, 1);
    final events = [
      makeEvent(
        id: 'q2-open',
        title: '回复客户',
        important: false,
        urgent: true,
        createdAt: base,
      ),
      makeEvent(
        id: 'q2-done-1',
        title: '完成一',
        important: false,
        urgent: true,
        completedAt: base.add(const Duration(hours: 1)),
      ),
      makeEvent(
        id: 'q2-done-2',
        title: '完成二',
        important: false,
        urgent: true,
        completedAt: base.add(const Duration(hours: 2)),
      ),
      makeEvent(
        id: 'q2-done-3',
        title: '完成三',
        important: false,
        urgent: true,
        completedAt: base.add(const Duration(hours: 3)),
      ),
    ];
    await pumpAppWith(tester, events);

    await tester.tap(find.byKey(const ValueKey('quadrant-all-q2')));
    await tester.pumpAndSettle();

    expect(find.text('尽快做 · 全部'), findsOneWidget);
    expect(find.text('未完成 1'), findsOneWidget);
    expect(find.text('已完成 3'), findsOneWidget);
    expect(find.text('回复客户'), findsOneWidget);
    expect(find.text('完成一'), findsOneWidget);
    expect(find.text('完成二'), findsOneWidget);
    expect(find.text('完成三'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('event-checkbox-q2-done-1')));
    await tester.pumpAndSettle();

    expect(find.text('未完成 2'), findsOneWidget);
    expect(find.text('已完成 2'), findsOneWidget);
  });
}
