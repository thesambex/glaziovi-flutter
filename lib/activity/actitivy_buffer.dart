import 'dart:async';

import 'package:glaziovi/activity/activity_event.dart';
import 'package:glaziovi/activity/activity_track_point.dart';
import 'package:glaziovi/activity/data-access/activity_dao.dart';

class ActivityBuffer {
  ActivityBuffer({
    required this._activityId,
    required this._activityDao,
    required int startSeq,
    this.chunkSize = 30,
    this.maxBufferAge = const Duration(seconds: 30),
  }) : _nextSeq = startSeq;

  final int _activityId;
  final ActivityDAO _activityDao;

  final Duration maxBufferAge;

  /// Track points size of record
  final int chunkSize;

  final List<ActivityTrackPoint> _pendingTrackPoints = [];
  final List<ActivityEvent> _pendingEvents = [];

  Timer? _ageTimer;
  Future<void>? _inFlight;
  bool _disposed = false;

  int _nextSeq;
  double _distanceM = 0;
  Duration _elapsed = Duration.zero;
  Duration _timer = Duration.zero;

  int get nextSeq => _nextSeq;

  int get pendingCount => _pendingTrackPoints.length;

  ActivityTrackPoint addPoint({
    required int timestampMs,
    required double latitude,
    required double longitude,
    required double cumulativeDistanceM,
    double? altitudeM,
    double? accuracyM,
    double? speedMps,
    bool isValid = true,
  }) {
    final point = ActivityTrackPoint(
      seq: _nextSeq++,
      timestampMs: timestampMs,
      latitude: latitude,
      longitude: longitude,
      cumulativeDistanceM: cumulativeDistanceM,
      altitudeM: altitudeM,
      accuracyM: accuracyM,
      speedMps: speedMps,
      isValid: isValid,
    );

    _pendingTrackPoints.add(point);
    _distanceM = cumulativeDistanceM;
    _scheduleAgeFlush();

    if (_pendingTrackPoints.length >= chunkSize) {
      flush();
    }

    return point;
  }

  Future<void> addEvent(ActivityEventType type, int timestampMs) {
    _pendingEvents.add(ActivityEvent(timestampMs: timestampMs, type: type));

    return flush();
  }

  void updateTotals({
    required Duration elapsed,
    required Duration timer,
    double? distanceM,
  }) {
    _elapsed = elapsed;
    _timer = timer;
    if (distanceM != null) _distanceM = distanceM;
  }

  /// Record activity data
  Future<void> flush() async {
    final previous = _inFlight;

    final next = previous == null
        ? _doFlush()
        : previous.then(
            (_) => _doFlush(),
            onError: (Object _, StackTrace _) => _doFlush(),
          );
    _inFlight = next;

    return next;
  }

  Future<void> _doFlush() async {
    final points = List<ActivityTrackPoint>.of(_pendingTrackPoints);
    final events = List<ActivityEvent>.of(_pendingEvents);

    _pendingTrackPoints.clear();
    _pendingEvents.clear();
    _ageTimer?.cancel();
    _ageTimer = null;

    try {
      await _activityDao.appendChunk(
        activityId: _activityId,
        points: points,
        events: events,
        distanceM: _distanceM,
        elapsed: _elapsed,
        timer: _timer,
      );
    } catch (_) {
      // Retry
      _pendingTrackPoints.insertAll(0, points);
      _pendingEvents.insertAll(0, events);

      rethrow;
    }
  }

  void _scheduleAgeFlush() {
    _ageTimer ??= Timer(maxBufferAge, () {
      if (!_disposed) unawaited(flush());
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    _ageTimer?.cancel();
    _ageTimer = null;

    await flush();
  }
}
