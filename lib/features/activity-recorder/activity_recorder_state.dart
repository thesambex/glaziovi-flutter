import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:glaziovi/activity/activity_sport.dart';

enum ActivityView { map, metrics }

enum ActivityStatus { idle, recording, paused, finished }

enum ActivityError {
  locationServiceDisabled,
  locationPermissionDenied,
  locationPermissionDeniedForever,
  backgroundLocationPermissionDenied,
  unknown,
}

class ActivityException implements Exception {
  const ActivityException(this.error);

  final ActivityError error;

  @override
  String toString() => 'ActivityException(${error.name})';
}

class ActivityState {
  const ActivityState({
    this.view = ActivityView.map,
    this.status = ActivityStatus.idle,
    this.currentPosition,
    this.previousPosition,
    this.route = const [],
    this.distanceMeters = 0,
    this.elapsed = Duration.zero,
    this.startedAt,
    this.finishedAt,
    this.isLoadingLocation = false,
    this.error,
    this.selectedSport,
  });

  final ActivityView view;
  final ActivityStatus status;

  final Position? currentPosition;
  final Position? previousPosition;
  final List<LatLng> route;

  final double distanceMeters;
  final Duration elapsed;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  /// Average over recorded time; pauses and time offline are excluded.
  double get averageSpeedKmh => elapsed.inMilliseconds <= 0
      ? 0
      : distanceMeters * 3600 / elapsed.inMilliseconds;

  final bool isLoadingLocation;
  final ActivityError? error;
  final ActivitySport? selectedSport;
  bool get isReady => selectedSport != null;

  bool get isRecording => status == ActivityStatus.recording;

  bool get hasStarted =>
      status == ActivityStatus.recording || status == ActivityStatus.paused;

  ActivityState copyWith({
    ActivityView? view,
    ActivityStatus? status,
    Position? currentPosition,
    Position? previousPosition,
    List<LatLng>? route,
    double? distanceMeters,
    Duration? elapsed,
    DateTime? startedAt,
    DateTime? finishedAt,
    bool? isLoadingLocation,
    ActivityError? error,
    ActivitySport? selectedSport,
    bool clearError = false,
    bool clearPreviousPosition = false,
  }) {
    return ActivityState(
      view: view ?? this.view,
      status: status ?? this.status,
      currentPosition: currentPosition ?? this.currentPosition,
      previousPosition: clearPreviousPosition
          ? null
          : previousPosition ?? this.previousPosition,
      route: route ?? this.route,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      elapsed: elapsed ?? this.elapsed,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      error: clearError ? null : error ?? this.error,
      selectedSport: selectedSport ?? this.selectedSport,
    );
  }
}
