import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/user_model.dart';
import '../../models/safety_alert.dart';
import '../../models/danger_zone.dart';
import '../../widgets/alert_card.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class ParentDashboard extends StatefulWidget {
  final UserModel parent;

  const ParentDashboard({super.key, required this.parent});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();

  List<UserModel> _teens = [];
  List<SafetyAlert> _alerts = [];
  List<DangerZone> _dangerZones = [];
  Map<String, LatLng> _teenLocations = {};
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load teens
      final teens = await _apiService.getTeensForParent(widget.parent.id);
      
      // Load alerts
      final alerts = await _apiService.getAlerts(widget.parent.id);
      
      // Load danger zones
      final dangerZones = await _apiService.getDangerZones();
      
      // Load teen locations
      final locations = <String, LatLng>{};
      for (final teen in teens) {
        final location = await _apiService.getUserLocation(teen.id);
        if (location != null) {
          locations[teen.id] = location;
        }
      }
      
      setState(() {
        _teens = teens;
        _alerts = alerts;
        _dangerZones = dangerZones;
        _teenLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _startLocationTracking() async {
    _locationService.onLocationUpdate = (location) {
      // Update parent location
      _apiService.updateLocation(widget.parent.id, location, _locationService.currentSpeedMph);
    };
    
    try {
      await _locationService.startLocationTracking();
    } catch (e) {
      // Location tracking failed, but app can still work
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Dashboard - ${widget.parent.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    // Alerts summary
                    if (_alerts.isNotEmpty)
                      Card(
                        color: Colors.red[50],
                        elevation: 2,
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_alerts.length} Active Alert${_alerts.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to view all alerts',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Teens list
                    Expanded(
                      child: ListView.builder(
                        itemCount: _teens.length,
                        itemBuilder: (context, index) {
                          final teen = _teens[index];
                          final location = _teenLocations[teen.id];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  teen.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(teen.name),
                              subtitle: location != null
                                  ? Text(
                                      'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}',
                                    )
                                  : const Text('Location not available'),
                              trailing: IconButton(
                                icon: const Icon(Icons.map),
                                onPressed: () {
                                  _mapController.move(location ?? LatLng(0, 0), 15);
                                },
                              ),
                              onTap: () {
                                // Navigate to teen detail
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addTeen',
            onPressed: () {
              // Add new teen
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'viewMap',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParentMapScreen(
                    parent: widget.parent,
                    teens: _teens,
                    teenLocations: _teenLocations,
                    dangerZones: _dangerZones,
                  ),
                ),
              );
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.map),
          ),
        ],
      ),
    );
  }
}

class ParentMapScreen extends StatefulWidget {
  final UserModel parent;
  final List<UserModel> teens;
  final Map<String, LatLng> teenLocations;
  final List<DangerZone> dangerZones;

  const ParentMapScreen({
    super.key,
    required this.parent,
    required this.teens,
    required this.teenLocations,
    required this.dangerZones,
  });

  @override
  State<ParentMapScreen> createState() => _ParentMapScreenState();
}

class _ParentMapScreenState extends State<ParentMapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    // Find center point
    final allLocations = <LatLng>[];
    if (widget.teenLocations.isNotEmpty) {
      allLocations.addAll(widget.teenLocations.values);
    }
    
    final center = allLocations.isNotEmpty
        ? LatLng(
            allLocations.map((l) => l.latitude).reduce((a, b) => a + b) / allLocations.length,
            allLocations.map((l) => l.longitude).reduce((a, b) => a + b) / allLocations.length,
          )
        : LatLng(35.2271, -80.8431); // Default to Charlotte

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teen Locations'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.selfsnitch',
          ),
          // Danger zones
          CircleLayer(
            circles: widget.dangerZones.map((zone) {
              return CircleMarker(
                point: zone.center,
                radius: zone.radius,
                color: Colors.red.withOpacity(0.2),
                borderColor: Colors.red,
                borderStrokeWidth: 2,
              );
            }).toList(),
          ),
          // Teen locations
          MarkerLayer(
            markers: widget.teenLocations.entries.map((entry) {
              final teen = widget.teens.firstWhere(
                (t) => t.id == entry.key,
                orElse: () => UserModel(
                  id: 'unknown',
                  name: 'Unknown',
                  email: '',
                  role: UserRole.teen,
                ),
              );
              
              return Marker(
                point: entry.value,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    // Show teen info
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        teen.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
