import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const SelfSnitchApp());
}

class SelfSnitchApp extends StatelessWidget {
  const SelfSnitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'SelfSnitch', home: const MapScreen());
  }
}

class SpeedViolation {
  final DateTime timestamp;
  final double speedMph;
  final LatLng location;

  SpeedViolation({
    required this.timestamp,
    required this.speedMph,
    required this.location,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static final LatLng charlotte = LatLng(35.2271, -80.8431);

  // TODO: eventually fetch the real speed limit for the current road from
  // an API based on location, instead of one fixed value for the whole trip.
  static const double maxSpeedMph = 90.0;

  final List<SpeedViolation> _violations = [];

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation;
  double _speedMph = 0.0;
  bool _isSpeeding = false;

  @override
  void initState() {
    super.initState();
    _startTrackingLocation();
  }

  Future<void> _startTrackingLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          final newLocation = LatLng(position.latitude, position.longitude);

          final rawSpeedMps = position.speed < 0 ? 0.0 : position.speed;
          final speedMph = rawSpeedMps * 2.23694;
          final isSpeedingNow = speedMph > maxSpeedMph;

          setState(() {
            _currentLocation = newLocation;
            _speedMph = speedMph;

            // Edge detection: only log the moment a violation *begins* — the
            // transition from not-speeding to speeding — not every single GPS
            // update while still over the limit. Without this check, one hard
            // press on the highway would log dozens of "violations" per second.
            if (isSpeedingNow && !_isSpeeding) {
              _violations.add(
                SpeedViolation(
                  timestamp: DateTime.now(),
                  speedMph: speedMph,
                  location: newLocation,
                ),
              );
            }

            _isSpeeding = isSpeedingNow;
          });

          _mapController.move(newLocation, _mapController.camera.zoom);
        });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SelfSnitch'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Badge(
                label: Text('${_violations.length}'),
                isLabelVisible: _violations.isNotEmpty,
                child: const Icon(Icons.warning_amber_rounded),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: charlotte, initialZoom: 12),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.selfsnitch',
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.circle,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Card(
              color: _isSpeeding ? Colors.red : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_speedMph.toStringAsFixed(0)} mph',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _isSpeeding ? Colors.white : Colors.black,
                      ),
                    ),
                    if (_isSpeeding)
                      const Text(
                        'OVER LIMIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
