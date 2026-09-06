class FitRecord {
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double? altitude; // Meters
  final double? speed; // m/s
  final int? heartRate; // bpm

  FitRecord({
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.altitude,
    this.speed,
    this.heartRate,
  });
}
