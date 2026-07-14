const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Location = require('../models/Location');
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

// Update user location
router.post('/:userId', auth, async (req, res) => {
  try {
    // Check if the requesting user can update this location
    if (req.user._id.toString() !== req.params.userId && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const { latitude, longitude, speedMph, heading, batteryLevel } = req.body;
    
    // Create new location document
    const location = new Location({
      userId: req.params.userId,
      location: {
        type: 'Point',
        coordinates: [longitude, latitude]
      },
      speedMph,
      heading,
      batteryLevel,
      isMoving: speedMph > 5
    });
    
    await location.save();
    
    // Get the io instance for real-time updates
    const io = req.app.get('io');
    
    // Notify parent if this is a teen
    const user = await User.findById(req.params.userId);
    if (user && user.role === 'teen' && user.parentId) {
      io.to(`parent_${user.parentId}`).emit('locationUpdate', {
        teenId: user._id,
        location: { latitude, longitude },
        speedMph,
        timestamp: new Date()
      });
    }
    
    res.json(location);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get user's current location
router.get('/:userId', auth, async (req, res) => {
  try {
    // Check if the requesting user can access this location
    if (req.user._id.toString() !== req.params.userId && 
        !(req.user.role === 'parent' && req.user._id.toString() === (await User.findById(req.params.userId))?.parentId?.toString())) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    // Get the most recent location
    const location = await Location.findOne({ userId: req.params.userId })
      .sort({ createdAt: -1 })
      .limit(1);
    
    if (!location) {
      return res.status(404).json({ error: 'Location not found' });
    }
    
    res.json({
      latitude: location.location.coordinates[1],
      longitude: location.location.coordinates[0],
      speedMph: location.speedMph,
      heading: location.heading,
      batteryLevel: location.batteryLevel,
      isMoving: location.isMoving,
      timestamp: location.createdAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get location history for a user
router.get('/:userId/history', auth, async (req, res) => {
  try {
    // Check if the requesting user can access this location history
    if (req.user._id.toString() !== req.params.userId && 
        !(req.user.role === 'parent' && req.user._id.toString() === (await User.findById(req.params.userId))?.parentId?.toString())) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const { limit = 100, skip = 0 } = req.query;
    
    const locations = await Location.find({ userId: req.params.userId })
      .sort({ createdAt: -1 })
      .skip(parseInt(skip))
      .limit(parseInt(limit));
    
    const formattedLocations = locations.map(loc => ({
      latitude: loc.location.coordinates[1],
      longitude: loc.location.coordinates[0],
      speedMph: loc.speedMph,
      heading: loc.heading,
      batteryLevel: loc.batteryLevel,
      isMoving: loc.isMoving,
      timestamp: loc.createdAt
    }));
    
    res.json(formattedLocations);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get locations of all teens for a parent
router.get('/parent/:parentId/teens', auth, async (req, res) => {
  try {
    // Check if the requesting user is the parent
    if (req.user._id.toString() !== req.params.parentId || req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    // Find all teens for this parent
    const teens = await User.find({ parentId: req.params.parentId, role: 'teen' });
    
    // Get latest location for each teen
    const teenLocations = [];
    
    for (const teen of teens) {
      const location = await Location.findOne({ userId: teen._id })
        .sort({ createdAt: -1 })
        .limit(1);
      
      if (location) {
        teenLocations.push({
          teenId: teen._id,
          teenName: teen.name,
          latitude: location.location.coordinates[1],
          longitude: location.location.coordinates[0],
          speedMph: location.speedMph,
          isMoving: location.isMoving,
          timestamp: location.createdAt
        });
      }
    }
    
    res.json(teenLocations);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
