import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todolist/data/app_database.dart';
import 'package:todolist/data/sqlite_event_repository.dart';
import 'package:todolist/domain/event.dart';

import '../support/event_factory.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late Directory tempDir;
  late String dbPath;
  late AppDatabase database;
  late SqliteEventRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('quadrant_todo_test_');
    dbPath = p.join(tempDir.path, 'events.db');
    database = AppDatabase(factory: databaseFactoryFfi, databasePath: dbPath);
    repository = SqliteEventRepository(database);
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('round-trips tasks and schedules', () async {
    final task = makeEvent(
      id: 'task',
      title: '任务',
      description: '说明',
      important: true,
      urgent: false,
      createdAt: DateTime.utc(2026, 10, 20, 1, 2, 3),
      updatedAt: DateTime.utc(2026, 10, 20, 2, 3, 4),
    );
    final schedule = makeEvent(
      id: 'schedule',
      title: '日程',
      important: false,
      urgent: true,
      createdAt: DateTime.utc(2026, 10, 21, 1),
      completedAt: DateTime.utc(2026, 10, 22, 3),
      schedule: makeSchedule(
        startAt: DateTime.utc(2026, 10, 23, 15, 30),
        endAt: DateTime.utc(2026, 10, 24, 1, 15),
        location: '会议室',
      ),
    );

    await repository.insert(task);
    await repository.insert(schedule);

    final loaded = await repository.loadAll();
    expect(loaded, hasLength(2));

    final loadedTask = loaded.firstWhere((event) => event.id == 'task');
    expect(loadedTask.title, '任务');
    expect(loadedTask.description, '说明');
    expect(loadedTask.important, isTrue);
    expect(loadedTask.urgent, isFalse);
    expect(loadedTask.createdAt, task.createdAt);
    expect(loadedTask.updatedAt, task.updatedAt);
    expect(loadedTask.schedule, isNull);
    expect(loadedTask.completedAt, isNull);

    final loadedSchedule = loaded.firstWhere((event) => event.id == 'schedule');
    expect(loadedSchedule.type, EventType.schedule);
    expect(
      loadedSchedule.schedule?.startAt,
      DateTime.utc(2026, 10, 23, 15, 30),
    );
    expect(loadedSchedule.schedule?.endAt, DateTime.utc(2026, 10, 24, 1, 15));
    expect(loadedSchedule.schedule?.location, '会议室');
    expect(loadedSchedule.completedAt, DateTime.utc(2026, 10, 22, 3));
  });

  test('updates and deletes rows, rejecting stale ids', () async {
    final event = makeEvent(id: 'event');
    await repository.insert(event);

    final updated = event.withCompletion(
      completed: true,
      updatedAt: DateTime.utc(2026, 10, 25),
      completedAt: DateTime.utc(2026, 10, 25),
    );
    await repository.update(updated);

    final loaded = (await repository.loadAll()).single;
    expect(loaded.isCompleted, isTrue);
    expect(loaded.completedAt, DateTime.utc(2026, 10, 25));

    await repository.delete('event');
    expect(await repository.loadAll(), isEmpty);

    await expectLater(repository.update(updated), throwsStateError);
    await expectLater(repository.delete('event'), throwsStateError);
  });

  test('persists events after reopening the database file', () async {
    final event = makeEvent(
      id: 'persisted',
      title: '持久化',
      important: true,
      urgent: true,
      schedule: makeSchedule(location: '家'),
    );
    await repository.insert(event);
    await database.close();

    final reopened = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: dbPath,
    );
    addTearDown(reopened.close);
    final reloaded = await SqliteEventRepository(reopened).loadAll();

    expect(reloaded, hasLength(1));
    expect(reloaded.single.id, 'persisted');
    expect(reloaded.single.title, '持久化');
    expect(reloaded.single.schedule?.location, '家');
  });

  test('database constraints reject malformed rows', () async {
    final raw = await database.database;
    final base = {
      'id': 'bad',
      'title': '坏数据',
      'description': '',
      'important': 0,
      'urgent': 0,
      'created_at': 1,
      'updated_at': 1,
      'completed_at': null,
    };

    await expectLater(
      raw.insert('events', {
        ...base,
        'start_at': 100,
        'end_at': 50,
        'location': null,
      }),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      raw.insert('events', {
        ...base,
        'id': 'location-on-task',
        'start_at': null,
        'end_at': null,
        'location': '不允许',
      }),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      raw.insert('events', {
        ...base,
        'id': 'bad-flag',
        'important': 2,
        'start_at': null,
        'end_at': null,
        'location': null,
      }),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      raw.insert('events', {
        ...base,
        'id': 'empty-title',
        'title': '   ',
        'start_at': null,
        'end_at': null,
        'location': null,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test(
    'reports unreadable rows as FormatException without deleting data',
    () async {
      final raw = await database.database;
      await raw.execute('DROP TABLE events');
      await raw.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        important INTEGER NOT NULL,
        urgent INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        completed_at INTEGER,
        start_at INTEGER,
        end_at INTEGER,
        location TEXT
      )
    ''');
      await raw.insert('events', {
        'id': 'partial',
        'title': '损坏日程',
        'description': '',
        'important': 0,
        'urgent': 0,
        'created_at': 1,
        'updated_at': 1,
        'start_at': 100,
        'end_at': null,
        'location': null,
      });

      await expectLater(
        repository.loadAll(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('无法读取'),
          ),
        ),
      );

      final rows = await raw.rawQuery('SELECT COUNT(*) AS count FROM events');
      expect(rows.first['count'], 1);
    },
  );
}
