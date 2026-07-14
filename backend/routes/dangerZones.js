const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
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

// Create a new danger zone
router.post('/', auth, async (req, res) => {
  try {
    const { name, description, latitude, longitude, radius, type, severity } = req.body;
    
    const dangerZone = new DangerZone({
      name,
      description,
      location: {
        type: 'Point',
        coordinates: [longitude, latitude]
      },
      radius,
      type,
      severity,
      createdBy: req.user._id
    });
    
    await dangerZone.save();
    res.status(201).json(dangerZone);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all danger zones
router.get('/', async (req, res) => {
  try {
    const { lat, lng, radius } = req.query;
    
    let query = { isActive: true };
    
    // If location filter is provided, find danger zones near that location
    if (lat && lng && radius) {
      query = {
        ...query,
        location: {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [parseFloat(lng), parseFloat(lat)]
            },
            $maxDistance: parseInt(radius)
          }
        }
      };
    }
    
    const dangerZones = await DangerZone.find(query);
    
    const formattedZones = dangerZones.map(zone => ({
      id: zone._id,
      name: zone.name,
      description: zone.description,
      latitude: zone.location.coordinates[1],
      longitude: zone.location.coordinates[0],
      radius: zone.radius,
      type: zone.type,
      severity: zone.severity,
      isActive: zone.isActive,
      createdAt: zone.createdAt,
      updatedAt: zone.updatedAt
    }));
    
    res.json(formattedZones);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get a specific danger zone
router.get('/:id', async (req, res) => {
  try {
    const dangerZone = await DangerZone.findById(req.params.id);
    
    if (!dangerZone) {
      return res.status(404).json({ error: 'Danger zone not found' });
    }
    
    res.json({
      id: dangerZone._id,
      name: dangerZone.name,
      description: dangerZone.description,
      latitude: dangerZone.location.coordinates[1],
      longitude: dangerZone.location.coordinates[0],
      radius: dangerZone.radius,
      type: dangerZone.type,
      severity: dangerZone.severity,
      isActive: dangerZone.isActive,
      createdAt: dangerZone.createdAt,
      updatedAt: dangerZone.updatedAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update a danger zone
router.put('/:id', auth, async (req, res) => {
  try {
    const updates = Object.keys(req.body);
    const allowedUpdates = ['name', 'description', 'radius', 'type', 'severity', 'isActive'];
    const isValidOperation = updates.every(update => allowedUpdates.includes(update));
    
    if (!isValidOperation) {
      return res.status(400).json({ error: 'Invalid updates!' });
    }
    
    const dangerZone = await DangerZone.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    
    if (!dangerZone) {
      return res.status(404).json({ error: 'Danger zone not found' });
    }
    
    res.json({
      id: dangerZone._id,
      name: dangerZone.name,
      description: dangerZone.description,
      latitude: dangerZone.location.coordinates[1],
      longitude: dangerZone.location.coordinates[0],
      radius: dangerZone.radius,
      type: dangerZone.type,
      severity: dangerZone.severity,
      isActive: dangerZone.isActive,
      createdAt: dangerZone.createdAt,
      updatedAt: dangerZone.updatedAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a danger zone
router.delete('/:id', auth, async (req, res) => {
  try {
    const dangerZone = await DangerZone.findByIdAndDelete(req.params.id);
    
    if (!dangerZone) {
      return res.status(404).json({ error: 'Danger zone not found' });
    }
    
    res.json({ message: 'Danger zone deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Check if a location is in any danger zone
router.post('/check', async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    
    const dangerZones = await DangerZone.find({
      isActive: true,
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [longitude, latitude]
          },
          $maxDistance: 1000 // Check within 1km
        }
      }
    });
    
    const formattedZones = dangerZones.map(zone => ({
      id: zone._id,
      name: zone.name,
      description: zone.description,
      latitude: zone.location.coordinates[1],
      longitude: zone.location.coordinates[0],
      radius: zone.radius,
      type: zone.type,
      severity: zone.severity
    }));
    
    res.json({ inDangerZone: formattedZones.length > 0, zones: formattedZones });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
