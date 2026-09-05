enum ActivityEventType { timerStart, timerStop, lap }

class ActivityEvent {
  const ActivityEvent({required this.timestampMs, required this.type});

  factory ActivityEvent.fromMap(Map<String, Object?> map) => ActivityEvent(
    timestampMs: map['timestamp_ms']! as int,
    type: ActivityEventType.values.byName(map['type']! as String),
  );

  final int timestampMs;
  final ActivityEventType type;

  Map<String, Object?> toMap(int activityId) => {
    'activity_id': activityId,
    'timestamp_ms': timestampMs,
    'type': type.name,
  };
}
