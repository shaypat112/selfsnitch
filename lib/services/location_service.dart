import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../models/danger_zone.dart';
import '../models/geofence.dart';

class LocationService {
  final List<DangerZone> _dangerZones = [];
  final List<Geofence> _geofences = [];
  
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation;
  double _currentSpeedMph = 0.0;
  double _currentHeading = 0.0;
  DateTime? _lastUpdate;

  // Callbacks for events
  Function(LatLng)? onLocationUpdate;
  Function(double)? onSpeedUpdate;
  Function(DangerZone)? onDangerZoneEntered;
  Function(DangerZone)? onDangerZoneExited;
  Function(Geofence, bool)? onGeofenceCrossed; // bool: true = entered, false = exited
  Function(double, LatLng)? onSpeeding;

  // State for tracking
  final Set<String> _currentDangerZones = {};
  final Set<String> _currentGeofences = {};

  LatLng? get currentLocation => _currentLocation;
  double get currentSpeedMph => _currentSpeedMph;
  double get currentHeading => _currentHeading;

  void setDangerZones(List<DangerZone> zones) {
    _dangerZones.clear();
    _dangerZones.addAll(zones);
  }

  void setGeofences(List<Geofence> geofences) {
    _geofences.clear();
    _geofences.addAll(geofences);
  }

  Future<void> startLocationTracking() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check and request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    // Get initial position
    Position initialPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
    
    _updateLocation(initialPosition);

    // Start listening to position updates
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
      timeInterval: Duration(seconds: 5), // Or every 5 seconds
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _updateLocation(position);
    });
  }

  void _updateLocation(Position position) {
    final newLocation = LatLng(position.latitude, position.longitude);
    final rawSpeedMps = position.speed < 0 ? 0.0 : position.speed;
    final speedMph = rawSpeedMps * 2.23694;
    final heading = position.heading < 0 ? 0.0 : position.heading;

    _currentLocation = newLocation;
    _currentSpeedMph = speedMph;
    _currentHeading = heading;
    _lastUpdate = DateTime.now();

    // Notify location update
    onLocationUpdate?.call(newLocation);
    onSpeedUpdate?.call(speedMph);

    // Check danger zones
    _checkDangerZones(newLocation);
    
    // Check geofences
    _checkGeofences(newLocation);
  }

  void _checkDangerZones(LatLng location) {
    final newDangerZones = <String>{};
    
    for (final zone in _dangerZones) {
      if (zone.isActive && zone.containsLocation(location)) {
        newDangerZones.add(zone.id);
        
        // Check if this is a new danger zone entry
        if (!_currentDangerZones.contains(zone.id)) {
          onDangerZoneEntered?.call(zone);
        }
      }
    }

    // Check for exited danger zones
    for (final zoneId in _currentDangerZones) {
      if (!newDangerZones.contains(zoneId)) {
        final exitedZone = _dangerZones.firstWhere(
          (z) => z.id == zoneId,
          orElse: () => null,
        );
        if (exitedZone != null) {
          onDangerZoneExited?.call(exitedZone);
        }
      }
    }

    _currentDangerZones.clear();
    _currentDangerZones.addAll(newDangerZones);
  }

  void _checkGeofences(LatLng location) {
    final newGeofences = <String>{};
    
    for (final geofence in _geofences) {
      if (geofence.isActive && geofence.containsLocation(location)) {
        newGeofences.add(geofence.id);
      }
    }

    // Check for crossed geofences
    for (final geofenceId in newGeofences) {
      if (!_currentGeofences.contains(geofenceId)) {
        // Entered geofence
        final enteredGeofence = _geofences.firstWhere(
          (g) => g.id == geofenceId,
          orElse: () => null,
        );
        if (enteredGeofence != null && enteredGeofence.notifyOnEntry) {
          onGeofenceCrossed?.call(enteredGeofence, true);
        }
      }
    }

    for (final geofenceId in _currentGeofences) {
      if (!newGeofences.contains(geofenceId)) {
        // Exited geofence
        final exitedGeofence = _geofences.firstWhere(
          (g) => g.id == geofenceId,
          orElse: () => null,
        );
        if (exitedGeofence != null && exitedGeofence.notifyOnExit) {
          onGeofenceCrossed?.call(exitedGeofence, false);
        }
      }
    }

    _currentGeofences.clear();
    _currentGeofences.addAll(newGeofences);
  }

  bool isInDangerZone() => _currentDangerZones.isNotEmpty;
  
  List<DangerZone> getCurrentDangerZones() {
    return _dangerZones
        .where((z) => _currentDangerZones.contains(z.id))
        .toList();
  }

  bool isInGeofence() => _currentGeofences.isNotEmpty;
  
  List<Geofence> getCurrentGeofences() {
    return _geofences
        .where((g) => _currentGeofences.contains(g.id))
        .toList();
  }

  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<double> calculateDistance(LatLng start, LatLng end) async {
    final distance = const Distance();
    return distance.distance(start, end);
  }

  Future<LatLng?> getCurrentLocationOnce() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    stopLocationTracking();
  }
}
