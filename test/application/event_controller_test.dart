import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/application/event_controller.dart';
import 'package:todolist/domain/event.dart';
import 'package:todolist/domain/quadrant.dart';

import '../support/event_factory.dart';
import '../support/fake_event_repository.dart';

void main() {
  late FakeEventRepository repository;
  late DateTime now;
  late int idCounter;

  EventController buildController([Iterable<Event> events = const []]) {
    repository = FakeEventRepository(events);
    now = DateTime.utc(2026, 10, 21, 6);
    idCounter = 0;
    return EventController(
      repository: repository,
      clock: () => now,
      idGenerator: () => 'generated-${++idCounter}',
    );
  }

  test('loads events and exposes quadrants', () async {
    final controller = buildController([
      makeEvent(id: 'q1', important: true, urgent: true),
      makeEvent(id: 'q4', important: true, urgent: false),
    ]);

    expect(controller.hasLoaded, isFalse);
    await controller.load();

    expect(controller.hasLoaded, isTrue);
    expect(controller.isLoading, isFalse);
    expect(controller.loadError, isNull);
    expect(controller.unfinishedIn(Quadrant.q1).single.id, 'q1');
    expect(controller.pendingCountIn(Quadrant.q4), 1);
    expect(controller.completedIn(Quadrant.q1), isEmpty);
  });

  test('captures load errors without marking the data as loaded', () async {
    final controller = buildController();
    repository.loadError = const FormatException('损坏的数据库行');

    await controller.load();

    expect(controller.hasLoaded, isFalse);
    expect(controller.isLoading, isFalse);
    expect(controller.loadError, isA<FormatException>());
    expect(controller.allEvents, isEmpty);
  });

  test('creates tasks with injected clock and id', () async {
    final controller = buildController();
    await controller.load();

    final created = await controller.create(
      EventDraft(
        title: '  写方案  ',
        description: '  内容  ',
        important: true,
        urgent: false,
      ),
    );

    expect(created.id, 'generated-1');
    expect(created.title, '写方案');
    expect(created.description, '内容');
    expect(created.createdAt, now);
    expect(created.updatedAt, now);
    expect(created.completedAt, isNull);
    expect(created.quadrant, Quadrant.q4);
    expect(repository.events.single.id, created.id);
    expect(controller.eventById(created.id), same(created));
  });

  test('does not add an event when insertion fails', () async {
    final controller = buildController();
    await controller.load();
    repository.insertError = StateError('disk full');

    await expectLater(
      controller.create(
        EventDraft(title: '失败', important: false, urgent: false),
      ),
      throwsStateError,
    );
    expect(controller.allEvents, isEmpty);
  });

  test('toggles completion and records the completion time', () async {
    final event = makeEvent(id: 'task', important: true, urgent: true);
    final controller = buildController([event]);
    await controller.load();
    now = DateTime.utc(2026, 10, 22, 1);

    final completed = await controller.toggleCompleted(event);
    expect(completed.isCompleted, isTrue);
    expect(completed.completedAt, now);
    expect(completed.updatedAt, now);
    expect(controller.completedIn(Quadrant.q1).single.id, 'task');
    expect(controller.unfinishedIn(Quadrant.q1), isEmpty);
    expect(repository.events.single.isCompleted, isTrue);

    now = DateTime.utc(2026, 10, 23, 1);
    final reopened = await controller.setCompleted(completed, false);
    expect(reopened.isCompleted, isFalse);
    expect(reopened.completedAt, isNull);
    expect(controller.unfinishedIn(Quadrant.q1).single.id, 'task');
  });

  test('updates content, classification and schedule', () async {
    final event = makeEvent(
      id: 'task',
      important: false,
      urgent: false,
      completedAt: DateTime.utc(2026, 10, 20, 1),
    );
    final controller = buildController([event]);
    await controller.load();
    now = DateTime.utc(2026, 10, 24, 2);

    final updated = await controller.update(
      event,
      EventDraft(
        title: '改成日程',
        important: true,
        urgent: true,
        schedule: makeSchedule(
          startAt: DateTime.utc(2026, 10, 25, 1),
          endAt: DateTime.utc(2026, 10, 25, 3),
          location: '会议室',
        ),
      ),
    );

    expect(updated.id, event.id);
    expect(updated.createdAt, event.createdAt);
    expect(updated.completedAt, event.completedAt);
    expect(updated.updatedAt, now);
    expect(updated.type, EventType.schedule);
    expect(updated.quadrant, Quadrant.q1);
    expect(updated.schedule?.location, '会议室');
    expect(controller.unfinishedIn(Quadrant.q3), isEmpty);
  });

  test('deletes events', () async {
    final event = makeEvent(id: 'task');
    final controller = buildController([event]);
    await controller.load();

    await controller.delete(event);

    expect(controller.allEvents, isEmpty);
    expect(repository.events, isEmpty);
    expect(controller.eventById('task'), isNull);
  });

  test('notifies listeners after mutations', () async {
    final controller = buildController();
    var notifications = 0;
    controller.addListener(() => notifications++);
    await controller.load();
    final afterLoad = notifications;

    final created = await controller.create(
      EventDraft(title: '通知', important: true, urgent: true),
    );
    expect(notifications, greaterThan(afterLoad));
    await controller.delete(created);
    expect(notifications, greaterThan(afterLoad + 1));
  });
}
