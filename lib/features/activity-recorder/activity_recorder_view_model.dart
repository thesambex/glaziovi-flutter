import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:glaziovi/activity/actitivy_buffer.dart';
import 'package:glaziovi/activity/activity_data.dart';
import 'package:glaziovi/activity/activity_sport.dart';
import 'package:glaziovi/activity/activity_event.dart';
import 'package:glaziovi/activity/activity_sport_type.dart';
import 'package:glaziovi/activity/activity_sub_sport_type.dart';
import 'package:glaziovi/activity/activity_summary.dart';
import 'package:glaziovi/activity/data-access/activity_dao.dart';
import 'package:glaziovi/activity/data-access/activity_summary_dao.dart';
import 'package:glaziovi/features/activity-recorder/activity_recorder_state.dart';
import 'package:glaziovi/l10n/l10n_providers.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'dart:developer' as developer;

part 'activity_recorder_view_model.g.dart';

@Riverpod(keepAlive: true)
class ActivityRecorderViewModel extends _$ActivityRecorderViewModel {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _elapsedTimer;

  DateTime? _recordingStartedAt;
  Duration _elapsedBeforeCurrentRecording = Duration.zero;

  bool _isInitialized = false;
  bool _isStarting = false;
  bool _isDeleting = false;

  bool get isReady => state.isReady;

  @override
  ActivityState build() {
    ref.onDispose(() {
      _elapsedTimer?.cancel();
      _positionSubscription?.cancel();
      _activityBuffer?.dispose();
    });

    return const ActivityState();
  }

  ActivityData? _activityData;
  ActivityBuffer? _activityBuffer;
  Future<void>? _restoration;

  Future<void> _restoreActivity() => _restoration ??= _loadActivity();

  /// Load unfinished activity
  Future<void> _loadActivity() async {
    try {
      final activityDao = await ref.read(activityDaoProvider.future);
      final data = await activityDao.findUnfinished();

      if (data == null) return;

      final points = await activityDao.getTrackPoints(data.id);

      await activityDao.updateLifecycle(
        data.id,
        status: ActivityRecordStatus.paused,
        startedAtMs: data.startedAtMs,
      );

      _activityData = data.copyWith(status: ActivityRecordStatus.paused);
      _activityBuffer = ActivityBuffer(
        activityId: data.id,
        activityDao: activityDao,
        startSeq: points.isEmpty ? 0 : points.last.seq + 1,
      );

      _elapsedBeforeCurrentRecording = Duration(milliseconds: data.timerMs);

      state = state.copyWith(
        status: data.startedAtMs < 0
            ? ActivityStatus.idle
            : ActivityStatus.paused,
        startedAt: data.startedAtMs < 0
            ? null
            : DateTime.fromMillisecondsSinceEpoch(data.startedAtMs),
        elapsed: _elapsedBeforeCurrentRecording,
        selectedSport: ActivitySport.fromFit(data.sport, data.subSport),
        distanceMeters: data.distanceM,
        route: points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList(),
        clearPreviousPosition: true,
      );

      _updateBufferTotals();
    } catch (_) {
      _restoration = null;
      rethrow;
    }
  }

  void _updateBufferTotals() {
    final startedAt = state.startedAt;
    _activityBuffer?.updateTotals(
      elapsed: startedAt == null
          ? Duration.zero
          : (state.finishedAt ?? DateTime.now()).difference(startedAt),
      timer: state.elapsed,
      distanceM: state.distanceMeters,
    );
  }

  Future<void> _saveLifecycle(ActivityRecordStatus status) async {
    final data = _activityData;
    if (data == null) return;

    _updateBufferTotals();

    await _activityBuffer?.flush();

    final activityDao = await ref.read(activityDaoProvider.future);
    await activityDao.updateLifecycle(
      data.id,
      status: status,
      startedAtMs: state.startedAt?.millisecondsSinceEpoch ?? -1,
      finishedAtMs: state.finishedAt?.millisecondsSinceEpoch,
    );
  }

  /// Create a new activity
  Future<void> createActivity(
    ActivitySportType sportType,
    ActivitySubSportType subSport,
  ) async {
    await _restoreActivity();
    if (_activityData != null) return;
    final activityDao = await ref.read(activityDaoProvider.future);

    final data = ActivityData(
      id: 0,
      sport: sportType.value,
      subSport: subSport.value,
      startedAtMs: -1,
      finishedAtMs: null,
      elapsedMs: 0,
      timerMs: 0,
      distanceM: 0,
      status: ActivityRecordStatus.paused,
      lastSeq: -1,
    );

    _activityData = await activityDao.createData(data);

    _activityBuffer = ActivityBuffer(
      activityId: _activityData!.id,
      activityDao: activityDao,
      startSeq: 0,
    );
    state = state.copyWith(
      selectedSport: ActivitySport.of(sportType, subSport),
    );
  }

  /// Delete current activity
  Future<void> deleteActivity(VoidCallback onDeleted) async {
    if (_isDeleting || _isStarting) return;
    _isDeleting = true;

    try {
      final data = _activityData;
      if (data == null || data.id <= 0) return;

      _updateElapsed();

      _elapsedBeforeCurrentRecording = state.elapsed;
      _recordingStartedAt = null;
      _elapsedTimer?.cancel();
      _elapsedTimer = null;

      state = state.copyWith(
        status: ActivityStatus.paused,
        clearPreviousPosition: true,
        clearError: true,
      );

      await _positionSubscription?.cancel();
      _positionSubscription = null;

      await _activityBuffer?.dispose();

      final activityDao = await ref.read(activityDaoProvider.future);
      await activityDao.deleteActivity(data.id);

      _activityBuffer = null;
      _activityData = null;
      _elapsedBeforeCurrentRecording = Duration.zero;
      state = ActivityState(currentPosition: state.currentPosition);

      onDeleted();
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
    } finally {
      _isDeleting = false;
    }
  }

  /// Initialize activity get GPS position, and restore pending activity
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;

    state = state.copyWith(isLoadingLocation: true, clearError: true);

    try {
      await _restoreActivity();
      await _ensureLocationPermission();

      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        state = state.copyWith(currentPosition: lastPosition);
      }

      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      state = state.copyWith(
        currentPosition: currentPosition,
        isLoadingLocation: false,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(isLoadingLocation: false);

      _handleError(error, stackTrace);
    }
  }

  /// Starts a new activity when is ready
  Future<void> start() async {
    if (_isStarting || _isDeleting) return;
    _isStarting = true;

    try {
      await _restoreActivity();

      if (state.status != ActivityStatus.idle || !state.isReady) return;

      await _ensureLocationPermission();

      if (Platform.isAndroid) {
        await Permission.notification.request();
      }

      final startedAt = DateTime.now();
      final activityDao = await ref.read(activityDaoProvider.future);

      await activityDao.updateLifecycle(
        _activityData!.id,
        status: ActivityRecordStatus.recording,
        startedAtMs: startedAt.millisecondsSinceEpoch,
      );

      _recordingStartedAt = startedAt;

      state = state.copyWith(
        status: ActivityStatus.recording,
        startedAt: _recordingStartedAt,
        clearPreviousPosition: true,
        clearError: true,
      );

      _startElapsedTimer();

      await _activityBuffer?.addEvent(
        ActivityEventType.timerStart,
        startedAt.millisecondsSinceEpoch,
      );

      await _startPositionStream();
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
    } finally {
      _isStarting = false;
    }
  }

  /// Pause current activity
  Future<void> pause() async {
    if (_isDeleting) return;
    if (!state.isRecording) return;

    _updateElapsed();

    _elapsedBeforeCurrentRecording = state.elapsed;
    _recordingStartedAt = null;

    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _updateBufferTotals();

    await _activityBuffer?.addEvent(
      ActivityEventType.timerStop,
      DateTime.now().millisecondsSinceEpoch,
    );

    state = state.copyWith(
      status: ActivityStatus.paused,
      clearPreviousPosition: true,
    );

    await _saveLifecycle(ActivityRecordStatus.paused);
  }

  /// Record every distance boundary crossed by an accepted GPS segment.
  /// Comparing cumulative distances also works after restoring an activity.
  Future<void> _registerAutoLaps({
    required double previousDistanceM,
    required double currentDistanceM,
    required Position previousPosition,
    required Position currentPosition,
  }) async {
    final buffer = _activityBuffer;

    // TODO: Create lap system for manual and other lap events
    final lapDistanceM = switch (state.selectedSport?.sport) {
      ActivitySportType.running || ActivitySportType.walking => 1000,
      ActivitySportType.cycling => 5000,
      _ => null,
    };

    if (buffer == null || lapDistanceM == null) return;
    if (currentDistanceM <= previousDistanceM) return;

    final firstLap = (previousDistanceM / lapDistanceM).floor() + 1;
    final lastLap = (currentDistanceM / lapDistanceM).floor();
    if (firstLap > lastLap) return;

    final startMs = previousPosition.timestamp.millisecondsSinceEpoch;
    final endMs = currentPosition.timestamp.millisecondsSinceEpoch;
    final writes = <Future<void>>[];

    for (var lap = firstLap; lap <= lastLap; lap++) {
      // Estimate the crossing time between the two GPS samples.
      final fraction =
          (lap * lapDistanceM - previousDistanceM) /
          (currentDistanceM - previousDistanceM);

      final timestampMs = startMs + ((endMs - startMs) * fraction).round();
      writes.add(buffer.addEvent(ActivityEventType.lap, timestampMs));
    }

    try {
      await Future.wait(writes);
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
    }
  }

  /// Resume current paused activity
  Future<void> resume() async {
    if (_isDeleting) return;
    if (state.status != ActivityStatus.paused) return;

    try {
      await _ensureLocationPermission();

      _recordingStartedAt = DateTime.now();

      _updateBufferTotals();

      await _activityBuffer?.addEvent(
        ActivityEventType.timerStart,
        DateTime.now().millisecondsSinceEpoch,
      );

      state = state.copyWith(
        status: ActivityStatus.recording,
        clearPreviousPosition: true,
        clearError: true,
      );

      _startElapsedTimer();

      await _saveLifecycle(ActivityRecordStatus.recording);
      await _startPositionStream();
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
    }
  }

  /// Finish actitivy and clear state
  Future<void> finish(VoidCallback onFinished) async {
    if (_isDeleting) return;
    if (state.status != ActivityStatus.paused || state.startedAt == null) {
      return;
    }
    _updateElapsed();

    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _recordingStartedAt = null;
    _elapsedBeforeCurrentRecording = Duration.zero;

    state = state.copyWith(
      status: ActivityStatus.finished,
      finishedAt: DateTime.now(),
    );

    await _saveLifecycle(ActivityRecordStatus.finished);
    await reset();

    onFinished();
  }

  /// Clear activity state
  Future<void> reset() async {
    if (_isDeleting) return;
    if (state.hasStarted) await _saveLifecycle(ActivityRecordStatus.aborted);
    _elapsedTimer?.cancel();

    await _positionSubscription?.cancel();

    _elapsedTimer = null;
    _positionSubscription = null;
    _recordingStartedAt = null;
    _elapsedBeforeCurrentRecording = Duration.zero;

    await _activityBuffer?.dispose();

    _activityBuffer = null;
    _activityData = null;
    state = ActivityState(currentPosition: state.currentPosition);
  }

  Future<void> createSummary(String name, VoidCallback onCreated) async {
    if (_isDeleting || state.status != ActivityStatus.paused) return;
    if (_activityData == null || _activityData!.id <= 0) return;

    final trimmedName = name.trim();

    try {
      final activitySummaryDao = await ref.read(
        activitySummaryDaoProvider.future,
      );

      final summary = ActivitySummary(
        id: 0,
        name: trimmedName.isEmpty ? 'Glaziovi activity' : trimmedName,
        activityDataId: _activityData!.id,
        isSynced: false,
      );

      await activitySummaryDao.createSummary(summary);

      await finish(onCreated);
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
    }
  }

  void clearError() {
    if (state.error == null) return;

    state = state.copyWith(clearError: true);
  }

  /// TODO: Create metrics view
  void toggleView() {
    state = state.copyWith(
      view: state.view == ActivityView.map
          ? ActivityView.metrics
          : ActivityView.map,
    );
  }

  LocationSettings _createLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final l10n = ref.read(appLocalizationsProvider);

      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: l10n.recordingNotificationTitle,
          notificationText: l10n.recordingNotificationText,
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    );
  }

  Future<void> _startPositionStream() async {
    await _positionSubscription?.cancel();

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: _createLocationSettings(),
        ).listen(
          _onPosition,
          onError: (Object error, StackTrace stackTrace) {
            _handleError(error, stackTrace);
          },
        );
  }

  void _handleError(Object error, [StackTrace? stackTrace]) {
    state = state.copyWith(
      error: error is ActivityException ? error.error : ActivityError.unknown,
    );

    developer.log(
      'Activity recorder failure',
      name: 'glaziovi.app.activity-recorder',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _onPosition(Position position) {
    if (!state.isRecording) return;

    final previousPosition = state.previousPosition;
    final previousDistanceM = state.distanceMeters;
    var distanceMeters = previousDistanceM;

    if (previousPosition != null && _isAcceptablePosition(position)) {
      final segmentDistance = Geolocator.distanceBetween(
        previousPosition.latitude,
        previousPosition.longitude,
        position.latitude,
        position.longitude,
      );

      if (_isAcceptableSegment(previousPosition, position, segmentDistance)) {
        distanceMeters += segmentDistance;
      }
    }

    state = state.copyWith(
      currentPosition: position,
      previousPosition: position,
      distanceMeters: distanceMeters,
      route: [...state.route, LatLng(position.latitude, position.longitude)],
    );

    _updateElapsed();

    _activityBuffer?.addPoint(
      timestampMs: position.timestamp.millisecondsSinceEpoch,
      latitude: position.latitude,
      longitude: position.longitude,
      altitudeM: position.altitude > 0 ? position.altitude : null,
      cumulativeDistanceM: distanceMeters,
    );

    if (previousPosition != null && distanceMeters > previousDistanceM) {
      unawaited(
        _registerAutoLaps(
          previousDistanceM: previousDistanceM,
          currentDistanceM: distanceMeters,
          previousPosition: previousPosition,
          currentPosition: position,
        ),
      );
    }
  }

  bool _isAcceptablePosition(Position position) {
    return position.accuracy <= 30;
  }

  bool _isAcceptableSegment(
    Position previous,
    Position current,
    double distance,
  ) {
    final elapsedMilliseconds = current.timestamp
        .difference(previous.timestamp)
        .inMilliseconds;

    if (elapsedMilliseconds <= 0) return false;

    final elapsedSeconds = elapsedMilliseconds / 1000;
    final calculatedSpeed = distance / elapsedSeconds;

    final maxSpeed =
        (state.selectedSport ?? ActivitySport.unknown).maxGpsSpeedMps;
    return distance >= 1 && calculatedSpeed <= maxSpeed;
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateElapsed();
      if (timer.tick % 30 == 0) {
        unawaited(_checkpoint());
      }
    });

    _updateElapsed();
  }

  void _updateElapsed() {
    final startedAt = _recordingStartedAt;
    if (startedAt == null) return;

    state = state.copyWith(
      elapsed:
          _elapsedBeforeCurrentRecording + DateTime.now().difference(startedAt),
    );
    _updateBufferTotals();
  }

  Future<void> _checkpoint() async {
    try {
      await _activityBuffer?.flush();
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
    }
  }

  Future<void> _ensureLocationPermission() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw const ActivityException(ActivityError.locationServiceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const ActivityException(ActivityError.locationPermissionDenied);
    }

    if (permission == LocationPermission.deniedForever) {
      throw const ActivityException(
        ActivityError.locationPermissionDeniedForever,
      );
    }

    if (Platform.isAndroid) {
      final backgroundStatus = await Permission.locationAlways.request();

      if (!backgroundStatus.isGranted) {
        throw const ActivityException(
          ActivityError.backgroundLocationPermissionDenied,
        );
      }
    }
  }
}
