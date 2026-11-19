import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/event.dart';
import '../domain/event_repository.dart';
import '../domain/event_sorting.dart';
import '../domain/quadrant.dart';

typedef Clock = DateTime Function();
typedef IdGenerator = String Function();

class EventController extends ChangeNotifier {
  EventController({
    required this.repository,
    Clock? clock,
    IdGenerator? idGenerator,
  }) : _clock = clock ?? _utcNow,
       _generateId = idGenerator ?? _generateUuid;

  static final Uuid _uuid = Uuid();

  static DateTime _utcNow() => DateTime.now().toUtc();

  static String _generateUuid() => _uuid.v4();

  final EventRepository repository;
  final Clock _clock;
  final IdGenerator _generateId;
  final List<Event> _events = [];

  bool _isLoading = false;
  bool _hasLoaded = false;
  Object? _loadError;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  Object? get loadError => _loadError;

  List<Event> get allEvents => List.unmodifiable(_events);

  Future<void> load() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      final loaded = await repository.loadAll();
      _events
        ..clear()
        ..addAll(loaded);
      _hasLoaded = true;
    } catch (error, stackTrace) {
      _loadError = error;
      debugPrint('Failed to load events: $error\n$stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Event? eventById(String id) {
    for (final event in _events) {
      if (event.id == id) {
        return event;
      }
    }
    return null;
  }

  List<Event> unfinishedIn(Quadrant quadrant) {
    return sortedUnfinished(
      _events.where((event) => event.quadrant == quadrant),
    );
  }

  List<Event> completedIn(Quadrant quadrant) {
    return sortedCompleted(
      _events.where((event) => event.quadrant == quadrant),
    );
  }

  int pendingCountIn(Quadrant quadrant) {
    return _events
        .where((event) => event.quadrant == quadrant && !event.isCompleted)
        .length;
  }

  Future<Event> create(EventDraft draft) async {
    final now = _clock().toUtc();
    final event = Event(
      id: _generateId(),
      title: draft.title,
      description: draft.description,
      important: draft.important,
      urgent: draft.urgent,
      createdAt: now,
      updatedAt: now,
      schedule: draft.schedule,
    );
    await repository.insert(event);
    _events.add(event);
    notifyListeners();
    return event;
  }

  Future<Event> update(Event existing, EventDraft draft) async {
    final now = _clock().toUtc();
    final updated = Event(
      id: existing.id,
      title: draft.title,
      description: draft.description,
      important: draft.important,
      urgent: draft.urgent,
      createdAt: existing.createdAt,
      updatedAt: now,
      completedAt: existing.completedAt,
      schedule: draft.schedule,
    );
    await repository.update(updated);
    _replace(updated);
    notifyListeners();
    return updated;
  }

  Future<Event> setCompleted(Event event, bool completed) async {
    final now = _clock().toUtc();
    final updated = event.withCompletion(
      completed: completed,
      updatedAt: now,
      completedAt: now,
    );
    await repository.update(updated);
    _replace(updated);
    notifyListeners();
    return updated;
  }

  Future<Event> toggleCompleted(Event event) =>
      setCompleted(event, !event.isCompleted);

  Future<void> delete(Event event) async {
    await repository.delete(event.id);
    _events.removeWhere((item) => item.id == event.id);
    notifyListeners();
  }

  void _replace(Event updated) {
    final index = _events.indexWhere((event) => event.id == updated.id);
    if (index == -1) {
      _events.add(updated);
    } else {
      _events[index] = updated;
    }
  }
}
