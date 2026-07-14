const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
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

// Get user settings
router.get('/:userId', auth, async (req, res) => {
  try {
    // Check if the requesting user can access these settings
    if (req.user._id.toString() !== req.params.userId && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const user = await User.findById(req.params.userId).select('settings -_id');
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(user.settings || {});
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update user settings
router.put('/:userId', auth, async (req, res) => {
  try {
    // Check if the requesting user can update these settings
    if (req.user._id.toString() !== req.params.userId && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const updates = req.body;
    
    // Update only settings
    const user = await User.findByIdAndUpdate(
      req.params.userId,
      { settings: updates },
      { new: true, runValidators: true }
    ).select('settings -_id');
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(user.settings || {});
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get default settings
router.get('/defaults', async (req, res) => {
  try {
    res.json({
      speedLimit: 80,
      dangerZoneAlerts: true,
      geofenceAlerts: true,
      speedingAlerts: true,
      nightDrivingAlerts: true,
      maxSpeedMph: 80,
      warningSpeedMph: 70,
      dangerZoneRadius: 100,
      geofenceRadius: 500
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
