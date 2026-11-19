import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and forward-only schema migrations.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, this.databasePath})
    : _factory = factory ?? databaseFactory;

  static const int schemaVersion = 1;
  static const String defaultFileName = 'quadrant_todo.db';

  final DatabaseFactory _factory;
  final String? databasePath;
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final opened = await _open();
    _database = opened;
    return opened;
  }

  Future<Database> _open() async {
    final dbPath =
        databasePath ?? path.join(await getDatabasesPath(), defaultFileName);
    return _factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: _createSchema,
        onUpgrade: _onUpgrade,
        onDowngrade: _onDowngrade,
      ),
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL CHECK (length(trim(title)) > 0),
        description TEXT NOT NULL DEFAULT '',
        important INTEGER NOT NULL CHECK (important IN (0, 1)),
        urgent INTEGER NOT NULL CHECK (urgent IN (0, 1)),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        completed_at INTEGER,
        start_at INTEGER,
        end_at INTEGER,
        location TEXT,
        CHECK (
          (start_at IS NULL AND end_at IS NULL AND location IS NULL)
          OR
          (start_at IS NOT NULL AND end_at IS NOT NULL AND end_at >= start_at)
        )
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_events_quadrant
      ON events (important, urgent, completed_at, start_at, created_at)
    ''');
  }

  /// Migrations are explicit and forward-only. Never delete user data when a
  /// migration is missing or an older schema is opened.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    throw StateError('缺少数据库迁移步骤：$oldVersion → $newVersion，已停止打开以保护数据。');
  }

  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    throw StateError('数据库版本 $oldVersion 高于应用支持的 $newVersion，已停止打开以保护数据。');
  }

  Future<void> close() async {
    final existing = _database;
    _database = null;
    await existing?.close();
  }
}
