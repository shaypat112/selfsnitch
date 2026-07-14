import 'package:latlong2/latlong.dart';

enum DangerType { 
  schoolZone,
  highCrime,
  poorLighting,
  construction,
  accidentProne,
  highTraffic,
  custom
}

class DangerZone {
  final String id;
  final String name;
  final String description;
  final LatLng center;
  final double radius; // in meters
  final DangerType type;
  final int severity; // 1-10 scale
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  DangerZone({
    required this.id,
    required this.name,
    required this.description,
    required this.center,
    required this.radius,
    required this.type,
    this.severity = 5,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory DangerZone.fromMap(Map<String, dynamic> map) {
    return DangerZone(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      center: LatLng(
        map['latitude'] as double,
        map['longitude'] as double,
      ),
      radius: (map['radius'] as num).toDouble(),
      type: DangerType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => DangerType.custom,
      ),
      severity: (map['severity'] as num?)?.toInt() ?? 5,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': center.latitude,
      'longitude': center.longitude,
      'radius': radius,
      'type': type.toString().split('.').last,
      'severity': severity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  bool containsLocation(LatLng location) {
    final distance = const Distance();
    return distance.distance(center, location) <= radius;
  }

  DangerZone copyWith({
    String? id,
    String? name,
    String? description,
    LatLng? center,
    double? radius,
    DangerType? type,
    int? severity,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return DangerZone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      center: center ?? this.center,
      radius: radius ?? this.radius,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
