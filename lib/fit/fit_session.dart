class FitSession {
  FitSession({
    required this.startTime,
    required this.timestamp,
    required this.totalElapsedTime,
    required this.totalTimerTime,
    required this.totalDistance,
    this.totalCalories,
    this.avgSpeed,
    this.maxSpeed,
    this.avgHeartRate,
    this.maxHeartRate,
    this.sport = 1,
    this.subSport = 0,
  });

  final DateTime startTime;
  final DateTime timestamp;
  final int totalElapsedTime;
  final int totalTimerTime;
  final double totalDistance;
  final int? totalCalories;
  final double? avgSpeed;
  final double? maxSpeed;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final int sport;
  final int subSport;
}
