import 'dart:io';

import 'dart:developer' as developer;

import 'package:glaziovi/activity/activity_summary.dart';
import 'package:glaziovi/activity/data-access/activity_dao.dart';
import 'package:glaziovi/activity/data-access/activity_summary_dao.dart';
import 'package:glaziovi/fit/fit_builder.dart';
import 'package:glaziovi/fit/fit_file_type.dart';
import 'package:glaziovi/fit/fit_record.dart';
import 'package:glaziovi/fit/fit_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:device_info_plus/device_info_plus.dart';

part 'home_page_view_model.g.dart';

@riverpod
class HomePageViewModel extends _$HomePageViewModel {
  @override
  Future<List<ActivitySummary>> build() async {
    final activitySummaryDao = await ref.read(
      activitySummaryDaoProvider.future,
    );

    return await activitySummaryDao.listSummaries();
  }

  // Simple helle world to test the exporter
  Future<void> exportToFit({
    required int activityId,
    required Function(String) onExported,
  }) async {
    final activityDao = await ref.read(activityDaoProvider.future);

    try {
      /*  FIT file construction */
      final activity = await activityDao.findById(activityId);
      if (activity == null) return;

      final trackPoints = await activityDao.getTrackPoints(activityId);
      final fitTrackPoints = trackPoints
          .map(
            (point) => FitRecord(
              timestamp: DateTime.fromMillisecondsSinceEpoch(point.timestampMs),
              altitude: point.altitudeM,
              latitude: point.latitude,
              longitude: point.longitude,
              speed: point.speedMps,
            ),
          )
          .toList();

      final activitySession = FitSession(
        startTime: DateTime.fromMillisecondsSinceEpoch(activity.startedAtMs),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          activity.finishedAtMs ?? 0,
        ),
        totalElapsedTime: activity.elapsedMs,
        totalTimerTime: activity.timerMs,
        totalDistance: activity.distanceM,
        sport: activity.sport,
        subSport: activity.subSport,
      );

      final deviceInfo = DeviceInfoPlugin();
      final androidDeviceInfo = await deviceInfo.androidInfo;

      final fitBuilder = FitBuilder();
      fitBuilder.writeField(
        fileType: FitFileType.activity,
        createdAt: activitySession.startTime,
        deviceUuid: androidDeviceInfo.id,
      );
      fitBuilder.writeRecords(fitTrackPoints);
      fitBuilder.writeSession(session: activitySession);
      fitBuilder.writeActivity(session: activitySession);
      final fitData = fitBuilder.build();

      /*  File serialization */
      final now = DateTime.now();
      final timestampStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_"
          "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";
      final fileName = "glaziovi_activity_$timestampStr.fit";

      // Only in Android for now
      final appDirectory = await getExternalStorageDirectory();
      if (appDirectory == null) {
        throw StateError('External storage directory is unavailable');
      }

      final activitiesDirectory = Directory('${appDirectory.path}/activities');
      await activitiesDirectory.create(recursive: true);

      final filePath = '${activitiesDirectory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(fitData, flush: true);

      onExported(filePath);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to export activity',
        name: 'glaziovi.app.home-page',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
