import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static Future<Database> open() {
    return openDatabase(
      'glaziovi.db',
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE IF NOT EXISTS activities (
          id INTEGER PRIMARY KEY,
          sport INTEGER NOT NULL,
          sub_sport INTEGER NOT NULL,
          started_at_ms INTEGER NOT NULL,
          finished_at_ms INTEGER,
          elapsed_ms INTEGER NOT NULL DEFAULT 0,
          timer_ms INTEGER NOT NULL DEFAULT 0,
          distance_m REAL NOT NULL DEFAULT 0,
          status TEXT NOT NULL,
          last_seq INTEGER NOT NULL DEFAULT -1
        )
        ''');

        await db.execute('''CREATE TABLE IF NOT EXISTS activity_track_points (
          activity_id INTEGER NOT NULL,
          seq INTEGER NOT NULL,
          timestamp_ms INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          altitude_m REAL,
          accuracy_m REAL,
          speed_mps REAL,
          cumulative_distance_m REAL NOT NULL,
          is_valid INTEGER NOT NULL DEFAULT 1,
          PRIMARY KEY (activity_id, seq),
          FOREIGN KEY (activity_id) REFERENCES activities (id) ON DELETE CASCADE
        )
        ''');

        await db.execute('''CREATE TABLE IF NOT EXISTS activity_events (
          activity_id INTEGER NOT NULL,
          timestamp_ms INTEGER NOT NULL,
          type TEXT NOT NULL,
          cumulative_distance_m REAL NOT NULL,
          elapsed_ms INTEGER NOT NULL,
          timer_ms INTEGER NOT NULL,
          PRIMARY KEY (activity_id, timestamp_ms, type),
          FOREIGN KEY (activity_id) REFERENCES activities (id) ON DELETE CASCADE
        )
        ''');

        await _createActivitySummaries(db);
      },
    );
  }

  static Future<void> _createActivitySummaries(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS activity_summaries (
          id INTEGER NOT NULL,
          activity_name TEXT NOT NULL,
          activity_data_id INTEGER NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (id),
          FOREIGN KEY (activity_data_id) REFERENCES activities (id) ON DELETE CASCADE
        )
        ''');
    await db.execute('''CREATE INDEX IF NOT EXISTS
      idx_activity_summaries_activity_data_id
      ON activity_summaries (activity_data_id)
    ''');
  }
}
