import 'event.dart';

/// The temporal anchor for an unfinished event.
///
/// A schedule is anchored at its start. A task has no explicit time, so its
/// creation time is used, which keeps ordering stable across restarts.
DateTime sortInstant(Event event) => event.schedule?.startAt ?? event.createdAt;

int compareUnfinished(Event a, Event b) {
  final byTime = sortInstant(a).compareTo(sortInstant(b));
  if (byTime != 0) {
    return byTime;
  }
  final byCreated = a.createdAt.compareTo(b.createdAt);
  if (byCreated != 0) {
    return byCreated;
  }
  return a.id.compareTo(b.id);
}

int compareCompleted(Event a, Event b) {
  final aCompleted = a.completedAt;
  final bCompleted = b.completedAt;
  if (aCompleted == null || bCompleted == null) {
    throw ArgumentError('compareCompleted 仅接受已完成事件');
  }
  final byCompleted = bCompleted.compareTo(aCompleted);
  if (byCompleted != 0) {
    return byCompleted;
  }
  final byCreated = a.createdAt.compareTo(b.createdAt);
  if (byCreated != 0) {
    return byCreated;
  }
  return a.id.compareTo(b.id);
}

List<Event> sortedUnfinished(Iterable<Event> events) {
  return events.where((event) => !event.isCompleted).toList()
    ..sort(compareUnfinished);
}

List<Event> sortedCompleted(Iterable<Event> events) {
  return events.where((event) => event.isCompleted).toList()
    ..sort(compareCompleted);
}

/// Unfinished events always come before completed events.
List<Event> sortedForDisplay(Iterable<Event> events) {
  return [...sortedUnfinished(events), ...sortedCompleted(events)];
}
