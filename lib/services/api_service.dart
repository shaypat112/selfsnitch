import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/danger_zone.dart';
import '../models/safety_alert.dart';
import '../models/geofence.dart';
import '../models/route_suggestion.dart';
import 'package:latlong2/latlong.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:3000/api';
  // For production, use your server URL
  // static const String _baseUrl = 'https://your-server.com/api';
  
  final String? _authToken;
  final http.Client _client;

  ApiService({String? authToken, http.Client? client})
      : _authToken = authToken,
        _client = client ?? http.Client();

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ============ Authentication ============

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? parentId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role.toString().split('.').last,
          'parentId': parentId,
        }),
      );
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  // ============ Users ============

  Future<UserModel> getUser(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return UserModel.fromMap(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<List<UserModel>> getTeensForParent(String parentId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/users/parent/$parentId/teens'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => UserModel.fromMap(item)).toList();
      } else {
        throw Exception('Failed to get teens: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get teens: $e');
    }
  }

  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await _client.put(
        Uri.parse('$_baseUrl/users/${user.id}'),
        headers: _getHeaders(),
        body: jsonEncode(user.toMap()),
      );
      
      if (response.statusCode == 200) {
        return UserModel.fromMap(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // ============ Location Sharing ============

  Future<void> updateLocation(String userId, LatLng location, double speedMph) async {
    try {
      await _client.post(
        Uri.parse('$_baseUrl/locations/$userId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'latitude': location.latitude,
          'longitude': location.longitude,
          'speedMph': speedMph,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  Future<LatLng?> getUserLocation(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/locations/$userId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          return LatLng(
            (data['latitude'] as num).toDouble(),
            (data['longitude'] as num).toDouble(),
          );
        }
        return null;
      } else {
        throw Exception('Failed to get location: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  // ============ Danger Zones ============

  Future<List<DangerZone>> getDangerZones({LatLng? nearLocation, double? radius}) async {
    try {
      var url = '$_baseUrl/danger-zones';
      if (nearLocation != null && radius != null) {
        url += '?lat=${nearLocation.latitude}&lng=${nearLocation.longitude}&radius=$radius';
      }
      
      final response = await _client.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => DangerZone.fromMap(item)).toList();
      } else {
        throw Exception('Failed to get danger zones: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get danger zones: $e');
    }
  }

  Future<DangerZone> createDangerZone(DangerZone zone) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/danger-zones'),
        headers: _getHeaders(),
        body: jsonEncode(zone.toMap()),
      );
      
      if (response.statusCode == 201) {
        return DangerZone.fromMap(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create danger zone: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create danger zone: $e');
    }
  }

  // ============ Safety Alerts ============

  Future<List<SafetyAlert>> getAlerts(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/alerts/user/$userId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => SafetyAlert.fromMap(item)).toList();
      } else {
        throw Exception('Failed to get alerts: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get alerts: $e');
    }
  }

  Future<SafetyAlert> createAlert(SafetyAlert alert) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/alerts'),
        headers: _getHeaders(),
        body: jsonEncode(alert.toMap()),
      );
      
      if (response.statusCode == 201) {
        return SafetyAlert.fromMap(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create alert: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create alert: $e');
    }
  }

  Future<SafetyAlert> acknowledgeAlert(String alertId) async {
    try {
      final response = await _client.patch(
        Uri.parse('$_baseUrl/alerts/$alertId/acknowledge'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return SafetyAlert.fromMap(jsonDecode(response.body));
      } else {
        throw Exception('Failed to acknowledge alert: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to acknowledge alert: $e');
    }
  }

  // ============ Geofences ============

  Future<List<Geofence>> getGeofences(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/geofences/user/$userId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Geofence.fromMap(item)).toList();
      } else {
        throw Exception('Failed to get geofences: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get geofences: $e');
    }
  }

  Future<Geofence> createGeofence(Geofence geofence) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/geofences'),
        headers: _getHeaders(),
        body: jsonEncode(geofence.toMap()),
      );
      
      if (response.statusCode == 201) {
        return Geofence.fromMap(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create geofence: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create geofence: $e');
    }
  }

  Future<void> deleteGeofence(String geofenceId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/geofences/$geofenceId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete geofence: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete geofence: $e');
    }
  }

  // ============ Route Suggestions ============

  Future<RouteSuggestion> getSafeRoute({
    required String userId,
    required LatLng start,
    required LatLng end,
    List<String>? avoidDangerTypes,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/routes/safe'),
        headers: _getHeaders(),
        body: jsonEncode({
          'userId': userId,
          'startLatitude': start.latitude,
          'startLongitude': start.longitude,
          'endLatitude': end.latitude,
          'endLongitude': end.longitude,
          'avoidDangerTypes': avoidDangerTypes,
        }),
      );
      
      if (response.statusCode == 200) {
        return RouteSuggestion.fromMap(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get safe route: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get safe route: $e');
    }
  }

  // ============ Speed Violations ============

  Future<void> reportSpeedViolation({
    required String userId,
    required double speedMph,
    required LatLng location,
    String? teenId,
  }) async {
    try {
      await _client.post(
        Uri.parse('$_baseUrl/violations'),
        headers: _getHeaders(),
        body: jsonEncode({
          'userId': userId,
          'teenId': teenId,
          'speedMph': speedMph,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      throw Exception('Failed to report speed violation: $e');
    }
  }

  Future<List<dynamic>> getSpeedViolations(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/violations/user/$userId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get speed violations: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get speed violations: $e');
    }
  }

  // ============ SOS Emergency ============

  Future<void> sendSOS({
    required String userId,
    required LatLng location,
    String? message,
    String? teenId,
  }) async {
    try {
      await _client.post(
        Uri.parse('$_baseUrl/emergency/sos'),
        headers: _getHeaders(),
        body: jsonEncode({
          'userId': userId,
          'teenId': teenId,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      throw Exception('Failed to send SOS: $e');
    }
  }

  // ============ Settings ============

  Future<Map<String, dynamic>> getSettings(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/settings/$userId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get settings: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get settings: $e');
    }
  }

  Future<void> updateSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await _client.put(
        Uri.parse('$_baseUrl/settings/$userId'),
        headers: _getHeaders(),
        body: jsonEncode(settings),
      );
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
