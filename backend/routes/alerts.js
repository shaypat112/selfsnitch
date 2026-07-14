const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const SafetyAlert = require('../models/SafetyAlert');
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

// Create a new alert
router.post('/', auth, async (req, res) => {
  try {
    const { teenId, type, title, message, latitude, longitude, speedMph, metadata } = req.body;
    
    // If teenId is provided, check if the teen belongs to the user (parent)
    if (teenId) {
      const teen = await User.findById(teenId);
      if (!teen || teen.parentId?.toString() !== req.user._id.toString()) {
        return res.status(403).json({ error: 'Access denied' });
      }
    }
    
    const alert = new SafetyAlert({
      userId: req.user._id,
      teenId,
      type,
      title,
      message,
      location: latitude && longitude ? {
        type: 'Point',
        coordinates: [longitude, latitude]
      } : undefined,
      speedMph,
      metadata
    });
    
    await alert.save();
    
    // Get the io instance for real-time updates
    const io = req.app.get('io');
    
    // Notify parent if this is a teen's alert
    if (teenId) {
      const teen = await User.findById(teenId);
      if (teen?.parentId) {
        io.to(`parent_${teen.parentId}`).emit('newAlert', {
          alertId: alert._id,
          teenId,
          type,
          title,
          message,
          timestamp: alert.createdAt
        });
      }
    } else {
      // Notify the user themselves
      io.to(req.user._id.toString()).emit('newAlert', {
        alertId: alert._id,
        type,
        title,
        message,
        timestamp: alert.createdAt
      });
    }
    
    res.status(201).json({
      id: alert._id,
      userId: alert.userId,
      teenId: alert.teenId,
      type: alert.type,
      status: alert.status,
      title: alert.title,
      message: alert.message,
      latitude: alert.location?.coordinates[1],
      longitude: alert.location?.coordinates[0],
      speedMph: alert.speedMph,
      metadata: alert.metadata,
      timestamp: alert.createdAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get alerts for a user
router.get('/user/:userId', auth, async (req, res) => {
  try {
    // Check if the requesting user can access these alerts
    if (req.user._id.toString() !== req.params.userId && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const { status, limit = 100, skip = 0 } = req.query;
    
    let query = { userId: req.params.userId };
    
    if (status) {
      query.status = status;
    }
    
    const alerts = await SafetyAlert.find(query)
      .sort({ createdAt: -1 })
      .skip(parseInt(skip))
      .limit(parseInt(limit));
    
    const formattedAlerts = alerts.map(alert => ({
      id: alert._id,
      userId: alert.userId,
      teenId: alert.teenId,
      type: alert.type,
      status: alert.status,
      title: alert.title,
      message: alert.message,
      latitude: alert.location?.coordinates[1],
      longitude: alert.location?.coordinates[0],
      speedMph: alert.speedMph,
      metadata: alert.metadata,
      timestamp: alert.createdAt,
      acknowledgedAt: alert.acknowledgedAt,
      resolvedAt: alert.resolvedAt
    }));
    
    res.json(formattedAlerts);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get alerts for a parent (all alerts for their teens)
router.get('/parent/:parentId', auth, async (req, res) => {
  try {
    // Check if the requesting user is the parent
    if (req.user._id.toString() !== req.params.parentId || req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    // Find all teens for this parent
    const teens = await User.find({ parentId: req.params.parentId, role: 'teen' });
    const teenIds = teens.map(t => t._id);
    
    const { status, limit = 100, skip = 0 } = req.query;
    
    let query = { teenId: { $in: teenIds } };
    
    if (status) {
      query.status = status;
    }
    
    const alerts = await SafetyAlert.find(query)
      .sort({ createdAt: -1 })
      .skip(parseInt(skip))
      .limit(parseInt(limit));
    
    const formattedAlerts = alerts.map(alert => ({
      id: alert._id,
      userId: alert.userId,
      teenId: alert.teenId,
      type: alert.type,
      status: alert.status,
      title: alert.title,
      message: alert.message,
      latitude: alert.location?.coordinates[1],
      longitude: alert.location?.coordinates[0],
      speedMph: alert.speedMph,
      metadata: alert.metadata,
      timestamp: alert.createdAt,
      acknowledgedAt: alert.acknowledgedAt,
      resolvedAt: alert.resolvedAt
    }));
    
    res.json(formattedAlerts);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Acknowledge an alert
router.patch('/:id/acknowledge', auth, async (req, res) => {
  try {
    const alert = await SafetyAlert.findById(req.params.id);
    
    if (!alert) {
      return res.status(404).json({ error: 'Alert not found' });
    }
    
    // Check if the user can acknowledge this alert
    if (alert.userId.toString() !== req.user._id.toString() && 
        alert.teenId?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    alert.status = 'acknowledged';
    alert.acknowledgedAt = new Date();
    await alert.save();
    
    // Get the io instance for real-time updates
    const io = req.app.get('io');
    
    // Notify parent if this is a teen's alert
    if (alert.teenId) {
      const teen = await User.findById(alert.teenId);
      if (teen?.parentId) {
        io.to(`parent_${teen.parentId}`).emit('alertAcknowledged', {
          alertId: alert._id,
          teenId: alert.teenId
        });
      }
    }
    
    res.json({
      id: alert._id,
      userId: alert.userId,
      teenId: alert.teenId,
      type: alert.type,
      status: alert.status,
      title: alert.title,
      message: alert.message,
      latitude: alert.location?.coordinates[1],
      longitude: alert.location?.coordinates[0],
      speedMph: alert.speedMph,
      metadata: alert.metadata,
      timestamp: alert.createdAt,
      acknowledgedAt: alert.acknowledgedAt,
      resolvedAt: alert.resolvedAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Resolve an alert
router.patch('/:id/resolve', auth, async (req, res) => {
  try {
    const alert = await SafetyAlert.findById(req.params.id);
    
    if (!alert) {
      return res.status(404).json({ error: 'Alert not found' });
    }
    
    // Check if the user can resolve this alert
    if (alert.userId.toString() !== req.user._id.toString() && 
        alert.teenId?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    alert.status = 'resolved';
    alert.resolvedAt = new Date();
    await alert.save();
    
    res.json({
      id: alert._id,
      userId: alert.userId,
      teenId: alert.teenId,
      type: alert.type,
      status: alert.status,
      title: alert.title,
      message: alert.message,
      latitude: alert.location?.coordinates[1],
      longitude: alert.location?.coordinates[0],
      speedMph: alert.speedMph,
      metadata: alert.metadata,
      timestamp: alert.createdAt,
      acknowledgedAt: alert.acknowledgedAt,
      resolvedAt: alert.resolvedAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete an alert
router.delete('/:id', auth, async (req, res) => {
  try {
    const alert = await SafetyAlert.findById(req.params.id);
    
    if (!alert) {
      return res.status(404).json({ error: 'Alert not found' });
    }
    
    // Check if the user can delete this alert
    if (alert.userId.toString() !== req.user._id.toString() && 
        alert.teenId?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    await SafetyAlert.findByIdAndDelete(req.params.id);
    res.json({ message: 'Alert deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
