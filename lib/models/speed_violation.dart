import 'package:latlong2/latlong.dart';

class SpeedViolation {
  final int? id;
  final DateTime timestamp;
  final double speedMph;
  final LatLng location;

  SpeedViolation({
    this.id,
    required this.timestamp,
    required this.speedMph,
    required this.location,
  });

  // Converts this object into the Map format sqflite needs to insert a row.
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'speedMph': speedMph,
      'latitude': location.latitude,
      'longitude': location.longitude,
    };
  }

  // The reverse: takes a row read back out of the database and rebuilds
  // a real SpeedViolation object from it.
  factory SpeedViolation.fromMap(Map<String, dynamic> map) {
    return SpeedViolation(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      speedMph: map['speedMph'] as double,
      location: LatLng(map['latitude'] as double, map['longitude'] as double),
    );
  }
}
