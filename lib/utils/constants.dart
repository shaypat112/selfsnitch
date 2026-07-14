import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// App Constants
class AppConstants {
  static const String appName = 'SelfSnitch';
  static const String appVersion = '2.0.0';
  static const String appDescription = 'Safe Driving App for Teens and Parents';
  
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:3000/api';
  // static const String apiBaseUrl = 'https://your-production-server.com/api';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Default Location (Charlotte, NC)
  static const LatLng defaultLocation = LatLng(35.2271, -80.8431);
  static const double defaultZoom = 13.0;
  
  // Speed Limits
  static const double defaultSpeedLimit = 80.0; // mph
  static const double warningSpeedThreshold = 70.0; // mph
  static const double schoolZoneSpeedLimit = 20.0; // mph
  static const double residentialSpeedLimit = 30.0; // mph
  
  // Danger Zone Configuration
  static const double dangerZoneWarningDistance = 200.0; // meters
  static const double dangerZoneEnterDistance = 50.0; // meters
  
  // Geofence Configuration
  static const double defaultGeofenceRadius = 500.0; // meters
  static const double minGeofenceRadius = 10.0; // meters
  static const double maxGeofenceRadius = 10000.0; // meters
  
  // Alert Configuration
  static const Duration alertAutoDismissDuration = Duration(minutes: 5);
  static const int maxAlertsToShow = 50;
  
  // Location Update Configuration
  static const Duration locationUpdateInterval = Duration(seconds: 5);
  static const double locationUpdateDistance = 10.0; // meters
  
  // Map Configuration
  static const String mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapUserAgent = 'com.example.selfsnitch';
  static const int maxMapZoom = 19;
  static const int minMapZoom = 10;
  
  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color dangerColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Danger Zone Types and Colors
  static const Map<String, Color> dangerZoneColors = {
    'schoolZone': Color(0xFFFF9800),
    'highCrime': Color(0xFFF44336),
    'poorLighting': Color(0xFFFFEB3B),
    'construction': Color(0xFFFF5722),
    'accidentProne': Color(0xFFE91E63),
    'highTraffic': Color(0xFF9C27B0),
    'custom': Color(0xFF2196F3),
  };
  
  // Alert Types and Icons
  static const Map<String, IconData> alertIcons = {
    'speeding': Icons.speed,
    'dangerZoneEntered': Icons.warning_amber,
    'dangerZoneApproaching': Icons.warning_amber,
    'geofenceExit': Icons.exit_to_app,
    'sos': Icons.sos,
    'lowBattery': Icons.battery_alert,
    'nightDriving': Icons.nightlight_round,
    'custom': Icons.notification_important,
  };
  
  // Storage Keys
  static const String storageUserTokenKey = 'user_token';
  static const String storageUserIdKey = 'user_id';
  static const String storageUserRoleKey = 'user_role';
  static const String storageUserEmailKey = 'user_email';
  static const String storageUserNameKey = 'user_name';
  static const String storageSettingsKey = 'user_settings';
  
  // Error Messages
  static const String errorLocationDisabled = 'Location services are disabled';
  static const String errorLocationPermission = 'Location permission denied';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorAuthentication = 'Authentication failed. Please login again.';
  
  // Success Messages
  static const String successLogin = 'Login successful';
  static const String successRegister = 'Registration successful';
  static const String successLogout = 'Logout successful';
  static const String successProfileUpdate = 'Profile updated successfully';
  static const String successSettingsUpdate = 'Settings updated successfully';
  
  // Validation Messages
  static const String validationEmailRequired = 'Email is required';
  static const String validationEmailInvalid = 'Please enter a valid email address';
  static const String validationPasswordRequired = 'Password is required';
  static const String validationPasswordShort = 'Password must be at least 6 characters';
  static const String validationNameRequired = 'Name is required';
  static const String validationConfirmPasswordMatch = 'Passwords do not match';
}

// Helper Functions
class AppHelpers {
  // Format speed in mph
  static String formatSpeed(double speedMph) {
    return '${speedMph.toStringAsFixed(0)} mph';
  }
  
  // Format distance in meters or miles
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      final miles = meters * 0.000621371;
      return '${miles.toStringAsFixed(2)} miles';
    }
  }
  
  // Format duration in seconds to readable string
  static String formatDuration(double seconds) {
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(0)} sec';
    } else if (seconds < 3600) {
      final minutes = seconds / 60;
      return '${minutes.toStringAsFixed(0)} min';
    } else {
      final hours = seconds / 3600;
      final minutes = (seconds % 3600) / 60;
      return '${hours.toStringAsFixed(0)}h ${minutes.toStringAsFixed(0)}m';
    }
  }
  
  // Calculate distance between two points
  static double calculateDistance(LatLng start, LatLng end) {
    const distance = const Distance();
    return distance.distance(start, end);
  }
  
  // Check if a location is within a radius of another location
  static bool isWithinRadius(LatLng center, LatLng point, double radius) {
    return calculateDistance(center, point) <= radius;
  }
  
  // Get danger zone color based on type
  static Color getDangerZoneColor(String type) {
    return AppConstants.dangerZoneColors[type] ?? AppConstants.primaryColor;
  }
  
  // Get alert icon based on type
  static IconData getAlertIcon(String type) {
    return AppConstants.alertIcons[type] ?? Icons.notification_important;
  }
  
  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
  
  // Generate a unique ID
  static String generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${(1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString()}';
  }
}

// Danger Zone Data (Sample data for testing)
class SampleDangerZones {
  static final List<Map<String, dynamic>> zones = [
    {
      'name': 'Central High School Zone',
      'description': 'School zone with reduced speed limit',
      'latitude': 35.2271,
      'longitude': -80.8431,
      'radius': 200.0,
      'type': 'schoolZone',
      'severity': 8,
      'isActive': true
    },
    {
      'name': 'Downtown Construction',
      'description': 'Road construction area',
      'latitude': 35.2280,
      'longitude': -80.8440,
      'radius': 150.0,
      'type': 'construction',
      'severity': 7,
      'isActive': true
    },
    {
      'name': 'High Crime Area',
      'description': 'Area with high crime rate',
      'latitude': 35.2250,
      'longitude': -80.8450,
      'radius': 300.0,
      'type': 'highCrime',
      'severity': 9,
      'isActive': true
    },
    {
      'name': 'Poor Lighting Street',
      'description': 'Street with inadequate lighting',
      'latitude': 35.2290,
      'longitude': -80.8420,
      'radius': 250.0,
      'type': 'poorLighting',
      'severity': 6,
      'isActive': true
    },
  ];
}
