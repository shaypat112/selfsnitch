import 'package:latlong2/latlong.dart';
import '../models/danger_zone.dart';
import '../models/route_suggestion.dart';

class ReroutingService {
  final List<DangerZone> _dangerZones;
  final double _maxSpeedMph;
  final double _safeDistanceFromDanger; // meters

  ReroutingService({
    List<DangerZone>? dangerZones,
    double maxSpeedMph = 80.0,
    double safeDistanceFromDanger = 100.0,
  }) : _dangerZones = dangerZones ?? [],
       _maxSpeedMph = maxSpeedMph,
       _safeDistanceFromDanger = safeDistanceFromDanger;

  Future<RouteSuggestion> calculateSafeRoute({
    required LatLng start,
    required LatLng end,
    required String userId,
    List<String>? avoidDangerTypes,
  }) async {
    // In a real implementation, this would call a routing API
    // For now, we'll simulate a simple route calculation
    
    final distance = const Distance();
    final directDistance = distance.distance(start, end);
    
    // Check if direct route passes through danger zones
    final dangersOnRoute = _checkDangersOnRoute(start, end);
    
    // Calculate waypoints that avoid danger zones
    final waypoints = _calculateWaypoints(start, end, dangersOnRoute);
    
    // Calculate route metrics
    double totalDistance = 0.0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      totalDistance += distance.distance(waypoints[i], waypoints[i + 1]);
    }
    
    // Estimate duration (assuming average speed)
    final avgSpeedMph = 30.0; // Average speed in mph
    final avgSpeedMps = avgSpeedMph / 2.23694; // Convert to m/s
    final duration = totalDistance / avgSpeedMps;
    
    // Calculate safety score
    final safetyScore = _calculateSafetyScore(dangersOnRoute, waypoints);
    
    return RouteSuggestion(
      id: 'route_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      start: start,
      end: end,
      waypoints: waypoints,
      distance: totalDistance,
      duration: duration,
      safetyScore: safetyScore,
      avoidedDangers: dangersOnRoute.map((d) => d.name).toList(),
      warnings: _generateWarnings(dangersOnRoute, waypoints),
    );
  }

  List<DangerZone> _checkDangersOnRoute(LatLng start, LatLng end) {
    final distance = const Distance();
    final routeDistance = distance.distance(start, end);
    
    // Check which danger zones are near the direct route
    final dangers = <DangerZone>[];
    
    for (final zone in _dangerZones) {
      if (!zone.isActive) continue;
      
      // Check if zone is within a certain distance from the route
      final distanceToStart = distance.distance(zone.center, start);
      final distanceToEnd = distance.distance(zone.center, end);
      
      // Simple check: if zone is close to either start or end, or the route passes near it
      if (distanceToStart <= _safeDistanceFromDanger ||
          distanceToEnd <= _safeDistanceFromDanger ||
          _isZoneOnRoute(zone, start, end)) {
        dangers.add(zone);
      }
    }
    
    return dangers;
  }

  bool _isZoneOnRoute(DangerZone zone, LatLng start, LatLng end) {
    final distance = const Distance();
    
    // Calculate the closest point on the line segment from start to end
    final closestPoint = _closestPointOnSegment(zone.center, start, end);
    final distanceToRoute = distance.distance(zone.center, closestPoint);
    
    return distanceToRoute <= _safeDistanceFromDanger + zone.radius;
  }

  LatLng _closestPointOnSegment(LatLng point, LatLng start, LatLng end) {
    // Calculate the closest point on the line segment from start to end
    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;
    
    if (dx == 0 && dy == 0) return start;
    
    final t = ((point.longitude - start.longitude) * dx + 
              (point.latitude - start.latitude) * dy) / 
             (dx * dx + dy * dy);
    
    final clampedT = t.clamp(0.0, 1.0);
    
    return LatLng(
      start.latitude + clampedT * dy,
      start.longitude + clampedT * dx,
    );
  }

  List<LatLng> _calculateWaypoints(LatLng start, LatLng end, List<DangerZone> dangers) {
    final waypoints = <LatLng>[start];
    
    if (dangers.isEmpty) {
      waypoints.add(end);
      return waypoints;
    }
    
    // For each danger zone, calculate a detour
    for (final zone in dangers) {
      // Calculate a point that goes around the danger zone
      final detourPoint = _calculateDetourPoint(start, end, zone);
      if (detourPoint != null) {
        waypoints.add(detourPoint);
      }
    }
    
    waypoints.add(end);
    return waypoints;
  }

  LatLng? _calculateDetourPoint(LatLng start, LatLng end, DangerZone zone) {
    // Calculate a point that avoids the danger zone
    final distance = const Distance();
    
    // Find the direction from start to end
    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;
    
    // Normalize the direction vector
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) return null;
    
    final dirX = dx / length;
    final dirY = dy / length;
    
    // Calculate perpendicular direction (to go around the zone)
    final perpX = -dirY;
    final perpY = dirX;
    
    // Calculate a point that is offset from the zone center
    final offsetDistance = zone.radius + _safeDistanceFromDanger;
    
    // Try to find a point that is away from the direct route
    final detourPoint = LatLng(
      zone.center.latitude + perpY * offsetDistance / 111320, // Approx meters to degrees
      zone.center.longitude + perpX * offsetDistance / (111320 * cos(zone.center.latitude * pi / 180)),
    );
    
    return detourPoint;
  }

  double _calculateSafetyScore(List<DangerZone> dangers, List<LatLng> waypoints) {
    // Base score
    double score = 100.0;
    
    // Reduce score based on number of dangers
    score -= dangers.length * 10.0;
    
    // Reduce score based on severity of dangers
    for (final danger in dangers) {
      score -= danger.severity * 2.0;
    }
    
    // Ensure score is between 0 and 100
    return score.clamp(0.0, 100.0);
  }

  List<String> _generateWarnings(List<DangerZone> dangers, List<LatLng> waypoints) {
    final warnings = <String>[];
    
    for (final danger in dangers) {
      warnings.add('Avoiding ${danger.type.toString().split('.').last} zone: ${danger.name}');
    }
    
    if (waypoints.length > 2) {
      warnings.add('Route has been adjusted to avoid danger zones');
    }
    
    return warnings;
  }

  bool shouldReroute(LatLng currentLocation, LatLng destination, List<DangerZone> activeDangers) {
    // Check if current route would pass through any active danger zones
    for (final danger in activeDangers) {
      if (_isZoneOnRoute(danger, currentLocation, destination)) {
        return true;
      }
    }
    return false;
  }

  List<LatLng> getAlternativeRoute(LatLng start, LatLng end, List<DangerZone> avoidZones) {
    // Create a temporary list of danger zones excluding the ones to avoid
    final tempDangerZones = _dangerZones
        .where((z) => !avoidZones.contains(z))
        .toList();
    
    // Calculate route with the remaining danger zones
    // This is a simplified version - in production, use a proper routing algorithm
    
    final distance = const Distance();
    final directDistance = distance.distance(start, end);
    
    // For now, just return a direct route
    // In a real implementation, this would use A* or Dijkstra's algorithm
    return [start, end];
  }
}
