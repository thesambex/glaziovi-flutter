enum ActivitySubSportType {
  generic(0),

  // Run
  treadmill(1),
  street(2),
  trail(3),
  track(4),

  // Walk
  indoorWalking(27),
  casualWalking(30),
  speedWalking(31),

  //Cycling
  spin(5),
  indoorCycling(6),
  road(7),
  mountain(8);

  const ActivitySubSportType(this.value);

  final int value;

  static final Map<int, ActivitySubSportType> _byValue = {
    for (final e in ActivitySubSportType.values) e.value: e,
  };

  static ActivitySubSportType? fromFit(int? value) =>
      value == null ? null : _byValue[value];
}
