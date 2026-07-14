const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Geofence = require('../models/Geofence');
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

// Create a new geofence
router.post('/', auth, async (req, res) => {
  try {
    const { name, description, latitude, longitude, radius, notifyOnEntry, notifyOnExit } = req.body;
    
    const geofence = new Geofence({
      name,
      description,
      location: {
        type: 'Point',
        coordinates: [longitude, latitude]
      },
      radius,
      userId: req.user._id,
      notifyOnEntry: notifyOnEntry !== undefined ? notifyOnEntry : true,
      notifyOnExit: notifyOnExit !== undefined ? notifyOnExit : true
    });
    
    await geofence.save();
    
    res.status(201).json({
      id: geofence._id,
      name: geofence.name,
      description: geofence.description,
      latitude: geofence.location.coordinates[1],
      longitude: geofence.location.coordinates[0],
      radius: geofence.radius,
      isActive: geofence.isActive,
      notifyOnEntry: geofence.notifyOnEntry,
      notifyOnExit: geofence.notifyOnExit,
      createdAt: geofence.createdAt,
      updatedAt: geofence.updatedAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all geofences for a user
router.get('/user/:userId', auth, async (req, res) => {
  try {
    // Check if the requesting user can access these geofences
    if (req.user._id.toString() !== req.params.userId && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const geofences = await Geofence.find({ userId: req.params.userId });
    
    const formattedGeofences = geofences.map(geofence => ({
      id: geofence._id,
      name: geofence.name,
      description: geofence.description,
      latitude: geofence.location.coordinates[1],
      longitude: geofence.location.coordinates[0],
      radius: geofence.radius,
      isActive: geofence.isActive,
      notifyOnEntry: geofence.notifyOnEntry,
      notifyOnExit: geofence.notifyOnExit,
      createdAt: geofence.createdAt,
      updatedAt: geofence.updatedAt
    }));
    
    res.json(formattedGeofences);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get a specific geofence
router.get('/:id', auth, async (req, res) => {
  try {
    const geofence = await Geofence.findById(req.params.id);
    
    if (!geofence) {
      return res.status(404).json({ error: 'Geofence not found' });
    }
    
    // Check if the user can access this geofence
    if (geofence.userId.toString() !== req.user._id.toString() && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    res.json({
      id: geofence._id,
      name: geofence.name,
      description: geofence.description,
      latitude: geofence.location.coordinates[1],
      longitude: geofence.location.coordinates[0],
      radius: geofence.radius,
      isActive: geofence.isActive,
      notifyOnEntry: geofence.notifyOnEntry,
      notifyOnExit: geofence.notifyOnExit,
      createdAt: geofence.createdAt,
      updatedAt: geofence.updatedAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update a geofence
router.put('/:id', auth, async (req, res) => {
  try {
    const geofence = await Geofence.findById(req.params.id);
    
    if (!geofence) {
      return res.status(404).json({ error: 'Geofence not found' });
    }
    
    // Check if the user can update this geofence
    if (geofence.userId.toString() !== req.user._id.toString() && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const updates = Object.keys(req.body);
    const allowedUpdates = ['name', 'description', 'radius', 'isActive', 'notifyOnEntry', 'notifyOnExit'];
    const isValidOperation = updates.every(update => allowedUpdates.includes(update));
    
    if (!isValidOperation) {
      return res.status(400).json({ error: 'Invalid updates!' });
    }
    
    const updatedGeofence = await Geofence.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    
    res.json({
      id: updatedGeofence._id,
      name: updatedGeofence.name,
      description: updatedGeofence.description,
      latitude: updatedGeofence.location.coordinates[1],
      longitude: updatedGeofence.location.coordinates[0],
      radius: updatedGeofence.radius,
      isActive: updatedGeofence.isActive,
      notifyOnEntry: updatedGeofence.notifyOnEntry,
      notifyOnExit: updatedGeofence.notifyOnExit,
      createdAt: updatedGeofence.createdAt,
      updatedAt: updatedGeofence.updatedAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a geofence
router.delete('/:id', auth, async (req, res) => {
  try {
    const geofence = await Geofence.findById(req.params.id);
    
    if (!geofence) {
      return res.status(404).json({ error: 'Geofence not found' });
    }
    
    // Check if the user can delete this geofence
    if (geofence.userId.toString() !== req.user._id.toString() && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    await Geofence.findByIdAndDelete(req.params.id);
    res.json({ message: 'Geofence deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Check if a location is inside a geofence
router.post('/check', auth, async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    
    const geofences = await Geofence.find({
      userId: req.user._id,
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
    
    const formattedGeofences = geofences.map(geofence => ({
      id: geofence._id,
      name: geofence.name,
      description: geofence.description,
      latitude: geofence.location.coordinates[1],
      longitude: geofence.location.coordinates[0],
      radius: geofence.radius,
      isInside: true
    }));
    
    res.json({ insideGeofence: formattedGeofences.length > 0, geofences: formattedGeofences });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
