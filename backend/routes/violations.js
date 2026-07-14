const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const SpeedViolation = require('../models/SpeedViolation');
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

// Report a speed violation
router.post('/', auth, async (req, res) => {
  try {
    const { teenId, speedMph, latitude, longitude, speedLimit, notes } = req.body;
    
    // If teenId is provided, check if the teen belongs to the user (parent)
    if (teenId) {
      const teen = await User.findById(teenId);
      if (!teen || teen.parentId?.toString() !== req.user._id.toString()) {
        return res.status(403).json({ error: 'Access denied' });
      }
    }
    
    const exceededBy = speedLimit ? speedMph - speedLimit : speedMph - 80;
    
    const violation = new SpeedViolation({
      userId: req.user._id,
      teenId,
      speedMph,
      location: {
        type: 'Point',
        coordinates: [longitude, latitude]
      },
      speedLimit: speedLimit || 80,
      exceededBy,
      notes
    });
    
    await violation.save();
    
    // Get the io instance for real-time updates
    const io = req.app.get('io');
    
    // Notify parent if this is a teen's violation
    if (teenId) {
      const teen = await User.findById(teenId);
      if (teen?.parentId) {
        io.to(`parent_${teen.parentId}`).emit('newViolation', {
          violationId: violation._id,
          teenId,
          speedMph,
          latitude,
          longitude,
          timestamp: violation.createdAt
        });
      }
    }
    
    res.status(201).json({
      id: violation._id,
      userId: violation.userId,
      teenId: violation.teenId,
      speedMph: violation.speedMph,
      latitude: violation.location.coordinates[1],
      longitude: violation.location.coordinates[0],
      speedLimit: violation.speedLimit,
      exceededBy: violation.exceededBy,
      acknowledged: violation.acknowledged,
      timestamp: violation.createdAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get speed violations for a user
router.get('/user/:userId', auth, async (req, res) => {
  try {
    // Check if the requesting user can access these violations
    if (req.user._id.toString() !== req.params.userId && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const { acknowledged, limit = 100, skip = 0 } = req.query;
    
    let query = { userId: req.params.userId };
    
    if (acknowledged !== undefined) {
      query.acknowledged = acknowledged === 'true';
    }
    
    const violations = await SpeedViolation.find(query)
      .sort({ createdAt: -1 })
      .skip(parseInt(skip))
      .limit(parseInt(limit));
    
    const formattedViolations = violations.map(violation => ({
      id: violation._id,
      userId: violation.userId,
      teenId: violation.teenId,
      speedMph: violation.speedMph,
      latitude: violation.location.coordinates[1],
      longitude: violation.location.coordinates[0],
      speedLimit: violation.speedLimit,
      exceededBy: violation.exceededBy,
      acknowledged: violation.acknowledged,
      acknowledgedAt: violation.acknowledgedAt,
      notes: violation.notes,
      timestamp: violation.createdAt
    }));
    
    res.json(formattedViolations);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get violations for a parent (all violations for their teens)
router.get('/parent/:parentId', auth, async (req, res) => {
  try {
    // Check if the requesting user is the parent
    if (req.user._id.toString() !== req.params.parentId || req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    // Find all teens for this parent
    const teens = await User.find({ parentId: req.params.parentId, role: 'teen' });
    const teenIds = teens.map(t => t._id);
    
    const { acknowledged, limit = 100, skip = 0 } = req.query;
    
    let query = { teenId: { $in: teenIds } };
    
    if (acknowledged !== undefined) {
      query.acknowledged = acknowledged === 'true';
    }
    
    const violations = await SpeedViolation.find(query)
      .sort({ createdAt: -1 })
      .skip(parseInt(skip))
      .limit(parseInt(limit));
    
    const formattedViolations = violations.map(violation => ({
      id: violation._id,
      userId: violation.userId,
      teenId: violation.teenId,
      speedMph: violation.speedMph,
      latitude: violation.location.coordinates[1],
      longitude: violation.location.coordinates[0],
      speedLimit: violation.speedLimit,
      exceededBy: violation.exceededBy,
      acknowledged: violation.acknowledged,
      acknowledgedAt: violation.acknowledgedAt,
      notes: violation.notes,
      timestamp: violation.createdAt
    }));
    
    res.json(formattedViolations);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Acknowledge a violation
router.patch('/:id/acknowledge', auth, async (req, res) => {
  try {
    const violation = await SpeedViolation.findById(req.params.id);
    
    if (!violation) {
      return res.status(404).json({ error: 'Violation not found' });
    }
    
    // Check if the user can acknowledge this violation
    if (violation.userId.toString() !== req.user._id.toString() && 
        violation.teenId?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    violation.acknowledged = true;
    violation.acknowledgedAt = new Date();
    await violation.save();
    
    res.json({
      id: violation._id,
      userId: violation.userId,
      teenId: violation.teenId,
      speedMph: violation.speedMph,
      latitude: violation.location.coordinates[1],
      longitude: violation.location.coordinates[0],
      speedLimit: violation.speedLimit,
      exceededBy: violation.exceededBy,
      acknowledged: violation.acknowledged,
      acknowledgedAt: violation.acknowledgedAt,
      notes: violation.notes,
      timestamp: violation.createdAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a violation
router.delete('/:id', auth, async (req, res) => {
  try {
    const violation = await SpeedViolation.findById(req.params.id);
    
    if (!violation) {
      return res.status(404).json({ error: 'Violation not found' });
    }
    
    // Check if the user can delete this violation
    if (violation.userId.toString() !== req.user._id.toString() && 
        violation.teenId?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    await SpeedViolation.findByIdAndDelete(req.params.id);
    res.json({ message: 'Violation deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get violation statistics
router.get('/stats/user/:userId', auth, async (req, res) => {
  try {
    // Check if the requesting user can access these stats
    if (req.user._id.toString() !== req.params.userId && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const violations = await SpeedViolation.find({ userId: req.params.userId });
    
    const totalViolations = violations.length;
    const avgSpeed = violations.reduce((sum, v) => sum + v.speedMph, 0) / totalViolations || 0;
    const maxSpeed = Math.max(...violations.map(v => v.speedMph), 0);
    const totalExceeded = violations.reduce((sum, v) => sum + (v.exceededBy || 0), 0);
    
    res.json({
      totalViolations,
      avgSpeed: parseFloat(avgSpeed.toFixed(2)),
      maxSpeed: parseFloat(maxSpeed.toFixed(2)),
      totalExceeded: parseFloat(totalExceeded.toFixed(2)),
      worstViolation: maxSpeed
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
