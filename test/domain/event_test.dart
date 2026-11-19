import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/domain/event.dart';
import 'package:todolist/domain/event_conversion.dart';
import 'package:todolist/domain/event_validation.dart';
import 'package:todolist/domain/quadrant.dart';

import '../support/event_factory.dart';

void main() {
  group('ScheduleDetails', () {
    test('normalizes to UTC and trims location', () {
      final start = DateTime.utc(2026, 10, 21, 6, 30);
      final end = DateTime.utc(2026, 10, 21, 7, 30);
      final schedule = ScheduleDetails(
        startAt: start,
        endAt: end,
        location: '  会议室 A  ',
      );
      expect(schedule.startAt, start);
      expect(schedule.endAt, end);
      expect(schedule.startAt.isUtc, isTrue);
      expect(schedule.location, '会议室 A');
    });

    test('rejects an end before the start', () {
      expect(
        () => ScheduleDetails(
          startAt: DateTime.utc(2026, 10, 21, 8),
          endAt: DateTime.utc(2026, 10, 21, 7),
        ),
        throwsArgumentError,
      );
    });

    test('allows an end equal to the start', () {
      final instant = DateTime.utc(2026, 10, 21, 8);
      final schedule = ScheduleDetails(startAt: instant, endAt: instant);
      expect(schedule.endAt, schedule.startAt);
    });
  });

  group('Event', () {
    test('derives type and quadrant', () {
      final task = makeEvent(important: true, urgent: false);
      expect(task.type, EventType.task);
      expect(task.quadrant, Quadrant.q4);

      final schedule = makeEvent(
        important: false,
        urgent: true,
        schedule: makeSchedule(),
      );
      expect(schedule.type, EventType.schedule);
      expect(schedule.quadrant, Quadrant.q2);
    });

    test('trims text and normalizes timestamps', () {
      final event = makeEvent(
        title: '  写周报  ',
        description: '  内容  ',
        createdAt: DateTime(2026, 10, 21, 8),
      );
      expect(event.title, '写周报');
      expect(event.description, '内容');
      expect(event.createdAt.isUtc, isTrue);
    });

    test('rejects empty id or title', () {
      expect(() => makeEvent(id: '  '), throwsArgumentError);
      expect(() => makeEvent(title: '  '), throwsArgumentError);
    });

    test('withCompletion marks and clears completion', () {
      final event = makeEvent();
      final completed = event.withCompletion(
        completed: true,
        updatedAt: DateTime.utc(2026, 10, 2, 1),
        completedAt: DateTime.utc(2026, 10, 2, 1),
      );
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, DateTime.utc(2026, 10, 2, 1));
      expect(completed.id, event.id);

      final reopened = completed.withCompletion(
        completed: false,
        updatedAt: DateTime.utc(2026, 10, 3, 1),
        completedAt: DateTime.utc(2026, 10, 3, 1),
      );
      expect(reopened.isCompleted, isFalse);
      expect(reopened.completedAt, isNull);
    });
  });

  group('preserveScheduleInDescription', () {
    final schedule = makeSchedule(
      startAt: DateTime.utc(2026, 10, 21, 6, 30),
      endAt: DateTime.utc(2026, 10, 21, 7, 30),
      location: '会议室 A',
    );

    test('records time and location when description is empty', () {
      final result = preserveScheduleInDescription('', schedule);
      expect(result, contains('原日程：2026-10-21 14:30 – 2026-10-21 15:30'));
      expect(result, contains('地点：会议室 A'));
    });

    test('keeps existing user content', () {
      final result = preserveScheduleInDescription('准备材料', schedule);
      expect(result, startsWith('准备材料\n\n原日程：'));
      expect(result, contains('地点：会议室 A'));
    });
  });

  group('validation', () {
    test('validates title and description lengths', () {
      expect(validateTitle(null), isNotNull);
      expect(validateTitle('   '), isNotNull);
      expect(validateTitle('a' * 201), isNotNull);
      expect(validateTitle('任务'), isNull);
      expect(validateDescription('a' * 5000), isNull);
      expect(validateDescription('a' * 5001), isNotNull);
      expect(validateLocation('a' * 201), isNotNull);
    });

    test('validates schedule range', () {
      final start = DateTime.utc(2026, 10, 21, 8);
      expect(validateScheduleRange(start, start), isNull);
      expect(
        validateScheduleRange(
          start,
          start.subtract(const Duration(minutes: 1)),
        ),
        isNotNull,
      );
    });
  });
}
