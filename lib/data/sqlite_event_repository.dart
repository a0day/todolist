import '../domain/event.dart';
import '../domain/event_repository.dart';
import 'app_database.dart';

class SqliteEventRepository implements EventRepository {
  SqliteEventRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<Event>> loadAll() async {
    final db = await _appDatabase.database;
    final rows = await db.query('events', orderBy: 'created_at ASC');
    return rows.map(_eventFromRow).toList(growable: false);
  }

  @override
  Future<void> insert(Event event) async {
    final db = await _appDatabase.database;
    await db.insert('events', _eventToRow(event));
  }

  @override
  Future<void> update(Event event) async {
    final db = await _appDatabase.database;
    final count = await db.update(
      'events',
      _eventToRow(event),
      where: 'id = ?',
      whereArgs: [event.id],
    );
    if (count != 1) {
      throw StateError('事件不存在或已被删除');
    }
  }

  @override
  Future<void> delete(String id) async {
    final db = await _appDatabase.database;
    final count = await db.delete('events', where: 'id = ?', whereArgs: [id]);
    if (count != 1) {
      throw StateError('事件不存在或已被删除');
    }
  }

  Map<String, Object?> _eventToRow(Event event) {
    final schedule = event.schedule;
    return {
      'id': event.id,
      'title': event.title,
      'description': event.description,
      'important': event.important ? 1 : 0,
      'urgent': event.urgent ? 1 : 0,
      'created_at': event.createdAt.millisecondsSinceEpoch,
      'updated_at': event.updatedAt.millisecondsSinceEpoch,
      'completed_at': event.completedAt?.millisecondsSinceEpoch,
      'start_at': schedule?.startAt.millisecondsSinceEpoch,
      'end_at': schedule?.endAt.millisecondsSinceEpoch,
      'location': schedule?.location,
    };
  }

  Event _eventFromRow(Map<String, Object?> row) {
    try {
      final startAt = row['start_at'] as int?;
      final endAt = row['end_at'] as int?;
      ScheduleDetails? schedule;
      if (startAt != null || endAt != null) {
        if (startAt == null || endAt == null) {
          throw const FormatException('日程的开始或结束时间缺失');
        }
        schedule = ScheduleDetails(
          startAt: DateTime.fromMillisecondsSinceEpoch(startAt, isUtc: true),
          endAt: DateTime.fromMillisecondsSinceEpoch(endAt, isUtc: true),
          location: (row['location'] as String?) ?? '',
        );
      } else if (row['location'] != null) {
        throw const FormatException('任务不应包含地点');
      }

      final completedAt = row['completed_at'] as int?;
      return Event(
        id: row['id'] as String,
        title: row['title'] as String,
        description: (row['description'] as String?) ?? '',
        important: (row['important'] as int) == 1,
        urgent: (row['urgent'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
          isUtc: true,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          row['updated_at'] as int,
          isUtc: true,
        ),
        completedAt: completedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(completedAt, isUtc: true),
        schedule: schedule,
      );
    } catch (error) {
      throw FormatException('事件 ${row['id']} 的数据无法读取：$error');
    }
  }
}
