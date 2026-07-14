import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'models/speed_violation.dart';
import 'database_helper.dart';

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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static final LatLng charlotte = LatLng(35.2271, -80.8431);
  static const double maxSpeedMph = 80.0;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final List<SpeedViolation> _violations = [];

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation;
  double _speedMph = 0.0;
  bool _isSpeeding = false;

  @override
  void initState() {
    super.initState();
    _loadSavedViolations();
    _startTrackingLocation();
  }

  Future<void> _loadSavedViolations() async {
    final saved = await _dbHelper.getAllViolations();
    setState(() {
      _violations.addAll(saved);
    });
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

            if (isSpeedingNow && !_isSpeeding) {
              final violation = SpeedViolation(
                timestamp: DateTime.now(),
                speedMph: speedMph,
                location: newLocation,
              );
              // Update the on-screen list immediately, so the badge count and
              // history screen feel instant...
              _violations.add(violation);
              // ...while the actual disk write happens in the background. We
              // don't `await` this — we don't want a slow disk write to freeze
              // the UI thread for even a moment. This is called an "optimistic
              // update": trust that the save will succeed, update the UI now,
              // and let the save happen quietly behind it.
              _dbHelper.insertViolation(violation);
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ViolationHistoryScreen(violations: _violations),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Badge(
                  label: Text('${_violations.length}'),
                  isLabelVisible: _violations.isNotEmpty,
                  child: const Icon(Icons.warning_amber_rounded),
                ),
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

class ViolationHistoryScreen extends StatelessWidget {
  final List<SpeedViolation> violations;

  const ViolationHistoryScreen({super.key, required this.violations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speed Violations')),
      body: violations.isEmpty
          ? const Center(child: Text('No violations yet — good driving!'))
          : ListView.builder(
              itemCount: violations.length,
              itemBuilder: (context, index) {
                final violation = violations[violations.length - 1 - index];
                return ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                  ),
                  title: Text('${violation.speedMph.toStringAsFixed(0)} mph'),
                  subtitle: Text(
                    '${DateFormat.yMMMd().add_jm().format(violation.timestamp)}\n'
                    '${violation.location.latitude.toStringAsFixed(4)}, '
                    '${violation.location.longitude.toStringAsFixed(4)}',
                  ),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}
