import 'event.dart';

abstract interface class EventRepository {
  Future<List<Event>> loadAll();

  Future<void> insert(Event event);

  Future<void> update(Event event);

  Future<void> delete(String id);
}
