class ActivityTrackPoint {
  const ActivityTrackPoint({
    required this.seq,
    required this.timestampMs,
    required this.latitude,
    required this.longitude,
    required this.cumulativeDistanceM,
    this.altitudeM,
    this.accuracyM,
    this.speedMps,
    this.isValid = true,
  });

  final int seq;

  /// GPS timestamp
  final int timestampMs;

  final double latitude;
  final double longitude;
  final double cumulativeDistanceM;
  final double? altitudeM;
  final double? accuracyM;
  final double? speedMps;

  final bool isValid;

  factory ActivityTrackPoint.fromMap(Map<String, Object?> map) =>
      ActivityTrackPoint(
        seq: map['seq']! as int,
        timestampMs: map['timestamp_ms']! as int,
        latitude: (map['latitude']! as num).toDouble(),
        longitude: (map['longitude']! as num).toDouble(),
        cumulativeDistanceM: (map['cumulative_distance_m']! as num).toDouble(),
        altitudeM: (map['altitude_m'] as num?)?.toDouble(),
        accuracyM: (map['accuracy_m'] as num?)?.toDouble(),
        speedMps: (map['speed_mps'] as num?)?.toDouble(),
        isValid: (map['is_valid']! as int) == 1,
      );

  Map<String, Object?> toMap(int activityId) => {
    'activity_id': activityId,
    'seq': seq,
    'timestamp_ms': timestampMs,
    'latitude': latitude,
    'longitude': longitude,
    'altitude_m': altitudeM,
    'accuracy_m': accuracyM,
    'speed_mps': speedMps,
    'cumulative_distance_m': cumulativeDistanceM,
    'is_valid': isValid ? 1 : 0,
  };
}
