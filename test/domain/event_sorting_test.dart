import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/domain/event_sorting.dart';

import '../support/event_factory.dart';

void main() {
  final base = DateTime.utc(2026, 10, 1, 0);

  group('unfinished sorting', () {
    test('uses schedule start, falling back to creation time', () {
      final taskLater = makeEvent(
        id: 'task-later',
        createdAt: base.add(const Duration(hours: 2)),
      );
      final scheduled = makeEvent(
        id: 'scheduled',
        createdAt: base,
        schedule: makeSchedule(
          startAt: base.add(const Duration(hours: 3)),
          endAt: base.add(const Duration(hours: 4)),
        ),
      );
      final taskFirst = makeEvent(
        id: 'task-first',
        createdAt: base.add(const Duration(hours: 1)),
      );

      final sorted = sortedUnfinished([taskLater, scheduled, taskFirst]);
      expect(sorted.map((event) => event.id), [
        'task-first',
        'task-later',
        'scheduled',
      ]);
    });

    test('breaks ties by creation time, then id', () {
      final sameInstant = base.add(const Duration(hours: 1));
      final first = makeEvent(
        id: 'b',
        createdAt: base,
        schedule: makeSchedule(
          startAt: sameInstant,
          endAt: sameInstant.add(const Duration(hours: 1)),
        ),
      );
      final second = makeEvent(
        id: 'a',
        createdAt: base,
        schedule: makeSchedule(
          startAt: sameInstant,
          endAt: sameInstant.add(const Duration(hours: 1)),
        ),
      );
      final earlier = makeEvent(
        id: 'c',
        createdAt: base.subtract(const Duration(minutes: 1)),
        schedule: makeSchedule(
          startAt: sameInstant,
          endAt: sameInstant.add(const Duration(hours: 1)),
        ),
      );

      final sorted = sortedUnfinished([first, second, earlier]);
      expect(sorted.map((event) => event.id), ['c', 'a', 'b']);
    });
  });

  group('completed sorting', () {
    test('orders by completion time descending', () {
      final early = makeEvent(
        id: 'early',
        completedAt: base.add(const Duration(hours: 1)),
      );
      final late = makeEvent(
        id: 'late',
        completedAt: base.add(const Duration(hours: 3)),
      );
      final middle = makeEvent(
        id: 'middle',
        completedAt: base.add(const Duration(hours: 2)),
      );

      final sorted = sortedCompleted([early, late, middle]);
      expect(sorted.map((event) => event.id), ['late', 'middle', 'early']);
    });

    test('breaks ties by creation time, then id', () {
      final completedAt = base.add(const Duration(hours: 5));
      final first = makeEvent(
        id: 'z',
        createdAt: base,
        completedAt: completedAt,
      );
      final second = makeEvent(
        id: 'y',
        createdAt: base,
        completedAt: completedAt,
      );
      final older = makeEvent(
        id: 'x',
        createdAt: base.subtract(const Duration(days: 1)),
        completedAt: completedAt,
      );

      final sorted = sortedCompleted([first, second, older]);
      expect(sorted.map((event) => event.id), ['x', 'y', 'z']);
    });

    test('filters out unfinished events', () {
      final completed = makeEvent(
        id: 'done',
        completedAt: base.add(const Duration(hours: 1)),
      );
      final sorted = sortedCompleted([makeEvent(), completed]);
      expect(sorted.map((event) => event.id), ['done']);
    });

    test('compareCompleted rejects unfinished events', () {
      expect(
        () => compareCompleted(makeEvent(), makeEvent(completedAt: base)),
        throwsArgumentError,
      );
    });
  });

  test('display order puts every unfinished event before completed ones', () {
    final unfinished = makeEvent(
      id: 'todo',
      createdAt: base.add(const Duration(days: 2)),
    );
    final completed = makeEvent(
      id: 'done',
      completedAt: base.add(const Duration(days: 3)),
    );

    final sorted = sortedForDisplay([completed, unfinished]);
    expect(sorted.map((event) => event.id), ['todo', 'done']);
  });

  test('sortInstant falls back to creation time for tasks', () {
    final task = makeEvent(createdAt: base);
    expect(sortInstant(task), base);
  });
}
