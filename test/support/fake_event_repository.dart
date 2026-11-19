import 'package:todolist/domain/event.dart';
import 'package:todolist/domain/event_repository.dart';

class FakeEventRepository implements EventRepository {
  FakeEventRepository([Iterable<Event> initial = const []])
    : events = [...initial];

  final List<Event> events;
  Object? loadError;
  Object? insertError;
  Object? updateError;
  Object? deleteError;

  @override
  Future<List<Event>> loadAll() async {
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return List<Event>.of(events);
  }

  @override
  Future<void> insert(Event event) async {
    final error = insertError;
    if (error != null) {
      throw error;
    }
    events.add(event);
  }

  @override
  Future<void> update(Event event) async {
    final error = updateError;
    if (error != null) {
      throw error;
    }
    final index = events.indexWhere((item) => item.id == event.id);
    if (index == -1) {
      throw StateError('事件不存在');
    }
    events[index] = event;
  }

  @override
  Future<void> delete(String id) async {
    final error = deleteError;
    if (error != null) {
      throw error;
    }
    final before = events.length;
    events.removeWhere((event) => event.id == id);
    if (events.length == before) {
      throw StateError('事件不存在');
    }
  }
}
