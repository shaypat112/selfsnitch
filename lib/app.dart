import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'models/user_model.dart';
import 'models/speed_violation.dart';
import 'models/danger_zone.dart';
import 'models/safety_alert.dart';
import 'models/geofence.dart';
import 'services/api_service.dart';
import 'services/location_service.dart';
import 'services/rerouting_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/teen/teen_dashboard.dart';
import 'database_helper.dart';

class SelfSnitchApp extends StatelessWidget {
  const SelfSnitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SelfSnitch - Safe Driving App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue[800],
          secondary: Colors.orange[600],
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 4,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // In a real app, check if user is logged in
    // For now, we'll simulate a logged-in state for testing
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
      // _currentUser = null; // Uncomment to test auth flow
    });
  }

  void _handleLoginSuccess() {
    // In a real app, fetch user data
    // For now, create a test user
    setState(() {
      _currentUser = UserModel(
        id: 'test_user_1',
        name: 'Test User',
        email: 'test@example.com',
        role: UserRole.teen, // Change to UserRole.parent to test parent mode
      );
    });
  }

  void _handleLogout() {
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null) {
      return LoginScreen(
        onLoginSuccess: _handleLoginSuccess,
        onNavigateToRegister: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterScreen(
                onRegisterSuccess: _handleLoginSuccess,
                onNavigateToLogin: () {
                  Navigator.pop(context);
                },
              ),
            ),
          );
        },
      );
    }

    // Show appropriate dashboard based on user role
    return _currentUser.role == UserRole.parent
        ? ParentDashboard(
            parent: _currentUser!,
          )
        : TeenDashboard(
            teen: _currentUser!,
          );
  }
}

// Legacy code for backward compatibility
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
              _violations.add(violation);
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
          ? const Center(child: Text('No violations yet - good driving!'))
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
