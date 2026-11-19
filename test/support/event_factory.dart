import 'package:todolist/domain/event.dart';

Event makeEvent({
  String id = 'event-1',
  String title = '测试事件',
  String description = '',
  bool important = false,
  bool urgent = false,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? completedAt,
  ScheduleDetails? schedule,
}) {
  final created = createdAt ?? DateTime.utc(2026, 10, 1, 8);
  return Event(
    id: id,
    title: title,
    description: description,
    important: important,
    urgent: urgent,
    createdAt: created,
    updatedAt: updatedAt ?? created,
    completedAt: completedAt,
    schedule: schedule,
  );
}

ScheduleDetails makeSchedule({
  DateTime? startAt,
  DateTime? endAt,
  String location = '',
}) {
  final start = startAt ?? DateTime.utc(2026, 10, 2, 1);
  return ScheduleDetails(
    startAt: start,
    endAt: endAt ?? start.add(const Duration(hours: 1)),
    location: location,
  );
}
