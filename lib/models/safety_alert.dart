import 'package:latlong2/latlong.dart';

enum AlertType {
  speeding,
  dangerZoneEntered,
  dangerZoneApproaching,
  geofenceExit,
  sos,
  lowBattery,
  nightDriving,
  custom
}

enum AlertStatus { active, acknowledged, resolved }

class SafetyAlert {
  final String id;
  final String userId;
  final String? teenId; // If parent is receiving alert about teen
  final AlertType type;
  final AlertStatus status;
  final String title;
  final String message;
  final LatLng? location;
  final double? speedMph;
  final DateTime timestamp;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final Map<String, dynamic>? metadata;

  SafetyAlert({
    required this.id,
    required this.userId,
    this.teenId,
    required this.type,
    this.status = AlertStatus.active,
    required this.title,
    required this.message,
    this.location,
    this.speedMph,
    DateTime? timestamp,
    this.acknowledgedAt,
    this.resolvedAt,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SafetyAlert.fromMap(Map<String, dynamic> map) {
    return SafetyAlert(
      id: map['id'] as String,
      userId: map['userId'] as String,
      teenId: map['teenId'] as String?,
      type: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => AlertType.custom,
      ),
      status: AlertStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => AlertStatus.active,
      ),
      title: map['title'] as String,
      message: map['message'] as String,
      location: map['latitude'] != null && map['longitude'] != null
          ? LatLng(
              (map['latitude'] as num).toDouble(),
              (map['longitude'] as num).toDouble(),
            )
          : null,
      speedMph: (map['speedMph'] as num?)?.toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? ''),
      acknowledgedAt: DateTime.tryParse(map['acknowledgedAt'] as String? ?? ''),
      resolvedAt: DateTime.tryParse(map['resolvedAt'] as String? ?? ''),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'userId': userId,
      'teenId': teenId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
    
    if (location != null) {
      map['latitude'] = location!.latitude;
      map['longitude'] = location!.longitude;
    }
    if (speedMph != null) map['speedMph'] = speedMph;
    if (acknowledgedAt != null) map['acknowledgedAt'] = acknowledgedAt!.toIso8601String();
    if (resolvedAt != null) map['resolvedAt'] = resolvedAt!.toIso8601String();
    
    return map;
  }

  SafetyAlert copyWith({
    String? id,
    String? userId,
    String? teenId,
    AlertType? type,
    AlertStatus? status,
    String? title,
    String? message,
    LatLng? location,
    double? speedMph,
    DateTime? timestamp,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    Map<String, dynamic>? metadata,
  }) {
    return SafetyAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      teenId: teenId ?? this.teenId,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      message: message ?? this.message,
      location: location ?? this.location,
      speedMph: speedMph ?? this.speedMph,
      timestamp: timestamp ?? this.timestamp,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
