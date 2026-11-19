import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/application/event_controller.dart';
import 'package:todolist/domain/event.dart';
import 'package:todolist/domain/quadrant.dart';
import 'package:todolist/ui/event/event_editor_page.dart';

import '../support/event_factory.dart';
import '../support/fake_event_repository.dart';
import '../support/pump_test_app.dart';

class _EditorLauncher extends StatelessWidget {
  const _EditorLauncher({required this.controller, this.event, this.quadrant});

  final EventController controller;
  final Event? event;
  final Quadrant? quadrant;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: FilledButton(
            key: const ValueKey('launch-editor'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => EventEditorPage(
                  controller: controller,
                  event: event,
                  initialQuadrant: quadrant,
                ),
              ),
            ),
            child: const Text('打开编辑器'),
          ),
        ),
      ),
    );
  }
}

Future<EventController> _pumpEditor(
  WidgetTester tester, {
  FakeEventRepository? repository,
  Event? event,
  Quadrant? quadrant,
}) async {
  final controller = EventController(
    repository: repository ?? FakeEventRepository(),
    clock: () => DateTime.utc(2026, 10, 10, 12),
    idGenerator: () => 'generated-1',
  );
  await controller.load();
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await pumpTestApp(
    tester,
    _EditorLauncher(controller: controller, event: event, quadrant: quadrant),
  );
  await tester.tap(find.byKey(const ValueKey('launch-editor')));
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('creates a schedule with one-hour default duration', (
    tester,
  ) async {
    final repository = FakeEventRepository();
    final controller = await _pumpEditor(
      tester,
      repository: repository,
      quadrant: Quadrant.q4,
    );

    expect(find.text('新建事件'), findsOneWidget);
    expect(find.text('当前归类：计划做'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('title-field')), '年度体检');
    await tester.tap(find.text('日程'));
    await tester.pumpAndSettle();

    expect(find.text('日程时间'), findsOneWidget);
    expect(find.text('北京时间（UTC+8），24 小时制，可跨天。'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('save-event')));
    await tester.pumpAndSettle();

    expect(controller.allEvents, hasLength(1));
    final event = controller.allEvents.single;
    expect(event.title, '年度体检');
    expect(event.type, EventType.schedule);
    expect(event.quadrant, Quadrant.q4);
    expect(event.schedule, isNotNull);
    expect(
      event.schedule!.endAt.difference(event.schedule!.startAt),
      const Duration(hours: 1),
    );
    expect(repository.events.single.id, event.id);
  });

  testWidgets('requires a title before saving', (tester) async {
    final controller = await _pumpEditor(tester, quadrant: Quadrant.q1);

    await tester.tap(find.byKey(const ValueKey('save-event')));
    await tester.pumpAndSettle();

    expect(find.text('请输入事件标题'), findsOneWidget);
    expect(controller.allEvents, isEmpty);
  });

  testWidgets('converts a schedule to a task without losing its data', (
    tester,
  ) async {
    final schedule = makeSchedule(
      startAt: DateTime.utc(2026, 10, 21, 6, 30),
      endAt: DateTime.utc(2026, 10, 21, 7, 30),
      location: '会议室 A',
    );
    final event = makeEvent(
      id: 'scheduled',
      title: '周会',
      important: true,
      urgent: true,
      schedule: schedule,
    );
    final repository = FakeEventRepository([event]);
    final controller = await _pumpEditor(
      tester,
      repository: repository,
      event: event,
    );

    await tester.tap(find.text('任务'));
    await tester.pumpAndSettle();

    expect(find.text('转为任务？'), findsOneWidget);
    expect(find.textContaining('会议室 A'), findsWidgets);

    await tester.tap(find.text('转为任务'));
    await tester.pumpAndSettle();

    final descriptionField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('description-field')),
    );
    expect(descriptionField.controller?.text, contains('原日程：'));
    expect(descriptionField.controller?.text, contains('会议室 A'));

    await tester.tap(find.byKey(const ValueKey('save-event')));
    await tester.pumpAndSettle();

    final updated = controller.eventById('scheduled')!;
    expect(updated.type, EventType.task);
    expect(updated.schedule, isNull);
    expect(updated.description, contains('原日程：'));
    expect(updated.description, contains('地点：会议室 A'));
    expect(repository.events.single.schedule, isNull);
  });

  testWidgets('cancelling the conversion keeps the schedule', (tester) async {
    final schedule = makeSchedule(location: '线上');
    final event = makeEvent(
      id: 'scheduled',
      title: '周会',
      important: true,
      urgent: true,
      schedule: schedule,
    );
    final controller = await _pumpEditor(
      tester,
      repository: FakeEventRepository([event]),
      event: event,
    );

    await tester.tap(find.text('任务'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('日程时间'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-event')));
    await tester.pumpAndSettle();

    final saved = controller.eventById('scheduled')!;
    expect(saved.type, EventType.schedule);
    expect(saved.schedule?.location, '线上');
  });

  testWidgets('switching a task to schedule and back adds no noise', (
    tester,
  ) async {
    final event = makeEvent(id: 'task', title: '买咖啡');
    final controller = await _pumpEditor(
      tester,
      repository: FakeEventRepository([event]),
      event: event,
    );

    await tester.tap(find.text('日程'));
    await tester.pumpAndSettle();
    expect(find.text('日程时间'), findsOneWidget);

    await tester.tap(find.text('任务'));
    await tester.pumpAndSettle();

    expect(find.text('转为任务？'), findsNothing);
    final descriptionField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('description-field')),
    );
    expect(descriptionField.controller?.text, isEmpty);

    await tester.tap(find.byKey(const ValueKey('save-event')));
    await tester.pumpAndSettle();

    final saved = controller.eventById('task')!;
    expect(saved.type, EventType.task);
    expect(saved.description, isEmpty);
  });

  testWidgets('updates the quadrant preview from the switches', (tester) async {
    await _pumpEditor(tester, quadrant: Quadrant.q3);

    expect(find.text('当前归类：暂缓做'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('important-switch')));
    await tester.pumpAndSettle();
    expect(find.text('当前归类：计划做'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('urgent-switch')));
    await tester.pumpAndSettle();
    expect(find.text('当前归类：立即做'), findsOneWidget);
  });
}
