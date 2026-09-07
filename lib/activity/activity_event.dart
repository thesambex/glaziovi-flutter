enum ActivityEventType { timerStart, timerStop, lap }

class ActivityEvent {
  const ActivityEvent({
    required this.timestampMs,
    required this.type,
    required this.cumulativeDistanceM,
    required this.elapsedMs,
    required this.timerMs,
  });

  factory ActivityEvent.fromMap(Map<String, Object?> map) => ActivityEvent(
    timestampMs: map['timestamp_ms']! as int,
    type: ActivityEventType.values.byName(map['type']! as String),
    cumulativeDistanceM: (map['cumulative_distance_m']! as num).toDouble(),
    elapsedMs: map['elapsed_ms']! as int,
    timerMs: map['timer_ms']! as int,
  );

  final int timestampMs;
  final ActivityEventType type;

  /// Accumulated activity totals at the event, not per-lap totals.
  final double cumulativeDistanceM;
  final int elapsedMs;
  final int timerMs;

  Map<String, Object?> toMap(int activityId) => {
    'activity_id': activityId,
    'timestamp_ms': timestampMs,
    'type': type.name,
    'cumulative_distance_m': cumulativeDistanceM,
    'elapsed_ms': elapsedMs,
    'timer_ms': timerMs,
  };
}
