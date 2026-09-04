import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
    this.isLoadingLocation = false,
    this.error,
  });

  final ActivityView view;
  final ActivityStatus status;

  final Position? currentPosition;
  final Position? previousPosition;
  final List<LatLng> route;

  final double distanceMeters;
  final Duration elapsed;

  final bool isLoadingLocation;
  final ActivityError? error;

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
    bool? isLoadingLocation,
    ActivityError? error,
    bool clearError = false,
  }) {
    return ActivityState(
      view: view ?? this.view,
      status: status ?? this.status,
      currentPosition: currentPosition ?? this.currentPosition,
      previousPosition: previousPosition ?? this.previousPosition,
      route: route ?? this.route,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      elapsed: elapsed ?? this.elapsed,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      error: clearError ? null : error ?? this.error,
    );
  }
}
