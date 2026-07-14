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

// Get all teens for a parent
router.get('/parent/:parentId/teens', auth, async (req, res) => {
  try {
    // Check if the requesting user is the parent
    if (req.user._id.toString() !== req.params.parentId && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const teens = await User.find({ parentId: req.params.parentId, role: 'teen' });
    res.json(teens);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get a specific user
router.get('/:id', auth, async (req, res) => {
  try {
    // Check if the requesting user can access this user
    if (req.user._id.toString() !== req.params.id && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const user = await User.findById(req.params.id).select('-password');
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update user
router.put('/:id', auth, async (req, res) => {
  try {
    // Check if the requesting user can update this user
    if (req.user._id.toString() !== req.params.id && req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const updates = Object.keys(req.body);
    const allowedUpdates = ['name', 'profileImageUrl', 'settings'];
    const isValidOperation = updates.every(update => allowedUpdates.includes(update));
    
    if (!isValidOperation) {
      return res.status(400).json({ error: 'Invalid updates!' });
    }
    
    const user = await User.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    ).select('-password');
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete user
router.delete('/:id', auth, async (req, res) => {
  try {
    // Only allow self-deletion or parent deleting their teen
    const userToDelete = await User.findById(req.params.id);
    
    if (!userToDelete) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    if (req.user._id.toString() !== req.params.id && 
        !(req.user.role === 'parent' && userToDelete.parentId?.toString() === req.user._id.toString())) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    await User.findByIdAndDelete(req.params.id);
    res.json({ message: 'User deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Link teen to parent
router.post('/:teenId/link-parent/:parentId', auth, async (req, res) => {
  try {
    // Check if the requesting user is the parent
    if (req.user._id.toString() !== req.params.parentId || req.user.role !== 'parent') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const teen = await User.findById(req.params.teenId);
    if (!teen || teen.role !== 'teen') {
      return res.status(404).json({ error: 'Teen not found' });
    }
    
    teen.parentId = req.params.parentId;
    await teen.save();
    
    res.json(teen);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
