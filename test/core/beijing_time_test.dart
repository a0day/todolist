import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/core/beijing_time.dart';

void main() {
  setUpAll(BeijingTime.initialize);

  test('interprets wall-clock time as Asia/Shanghai', () {
    final utc = BeijingTime.wallClockToUtc(
      year: 2026,
      month: 10,
      day: 21,
      hour: 14,
      minute: 30,
    );
    expect(utc, DateTime.utc(2026, 10, 21, 6, 30));
    expect(utc.isUtc, isTrue);
    expect(BeijingTime.formatDateTime(utc), '2026-10-21 14:30');
    expect(BeijingTime.formatTime(utc), '14:30');
  });

  test('renders and reads back the same wall clock', () {
    final wall = DateTime(2026, 1, 2, 3, 4);
    final utc = BeijingTime.wallClockToUtc(
      year: wall.year,
      month: wall.month,
      day: wall.day,
      hour: wall.hour,
      minute: wall.minute,
    );
    final roundTrip = BeijingTime.wallClockFromInstant(utc);
    expect(roundTrip, wall);
  });

  test('detects and formats cross-day ranges', () {
    final start = BeijingTime.wallClockToUtc(
      year: 2026,
      month: 10,
      day: 21,
      hour: 23,
      minute: 0,
    );
    final end = BeijingTime.wallClockToUtc(
      year: 2026,
      month: 10,
      day: 22,
      hour: 1,
      minute: 0,
    );

    expect(BeijingTime.isCrossDay(start, end), isTrue);
    expect(BeijingTime.isSameDay(start, end), isFalse);
    expect(BeijingTime.formatCardRange(start, end), '10-21 23:00–10-22 01:00');
    expect(
      BeijingTime.formatFullRange(start, end),
      '2026-10-21 23:00 – 2026-10-22 01:00',
    );
  });

  test('formats same-day ranges with one date', () {
    final start = BeijingTime.wallClockToUtc(
      year: 2026,
      month: 10,
      day: 21,
      hour: 9,
      minute: 5,
    );
    final end = BeijingTime.wallClockToUtc(
      year: 2026,
      month: 10,
      day: 21,
      hour: 10,
      minute: 0,
    );
    expect(BeijingTime.formatCardRange(start, end), '10-21 09:05–10:00');
  });

  test('default schedule start is the next half-hour boundary', () {
    final before = DateTime.now().toUtc();
    final start = BeijingTime.defaultStartUtc();
    final after = DateTime.now().toUtc();
    final local = BeijingTime.fromInstant(start);

    expect(start.isAfter(before.subtract(const Duration(minutes: 1))), isTrue);
    expect(start.isBefore(after.add(const Duration(minutes: 31))), isTrue);
    expect(local.minute, anyOf(0, 30));
    expect(local.second, 0);
  });

  test('chinese formatters use 24-hour time', () {
    final instant = DateTime.utc(2026, 10, 21, 15, 45);
    expect(BeijingTime.formatChineseDateTime(instant), '2026年10月21日 23:45');
    expect(BeijingTime.formatChineseDate(instant), '2026年10月21日');
  });
}
