class FitLap {
  const FitLap({
    required this.messageIndex,
    required this.startTime,
    required this.timestamp,
    required this.totalElapsedTime,
    required this.totalTimerTime,
    required this.totalDistance,
  });

  final int messageIndex;
  final DateTime startTime;
  final DateTime timestamp;
  final int totalElapsedTime;
  final int totalTimerTime;
  final double totalDistance;
}
