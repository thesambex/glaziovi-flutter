class ActivitySummary {
  const ActivitySummary({
    required this.id,
    required this.name,
    required this.activityDataId,
    required this.isSynced,
  });

  final int id;
  final String name;
  final bool isSynced;
  final int activityDataId;

  factory ActivitySummary.fromMap(Map<String, Object?> map) => ActivitySummary(
    id: map['id']! as int,
    name: map['activity_name']! as String,
    activityDataId: map['activity_data_id']! as int,
    isSynced: (map['is_synced']! as int) == 1,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'activity_name': name,
    'activity_data_id': activityDataId,
    'is_synced': isSynced ? 1 : 0,
  };
}
