import 'dart:io';

import 'package:glaziovi/activity/activity_data.dart';
import 'package:glaziovi/activity/data-access/activity_dao.dart';
import 'package:glaziovi/fit/fit_builder.dart';
import 'package:glaziovi/fit/fit_record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';

part 'home_page_view_model.g.dart';

@riverpod
class HomePageViewModel extends _$HomePageViewModel {
  @override
  Future<List<ActivityData>> build() async {
    final activityDao = await ref.read(activityDAOProvider.future);

    return await activityDao.listFinished();
  }

  // Simple helle world to test the exporter
  Future<void> writeToFit(int activityId) async {
    final activityDao = await ref.read(activityDAOProvider.future);

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

    final deviceInfo = DeviceInfoPlugin();
    final androidDeviceInfo = await deviceInfo.androidInfo;

    final fitBuilder = FitBuilder();
    fitBuilder.writeField(
      createdAt: DateTime.now(),
      deviceUuid: androidDeviceInfo.id,
    );
    fitBuilder.writeRecords(fitTrackPoints);

    final fitData = fitBuilder.build();

    final now = DateTime.now();
    final timestampStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_"
        "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";
    final fileName = "activity_$timestampStr.fit";

    final tempDir = await getTemporaryDirectory();
    final filePath = "${tempDir.path}/$fileName";

    final file = File(filePath);
    await file.writeAsBytes(fitData, flush: true);

    final xFile = XFile(filePath, mimeType: 'application/fits');
    final shareParams = ShareParams(
      text: 'Share this activity',
      subject: 'Fit activity exporter',
      files: [xFile],
    );
    await SharePlus.instance.share(shareParams);
  }
}
