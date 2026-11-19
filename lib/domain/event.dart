import 'quadrant.dart';

enum EventType { task, schedule }

class ScheduleDetails {
  final DateTime startAt;
  final DateTime endAt;
  final String location;

  ScheduleDetails({
    required DateTime startAt,
    required DateTime endAt,
    String location = '',
  }) : startAt = startAt.toUtc(),
       endAt = endAt.toUtc(),
       location = location.trim() {
    if (this.endAt.isBefore(this.startAt)) {
      throw ArgumentError('结束时间不得早于开始时间');
    }
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final bool important;
  final bool urgent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final ScheduleDetails? schedule;

  Event({
    required this.id,
    required String title,
    String description = '',
    required this.important,
    required this.urgent,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
    this.schedule,
  }) : title = title.trim(),
       description = description.trim(),
       createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc(),
       completedAt = completedAt?.toUtc() {
    if (id.trim().isEmpty) {
      throw ArgumentError('事件 ID 不能为空');
    }
    if (this.title.isEmpty) {
      throw ArgumentError('事件标题不能为空');
    }
  }

  bool get isCompleted => completedAt != null;

  EventType get type => schedule == null ? EventType.task : EventType.schedule;

  Quadrant get quadrant => quadrantFor(important: important, urgent: urgent);

  Event withCompletion({
    required bool completed,
    required DateTime updatedAt,
    required DateTime completedAt,
  }) {
    return Event(
      id: id,
      title: title,
      description: description,
      important: important,
      urgent: urgent,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completed ? completedAt : null,
      schedule: schedule,
    );
  }
}

class EventDraft {
  final String title;
  final String description;
  final bool important;
  final bool urgent;
  final ScheduleDetails? schedule;

  EventDraft({
    required String title,
    String description = '',
    required this.important,
    required this.urgent,
    this.schedule,
  }) : title = title.trim(),
       description = description.trim();

  EventType get type => schedule == null ? EventType.task : EventType.schedule;
}
