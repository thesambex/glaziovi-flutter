enum ActivitySportType {
  generic(0),
  running(1),
  cycling(2),
  fitnessEquipment(4),
  walking(11);

  const ActivitySportType(this.value);

  final int value;

  static final Map<int, ActivitySportType> _byValue = {
    for (final e in ActivitySportType.values) e.value: e,
  };

  static ActivitySportType? fromFit(int? value) =>
      value == null ? null : _byValue[value];
}
