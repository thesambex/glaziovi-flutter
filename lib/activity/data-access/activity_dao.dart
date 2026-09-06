import 'package:glaziovi/activity/activity_data.dart';
import 'package:glaziovi/activity/activity_event.dart';
import 'package:glaziovi/activity/activity_track_point.dart';
import 'package:glaziovi/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

final activityDAOProvider = FutureProvider.autoDispose<ActivityDAO>((
  ref,
) async {
  final database = await ref.watch(databaseProvider.future);
  return ActivityDAO(database: database);
});

class ActivityDAO {
  const ActivityDAO({required this._database});

  final Database _database;

  Future<ActivityData?> findUnfinished() async {
    final rows = await _database.query(
      'activities',
      where: 'finished_at_ms IS NULL AND status IN (?, ?)',
      whereArgs: ['recording', 'paused'],
      orderBy: 'id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : ActivityData.fromMap(rows.single);
  }

  Future<List<ActivityTrackPoint>> getTrackPoints(int activityId) async {
    final rows = await _database.query(
      'activity_track_points',
      where: 'activity_id = ?',
      whereArgs: [activityId],
      orderBy: 'seq',
    );
    return rows.map(ActivityTrackPoint.fromMap).toList();
  }

  Future<void> updateLifecycle(
    int activityId, {
    required ActivityRecordStatus status,
    required int startedAtMs,
    int? finishedAtMs,
  }) async {
    await _database.update(
      'activities',
      {
        'status': status.name,
        'started_at_ms': startedAtMs,
        'finished_at_ms': finishedAtMs,
      },
      where: 'id = ?',
      whereArgs: [activityId],
    );
  }

  Future<ActivityData> createData(ActivityData data) async {
    final values = data.toMap()..remove('id');
    final id = await _database.insert('activities', values);

    return data.copyWith(id: id);
  }

  Future<void> appendChunk({
    required int activityId,
    required List<ActivityTrackPoint> points,
    required List<ActivityEvent> events,
    required double distanceM,
    required Duration elapsed,
    required Duration timer,
  }) async {
    await _database.transaction((txn) async {
      final batch = txn.batch();

      // Insert all track points
      for (var point in points) {
        batch.insert(
          'activity_track_points',
          point.toMap(activityId),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      // Insert all events
      for (var event in events) {
        batch.insert(
          'activity_events',
          event.toMap(activityId),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      // Update activity data
      batch.update(
        'activities',
        {
          'distance_m': distanceM,
          'elapsed_ms': elapsed.inMilliseconds,
          'timer_ms': timer.inMilliseconds,
          if (points.isNotEmpty) 'last_seq': points.last.seq,
        },
        where: 'id = ?',
        whereArgs: [activityId],
      );

      await batch.commit(noResult: true);
    });
  }

  Future<void> deleteActivity(int activityId) async {
    await _database.transaction((txn) async {
      for (final table in ['activity_track_points', 'activity_events']) {
        await txn.delete(
          table,
          where: 'activity_id = ?',
          whereArgs: [activityId],
        );
      }
      await txn.delete(
        'activities',
        where: 'id = ?',
        whereArgs: [activityId],
      );
    });
  }
}
