import 'package:latlong2/latlong.dart';

class Geofence {
  final String id;
  final String name;
  final String description;
  final LatLng center;
  final double radius; // in meters
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool notifyOnEntry;
  final bool notifyOnExit;

  Geofence({
    required this.id,
    required this.name,
    required this.description,
    required this.center,
    required this.radius,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
    this.notifyOnEntry = true,
    this.notifyOnExit = true,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Geofence.fromMap(Map<String, dynamic> map) {
    return Geofence(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      center: LatLng(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      ),
      radius: (map['radius'] as num).toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      isActive: (map['isActive'] as bool?) ?? true,
      notifyOnEntry: (map['notifyOnEntry'] as bool?) ?? true,
      notifyOnExit: (map['notifyOnExit'] as bool?) ?? true,
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'notifyOnEntry': notifyOnEntry,
      'notifyOnExit': notifyOnExit,
    };
  }

  bool containsLocation(LatLng location) {
    final distance = const Distance();
    return distance.distance(center, location) <= radius;
  }

  Geofence copyWith({
    String? id,
    String? name,
    String? description,
    LatLng? center,
    double? radius,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? notifyOnEntry,
    bool? notifyOnExit,
  }) {
    return Geofence(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      center: center ?? this.center,
      radius: radius ?? this.radius,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      notifyOnEntry: notifyOnEntry ?? this.notifyOnEntry,
      notifyOnExit: notifyOnExit ?? this.notifyOnExit,
    );
  }
}
