const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const RouteSuggestion = require('../models/RouteSuggestion');
const DangerZone = require('../models/DangerZone');
const User = require('../models/User');

// Middleware to authenticate user
const auth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    if (!token) {
      return res.status(401).json({ error: 'No token, authorization denied' });
    }
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    req.user = await User.findById(decoded.id).select('-password');
    
    if (!req.user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    next();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Calculate a safe route
router.post('/safe', auth, async (req, res) => {
  try {
    const { startLatitude, startLongitude, endLatitude, endLongitude, avoidDangerTypes } = req.body;
    
    // In a real implementation, this would use a routing service like OSRM, Google Maps, or Mapbox
    // For now, we'll create a simple route suggestion
    
    // Find danger zones along the route
    const dangerZones = await DangerZone.find({
      isActive: true,
      location: {
        $near: {
          $geometry: {
            type: 'LineString',
            coordinates: [
              [startLongitude, startLatitude],
              [endLongitude, endLatitude]
            ]
          },
          $maxDistance: 500 // Check within 500 meters of the route
        }
      }
    });
    
    // Filter by avoidDangerTypes if provided
    let filteredDangers = dangerZones;
    if (avoidDangerTypes && avoidDangerTypes.length > 0) {
      filteredDangers = dangerZones.filter(zone => 
        avoidDangerTypes.includes(zone.type)
      );
    }
    
    // Calculate simple route metrics (in a real app, use a routing API)
    const distance = calculateDistance(
      startLatitude, startLongitude,
      endLatitude, endLongitude
    );
    
    // Estimate duration (assuming average speed of 30 mph)
    const duration = (distance / 30) * 3600; // in seconds
    
    // Calculate safety score
    const safetyScore = calculateSafetyScore(filteredDangers, distance);
    
    // Generate warnings
    const warnings = filteredDangers.map(zone => 
      `Avoiding ${zone.type} zone: ${zone.name}`
    );
    
    if (filteredDangers.length > 0) {
      warnings.push('Route has been adjusted to avoid danger zones');
    }
    
    // Create route suggestion
    const routeSuggestion = new RouteSuggestion({
      userId: req.user._id,
      start: {
        type: 'Point',
        coordinates: [startLongitude, startLatitude]
      },
      end: {
        type: 'Point',
        coordinates: [endLongitude, endLatitude]
      },
      waypoints: [], // In a real app, this would contain the route waypoints
      distance,
      duration,
      safetyScore,
      avoidedDangers: filteredDangers.map(z => z._id),
      warnings
    });
    
    await routeSuggestion.save();
    
    res.json({
      id: routeSuggestion._id,
      userId: routeSuggestion.userId,
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
      waypoints: [],
      distance,
      duration,
      safetyScore,
      avoidedDangers: filteredDangers.map(z => z.name),
      warnings,
      createdAt: routeSuggestion.createdAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get route history for a user
router.get('/', auth, async (req, res) => {
  try {
    const { limit = 10, skip = 0 } = req.query;
    
    const routes = await RouteSuggestion.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .skip(parseInt(skip))
      .limit(parseInt(limit));
    
    const formattedRoutes = routes.map(route => ({
      id: route._id,
      userId: route.userId,
      startLatitude: route.start.coordinates[1],
      startLongitude: route.start.coordinates[0],
      endLatitude: route.end.coordinates[1],
      endLongitude: route.end.coordinates[0],
      waypoints: route.waypoints.map(w => ({
        latitude: w.coordinates[1],
        longitude: w.coordinates[0]
      })),
      distance: route.distance,
      duration: route.duration,
      safetyScore: route.safetyScore,
      avoidedDangers: route.avoidedDangers,
      warnings: route.warnings,
      status: route.status,
      createdAt: route.createdAt
    }));
    
    res.json(formattedRoutes);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get a specific route
router.get('/:id', auth, async (req, res) => {
  try {
    const route = await RouteSuggestion.findById(req.params.id);
    
    if (!route) {
      return res.status(404).json({ error: 'Route not found' });
    }
    
    // Check if the user can access this route
    if (route.userId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    res.json({
      id: route._id,
      userId: route.userId,
      startLatitude: route.start.coordinates[1],
      startLongitude: route.start.coordinates[0],
      endLatitude: route.end.coordinates[1],
      endLongitude: route.end.coordinates[0],
      waypoints: route.waypoints.map(w => ({
        latitude: w.coordinates[1],
        longitude: w.coordinates[0]
      })),
      distance: route.distance,
      duration: route.duration,
      safetyScore: route.safetyScore,
      avoidedDangers: route.avoidedDangers,
      warnings: route.warnings,
      status: route.status,
      createdAt: route.createdAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Helper function to calculate distance between two points (Haversine formula)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371000; // Earth radius in meters
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;
  
  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  
  return R * c;
}

// Helper function to calculate safety score
function calculateSafetyScore(dangerZones, distance) {
  let score = 100;
  
  // Reduce score based on number of dangers
  score -= dangerZones.length * 10;
  
  // Reduce score based on severity of dangers
  for (const zone of dangerZones) {
    score -= zone.severity * 2;
  }
  
  // Ensure score is between 0 and 100
  return Math.max(0, Math.min(100, score));
}

module.exports = router;
