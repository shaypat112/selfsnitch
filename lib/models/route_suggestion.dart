import 'package:latlong2/latlong.dart';

class RouteSuggestion {
  final String id;
  final String userId;
  final LatLng start;
  final LatLng end;
  final List<LatLng> waypoints;
  final double distance; // in meters
  final double duration; // in seconds
  final double safetyScore; // 0-100
  final List<String> avoidedDangers;
  final List<String> warnings;
  final DateTime createdAt;

  RouteSuggestion({
    required this.id,
    required this.userId,
    required this.start,
    required this.end,
    required this.waypoints,
    required this.distance,
    required this.duration,
    required this.safetyScore,
    this.avoidedDangers = const [],
    this.warnings = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RouteSuggestion.fromMap(Map<String, dynamic> map) {
    final waypoints = (map['waypoints'] as List<dynamic>?)
        ?.map((w) => LatLng(
              (w['latitude'] as num).toDouble(),
              (w['longitude'] as num).toDouble(),
            ))
        .toList() ?? [];
    
    final avoidedDangers = (map['avoidedDangers'] as List<dynamic>?)
        ?.map((d) => d as String)
        .toList() ?? [];
    
    final warnings = (map['warnings'] as List<dynamic>?)
        ?.map((w) => w as String)
        .toList() ?? [];

    return RouteSuggestion(
      id: map['id'] as String,
      userId: map['userId'] as String,
      start: LatLng(
        (map['startLatitude'] as num).toDouble(),
        (map['startLongitude'] as num).toDouble(),
      ),
      end: LatLng(
        (map['endLatitude'] as num).toDouble(),
        (map['endLongitude'] as num).toDouble(),
      ),
      waypoints: waypoints,
      distance: (map['distance'] as num).toDouble(),
      duration: (map['duration'] as num).toDouble(),
      safetyScore: (map['safetyScore'] as num).toDouble(),
      avoidedDangers: avoidedDangers,
      warnings: warnings,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startLatitude': start.latitude,
      'startLongitude': start.longitude,
      'endLatitude': end.latitude,
      'endLongitude': end.longitude,
      'waypoints': waypoints
          .map((w) => {'latitude': w.latitude, 'longitude': w.longitude})
          .toList(),
      'distance': distance,
      'duration': duration,
      'safetyScore': safetyScore,
      'avoidedDangers': avoidedDangers,
      'warnings': warnings,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  RouteSuggestion copyWith({
    String? id,
    String? userId,
    LatLng? start,
    LatLng? end,
    List<LatLng>? waypoints,
    double? distance,
    double? duration,
    double? safetyScore,
    List<String>? avoidedDangers,
    List<String>? warnings,
    DateTime? createdAt,
  }) {
    return RouteSuggestion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      start: start ?? this.start,
      end: end ?? this.end,
      waypoints: waypoints ?? this.waypoints,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      safetyScore: safetyScore ?? this.safetyScore,
      avoidedDangers: avoidedDangers ?? this.avoidedDangers,
      warnings: warnings ?? this.warnings,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
