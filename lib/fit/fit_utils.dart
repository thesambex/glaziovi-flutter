class FitUtils {
  static int degreesToSemicircles(double degrees) {
    return (degrees * (1 << 31) / 180).round();
  }

  static int toGarminTimestamp(DateTime dateTime) {
    final garminEpoch = DateTime.utc(1989, 12, 31);
    return dateTime.toUtc().difference(garminEpoch).inSeconds;
  }
}
