const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const SafetyAlert = require('../models/SafetyAlert');

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

// Send SOS emergency alert
router.post('/sos', auth, async (req, res) => {
  try {
    const { latitude, longitude, message, teenId } = req.body;
    
    // If teenId is provided, check if the teen belongs to the user (parent)
    if (teenId) {
      const teen = await User.findById(teenId);
      if (!teen || teen.parentId?.toString() !== req.user._id.toString()) {
        return res.status(403).json({ error: 'Access denied' });
      }
    }
    
    // Create SOS alert
    const alert = new SafetyAlert({
      userId: req.user._id,
      teenId: teenId || req.user._id,
      type: 'sos',
      title: 'SOS Emergency',
      message: message || 'Emergency! Please help!',
      location: {
        type: 'Point',
        coordinates: [longitude, latitude]
      }
    });
    
    await alert.save();
    
    // Get the io instance for real-time updates
    const io = req.app.get('io');
    
    // Notify parent if this is a teen's SOS
    const userToNotify = teenId ? await User.findById(teenId) : req.user;
    if (userToNotify?.parentId) {
      io.to(`parent_${userToNotify.parentId}`).emit('sosAlert', {
        alertId: alert._id,
        teenId: userToNotify._id,
        teenName: userToNotify.name,
        latitude,
        longitude,
        message: alert.message,
        timestamp: alert.createdAt
      });
    }
    
    // In a real app, you would also:
    // 1. Send push notifications to parent's device
    // 2. Send SMS to emergency contacts
    // 3. Call emergency services if configured
    
    res.status(201).json({
      id: alert._id,
      userId: alert.userId,
      teenId: alert.teenId,
      type: alert.type,
      title: alert.title,
      message: alert.message,
      latitude: alert.location.coordinates[1],
      longitude: alert.location.coordinates[0],
      timestamp: alert.createdAt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get emergency contacts for a user
router.get('/contacts', auth, async (req, res) => {
  try {
    // In a real app, this would fetch from a contacts collection
    // For now, return mock data
    const contacts = [
      {
        id: '1',
        name: 'Parent',
        phone: '+1-555-0123',
        relationship: 'parent',
        isEmergencyContact: true
      },
      {
        id: '2',
        name: 'Emergency Services',
        phone: '911',
        relationship: 'emergency',
        isEmergencyContact: true
      }
    ];
    
    res.json(contacts);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Add emergency contact
router.post('/contacts', auth, async (req, res) => {
  try {
    const { name, phone, relationship, isEmergencyContact } = req.body;
    
    // In a real app, save to contacts collection
    // For now, just return success
    
    res.status(201).json({
      id: 'new_contact_id',
      name,
      phone,
      relationship,
      isEmergencyContact,
      userId: req.user._id
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Trigger emergency call
router.post('/call', auth, async (req, res) => {
  try {
    const { phoneNumber } = req.body;
    
    // In a real app, this would use a telephony API to make the call
    // For now, just log and return success
    
    console.log(`Emergency call to ${phoneNumber} triggered by user ${req.user._id}`);
    
    res.json({
      message: 'Emergency call initiated',
      phoneNumber,
      timestamp: new Date()
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
