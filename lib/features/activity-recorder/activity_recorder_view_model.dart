import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  ActivityState build() {
    return const ActivityState();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;

    state = state.copyWith(isLoadingLocation: true, clearError: true);

    try {
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

  Future<void> start() async {
    try {
      await _ensureLocationPermission();

      if (Platform.isAndroid) {
        await Permission.notification.request();
      }

      _recordingStartedAt = DateTime.now();

      state = state.copyWith(
        status: ActivityStatus.recording,
        previousPosition: state.currentPosition,
        clearError: true,
      );

      _startElapsedTimer();
      await _startPositionStream();
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
    }
  }

  Future<void> pause() async {
    if (!state.isRecording) return;

    _updateElapsed();

    _elapsedBeforeCurrentRecording = state.elapsed;
    _recordingStartedAt = null;

    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    state = state.copyWith(
      status: ActivityStatus.paused,
      previousPosition: state.currentPosition,
    );
  }

  Future<void> resume() async {
    if (state.status != ActivityStatus.paused) return;

    try {
      await _ensureLocationPermission();

      _recordingStartedAt = DateTime.now();

      state = state.copyWith(
        status: ActivityStatus.recording,
        previousPosition: state.currentPosition,
        clearError: true,
      );

      _startElapsedTimer();
      await _startPositionStream();
    } catch (error, stackTrace) {
      _handleError(error, stackTrace);
    }
  }

  Future<void> finish() async {
    _updateElapsed();

    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _recordingStartedAt = null;
    _elapsedBeforeCurrentRecording = Duration.zero;

    state = state.copyWith(status: ActivityStatus.finished);
  }

  Future<void> reset() async {
    _elapsedTimer?.cancel();
    await _positionSubscription?.cancel();

    _elapsedTimer = null;
    _positionSubscription = null;
    _recordingStartedAt = null;
    _elapsedBeforeCurrentRecording = Duration.zero;

    state = ActivityState(currentPosition: state.currentPosition);
  }

  void clearError() {
    if (state.error == null) return;

    state = state.copyWith(clearError: true);
  }

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
    var distanceMeters = state.distanceMeters;

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

    // TODO: Check speed by activity type
    return distance >= 1 && calculatedSpeed <= 15;
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();

    _elapsedTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateElapsed(),
    );

    _updateElapsed();
  }

  void _updateElapsed() {
    final startedAt = _recordingStartedAt;
    if (startedAt == null) return;

    state = state.copyWith(
      elapsed:
          _elapsedBeforeCurrentRecording + DateTime.now().difference(startedAt),
    );
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
