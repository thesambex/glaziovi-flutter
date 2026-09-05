enum ActivityRecordStatus { recording, paused, finished, aborted }

class ActivityData {
  const ActivityData({
    required this.id,
    required this.sport,
    required this.subSport,
    required this.startedAtMs,
    required this.finishedAtMs,
    required this.elapsedMs,
    required this.timerMs,
    required this.distanceM,
    required this.status,
    required this.lastSeq,
  });

  final int id;
  final int sport;
  final int subSport;
  final int startedAtMs;
  final int? finishedAtMs;

  final int elapsedMs;
  final int timerMs;

  final double distanceM;
  final ActivityRecordStatus status;
  final int lastSeq;

  ActivityData copyWith({
    int? id,
    int? sport,
    int? subSport,
    int? startedAtMs,
    int? finishedAtMs,
    bool clearFinishedAtMs = false,
    int? elapsedMs,
    int? timerMs,
    double? distanceM,
    ActivityRecordStatus? status,
    int? lastSeq,
  }) => ActivityData(
    id: id ?? this.id,
    sport: sport ?? this.sport,
    subSport: subSport ?? this.subSport,
    startedAtMs: startedAtMs ?? this.startedAtMs,
    finishedAtMs: clearFinishedAtMs
        ? null
        : finishedAtMs ?? this.finishedAtMs,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    timerMs: timerMs ?? this.timerMs,
    distanceM: distanceM ?? this.distanceM,
    status: status ?? this.status,
    lastSeq: lastSeq ?? this.lastSeq,
  );

  factory ActivityData.fromMap(Map<String, Object?> map) => ActivityData(
    id: map['id']! as int,
    sport: map['sport']! as int,
    subSport: map['sub_sport']! as int,
    startedAtMs: map['started_at_ms']! as int,
    finishedAtMs: map['finished_at_ms'] as int?,
    elapsedMs: map['elapsed_ms']! as int,
    timerMs: map['timer_ms']! as int,
    distanceM: (map['distance_m']! as num).toDouble(),
    status: ActivityRecordStatus.values.byName(map['status']! as String),
    lastSeq: map['last_seq']! as int,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'sport': sport,
    'sub_sport': subSport,
    'started_at_ms': startedAtMs,
    'finished_at_ms': finishedAtMs,
    'elapsed_ms': elapsedMs,
    'timer_ms': timerMs,
    'distance_m': distanceM,
    'status': status.name,
    'last_seq': lastSeq,
  };
}
