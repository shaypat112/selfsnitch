import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/user_model.dart';
import '../../models/safety_alert.dart';
import '../../models/danger_zone.dart';
import '../../models/geofence.dart';
import '../../widgets/speedometer.dart';
import '../../widgets/danger_indicator.dart';
import '../../widgets/sos_button.dart';
import '../../widgets/alert_card.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/rerouting_service.dart';

class TeenDashboard extends StatefulWidget {
  final UserModel teen;

  const TeenDashboard({super.key, required this.teen});

  @override
  State<TeenDashboard> createState() => _TeenDashboardState();
}

class _TeenDashboardState extends State<TeenDashboard> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  final ReroutingService _reroutingService = ReroutingService();

  LatLng? _currentLocation;
  double _currentSpeedMph = 0.0;
  bool _isSpeeding = false;
  List<DangerZone> _dangerZones = [];
  List<DangerZone> _currentDangerZones = [];
  List<Geofence> _geofences = [];
  List<SafetyAlert> _alerts = [];
  bool _isRerouting = false;
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupLocationTracking();
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load danger zones
      final dangerZones = await _apiService.getDangerZones();
      
      // Load geofences
      final geofences = await _apiService.getGeofences(widget.teen.id);
      
      // Load alerts
      final alerts = await _apiService.getAlerts(widget.teen.id);
      
      setState(() {
        _dangerZones = dangerZones;
        _geofences = geofences;
        _alerts = alerts;
        _locationService.setDangerZones(dangerZones);
        _locationService.setGeofences(geofences);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  void _setupLocationTracking() {
    _locationService.onLocationUpdate = (location) {
      setState(() {
        _currentLocation = location;
      });
      
      // Update location on server
      _apiService.updateLocation(
        widget.teen.id,
        location,
        _locationService.currentSpeedMph,
      );
      
      // Check if we need to reroute
      _checkForRerouting();
    };

    _locationService.onSpeedUpdate = (speed) {
      setState(() {
        _currentSpeedMph = speed;
        _isSpeeding = speed > 80.0; // Default speed limit
      });
      
      // Check for speeding violation
      if (speed > 80.0) {
        _createSpeedingAlert(speed);
      }
    };

    _locationService.onDangerZoneEntered = (zone) {
      setState(() {
        _currentDangerZones.add(zone);
      });
      _createDangerZoneAlert(zone, true);
    };

    _locationService.onDangerZoneExited = (zone) {
      setState(() {
        _currentDangerZones.removeWhere((z) => z.id == zone.id);
      });
      _createDangerZoneAlert(zone, false);
    };

    _locationService.onGeofenceCrossed = (geofence, entered) {
      if (!entered) {
        // Geofence exit
        _createGeofenceAlert(geofence);
      }
    };

    _locationService.startLocationTracking().then((_) {
      setState(() {
        _currentLocation = _locationService.currentLocation;
        _currentSpeedMph = _locationService.currentSpeedMph;
      });
    }).catchError((e) {
      setState(() {
        _errorMessage = 'Location tracking failed: $e';
      });
    });
  }

  void _checkForRerouting() {
    if (_currentLocation == null) return;
    
    // In a real app, we would have a destination
    // For now, just check if we're in a danger zone
    if (_currentDangerZones.isNotEmpty && !_isRerouting) {
      setState(() {
        _isRerouting = true;
      });
      
      // Simulate rerouting
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _isRerouting = false;
        });
      });
    }
  }

  Future<void> _createSpeedingAlert(double speed) async {
    final alert = SafetyAlert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.teen.id,
      teenId: widget.teen.id,
      type: AlertType.speeding,
      title: 'Speeding Alert',
      message: 'You are driving at ${speed.toStringAsFixed(0)} mph, which exceeds the speed limit!',
      location: _currentLocation,
      speedMph: speed,
    );
    
    try {
      await _apiService.createAlert(alert);
      setState(() {
        _alerts.insert(0, alert);
      });
    } catch (e) {
      // Alert creation failed, but we can still show it locally
      setState(() {
        _alerts.insert(0, alert);
      });
    }
  }

  Future<void> _createDangerZoneAlert(DangerZone zone, bool entered) async {
    final alert = SafetyAlert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.teen.id,
      teenId: widget.teen.id,
      type: entered ? AlertType.dangerZoneEntered : AlertType.dangerZoneApproaching,
      title: entered ? 'Danger Zone Entered' : 'Danger Zone Approaching',
      message: '${entered ? 'Entered' : 'Approaching'} ${zone.type.toString().split('.').last} zone: ${zone.name}',
      location: zone.center,
    );
    
    try {
      await _apiService.createAlert(alert);
      setState(() {
        _alerts.insert(0, alert);
      });
    } catch (e) {
      setState(() {
        _alerts.insert(0, alert);
      });
    }
  }

  Future<void> _createGeofenceAlert(Geofence geofence) async {
    final alert = SafetyAlert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.teen.id,
      teenId: widget.teen.id,
      type: AlertType.geofenceExit,
      title: 'Geofence Exit',
      message: 'You have exited the geofence: ${geofence.name}',
      location: geofence.center,
    );
    
    try {
      await _apiService.createAlert(alert);
      setState(() {
        _alerts.insert(0, alert);
      });
    } catch (e) {
      setState(() {
        _alerts.insert(0, alert);
      });
    }
  }

  Future<void> _sendSOS() async {
    if (_currentLocation == null) return;
    
    try {
      await _apiService.sendSOS(
        userId: widget.teen.id,
        location: _currentLocation!,
        message: 'Emergency! Please help!',
        teenId: widget.teen.id,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS sent! Help is on the way.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send SOS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    try {
      final updatedAlert = await _apiService.acknowledgeAlert(alertId);
      setState(() {
        final index = _alerts.indexWhere((a) => a.id == alertId);
        if (index != -1) {
          _alerts[index] = updatedAlert;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to acknowledge alert: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teen Dashboard - ${widget.teen.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlertsScreen(
                    alerts: _alerts,
                    onAcknowledge: _acknowledgeAlert,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Stack(
                  children: [
                    // Map
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation ?? LatLng(35.2271, -80.8431),
                        initialZoom: 15,
                        center: _currentLocation,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.selfsnitch',
                        ),
                        // Danger zones
                        CircleLayer(
                          circles: _dangerZones.map((zone) {
                            return CircleMarker(
                              point: zone.center,
                              radius: zone.radius,
                              color: Colors.red.withOpacity(0.2),
                              borderColor: Colors.red,
                              borderStrokeWidth: 2,
                            );
                          }).toList(),
                        ),
                        // Geofences
                        CircleLayer(
                          circles: _geofences.map((geofence) {
                            return CircleMarker(
                              point: geofence.center,
                              radius: geofence.radius,
                              color: Colors.blue.withOpacity(0.2),
                              borderColor: Colors.blue,
                              borderStrokeWidth: 2,
                            );
                          }).toList(),
                        ),
                        // Current location
                        if (_currentLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentLocation!,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    // Speedometer
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Speedometer(
                        speedMph: _currentSpeedMph,
                        maxSpeed: 80.0,
                        isSpeeding: _isSpeeding,
                      ),
                    ),
                    
                    // Danger indicator
                    Positioned(
                      top: 16,
                      right: 16,
                      child: DangerIndicator(
                        currentDangers: _currentDangerZones,
                        isRerouting: _isRerouting,
                      ),
                    ),
                    
                    // SOS Button
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: SOSButton(
                        onPressed: _sendSOS,
                        label: 'Emergency',
                      ),
                    ),
                  ],
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'geofence',
            onPressed: () {
              // Add geofence
            },
            backgroundColor: Colors.purple,
            child: const Icon(Icons.add_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'navigate',
            onPressed: () {
              // Start navigation
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.navigation),
          ),
        ],
      ),
    );
  }
}

class AlertsScreen extends StatelessWidget {
  final List<SafetyAlert> alerts;
  final Function(String) onAcknowledge;

  const AlertsScreen({
    super.key,
    required this.alerts,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Alerts'),
      ),
      body: alerts.isEmpty
          ? const Center(
              child: Text(
                'No alerts',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return AlertCard(
                  alert: alert,
                  onAcknowledge: alert.status == AlertStatus.active
                      ? () => onAcknowledge(alert.id)
                      : null,
                );
              },
            ),
    );
  }
}
