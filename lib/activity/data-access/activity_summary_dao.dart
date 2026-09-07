import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glaziovi/activity/activity_summary.dart';
import 'package:glaziovi/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final activitySummaryDaoProvider =
    FutureProvider.autoDispose<ActivitySummaryDao>((ref) async {
      final database = await ref.watch(databaseProvider.future);
      return ActivitySummaryDao(database: database);
    });

class ActivitySummaryDao {
  const ActivitySummaryDao({required this._database});

  final Database _database;

  Future<void> createSummary(ActivitySummary summary) async {
    final value = summary.toMap()..remove('id');

    await _database.insert('activity_summaries', value);
  }

  Future<List<ActivitySummary>> listSummaries() async {
    final rows = await _database.rawQuery(
      'SELECT acs.* FROM activity_summaries acs INNER JOIN activities a ON a.id = acs.activity_data_id ORDER BY a.finished_at_ms DESC',
    );

    return rows.map(ActivitySummary.fromMap).toList();
  }
}
