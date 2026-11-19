import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// All persisted instants are UTC; every user-facing date/time is rendered in
/// Asia/Shanghai, independent of the device time zone.
abstract final class BeijingTime {
  static const String zoneName = 'Asia/Shanghai';

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) {
      return;
    }
    tz_data.initializeTimeZones();
    _initialized = true;
  }

  static tz.Location get location {
    initialize();
    return tz.getLocation(zoneName);
  }

  static tz.TZDateTime now() {
    initialize();
    return tz.TZDateTime.now(location);
  }

  static tz.TZDateTime fromInstant(DateTime instant) {
    initialize();
    return tz.TZDateTime.from(instant.toUtc(), location);
  }

  static DateTime wallClockToUtc({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) {
    initialize();
    return tz.TZDateTime(location, year, month, day, hour, minute).toUtc();
  }

  static DateTime wallClockFromInstant(DateTime instant) {
    final local = fromInstant(instant);
    return DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
  }

  /// A convenient default schedule start: the next half-hour boundary.
  static DateTime defaultStartUtc() {
    final local = now();
    final minutesToAdd = local.minute < 30
        ? 30 - local.minute
        : 60 - local.minute;
    final next = local.add(Duration(minutes: minutesToAdd));
    initialize();
    return tz.TZDateTime(
      location,
      next.year,
      next.month,
      next.day,
      next.hour,
      next.minute,
    ).toUtc();
  }

  static String formatDate(DateTime instant) =>
      DateFormat('yyyy-MM-dd').format(fromInstant(instant));

  static String formatTime(DateTime instant) =>
      DateFormat('HH:mm').format(fromInstant(instant));

  static String formatDateTime(DateTime instant) =>
      DateFormat('yyyy-MM-dd HH:mm').format(fromInstant(instant));

  static String formatChineseDateTime(DateTime instant) =>
      DateFormat('yyyy年M月d日 HH:mm').format(fromInstant(instant));

  static String formatChineseDate(DateTime instant) =>
      DateFormat('yyyy年M月d日').format(fromInstant(instant));

  static String formatCardRange(DateTime startAt, DateTime endAt) {
    final start = fromInstant(startAt);
    final end = fromInstant(endAt);
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return '${DateFormat('MM-dd').format(start)} '
          '${DateFormat('HH:mm').format(start)}–${DateFormat('HH:mm').format(end)}';
    }
    if (start.year == end.year) {
      return '${DateFormat('MM-dd HH:mm').format(start)}–'
          '${DateFormat('MM-dd HH:mm').format(end)}';
    }
    return '${DateFormat('yyyy-MM-dd HH:mm').format(start)}–'
        '${DateFormat('yyyy-MM-dd HH:mm').format(end)}';
  }

  static String formatFullRange(DateTime startAt, DateTime endAt) {
    return '${formatDateTime(startAt)} – ${formatDateTime(endAt)}';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    final left = fromInstant(a);
    final right = fromInstant(b);
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static bool isCrossDay(DateTime startAt, DateTime endAt) =>
      !isSameDay(startAt, endAt);
}
