import 'package:flutter/foundation.dart';
import 'package:glaziovi/activity/activity_sub_sport_type.dart';

import 'activity_sport_type.dart';

@immutable
class ActivitySport {
  const ActivitySport._(this.rawSport, this.rawSubSport);

  factory ActivitySport.fromFit(int? rawSport, int? rawSubSport) =>
      ActivitySport._(rawSport ?? 0, rawSubSport ?? 0);

  factory ActivitySport.of(
    ActivitySportType sport, [
    ActivitySubSportType? subSport,
  ]) => ActivitySport._(
    sport.value,
    (subSport ?? ActivitySubSportType.generic).value,
  );

  factory ActivitySport.fromJson(Map<String, dynamic> json) =>
      ActivitySport._(json['sport'] as int, json['subSport'] as int);

  static const ActivitySport unknown = ActivitySport._(0, 0);

  final int rawSport;

  final int rawSubSport;

  ActivitySportType? get sport => ActivitySportType.fromFit(rawSport);

  ActivitySubSportType? get subSport =>
      ActivitySubSportType.fromFit(rawSubSport);

  double get maxGpsSpeedMps => switch (sport) {
    ActivitySportType.walking || ActivitySportType.running => 15,
    ActivitySportType.cycling => switch (subSport) {
      ActivitySubSportType.mountain => 40,
      _ => 60,
    },
    _ => 40,
  };

  bool get isRecognized => sport != null && subSport != null;

  bool get isGeneric =>
      rawSport == ActivitySportType.generic.value &&
      rawSubSport == ActivitySubSportType.generic.value;

  String get key => '$rawSport:$rawSubSport';

  ActivitySport get withoutSubSport => ActivitySport._(rawSport, 0);

  Map<String, dynamic> toJson() => {'sport': rawSport, 'subSport': rawSubSport};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivitySport &&
          other.rawSport == rawSport &&
          other.rawSubSport == rawSubSport;

  @override
  int get hashCode => Object.hash(rawSport, rawSubSport);

  @override
  String toString() =>
      'ActivitySport(${sport?.name ?? rawSport}/${subSport?.name ?? rawSubSport})';
}
