import '../core/beijing_time.dart';
import 'event.dart';

/// Converts a schedule into a task without silently discarding its time and
/// location: the information is appended to the task description.
String preserveScheduleInDescription(
  String description,
  ScheduleDetails schedule,
) {
  final summary = StringBuffer('原日程：')
    ..write(BeijingTime.formatFullRange(schedule.startAt, schedule.endAt));
  if (schedule.location.isNotEmpty) {
    summary.write('，地点：${schedule.location}');
  }
  final trimmed = description.trim();
  if (trimmed.isEmpty) {
    return summary.toString();
  }
  return '$trimmed\n\n$summary';
}
