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
    const user = await User.findById(decoded.id).select('-password');
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    req.user = user;
    req.token = token;
    next();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Middleware to check if user is a parent
const isParent = (req, res, next) => {
  if (req.user && req.user.role === 'parent') {
    next();
  } else {
    res.status(403).json({ error: 'Access denied. Parent role required.' });
  }
};

// Middleware to check if user is a teen
const isTeen = (req, res, next) => {
  if (req.user && req.user.role === 'teen') {
    next();
  } else {
    res.status(403).json({ error: 'Access denied. Teen role required.' });
  }
};

// Middleware to check if user can access a specific resource
const canAccessResource = (resourceType) => {
  return async (req, res, next) => {
    try {
      const resourceId = req.params.id || req.params[`${resourceType}Id`];
      
      if (!resourceId) {
        return res.status(400).json({ error: 'Resource ID is required' });
      }
      
      // In a real implementation, you would check the database
      // to see if the user has access to this resource
      
      // For now, just check if the user is the owner
      if (req.user._id.toString() === resourceId) {
        return next();
      }
      
      // If the user is a parent, check if the resource belongs to their teen
      if (req.user.role === 'parent') {
        // This would need to be implemented based on your data model
        return next();
      }
      
      res.status(403).json({ error: 'Access denied' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  };
};

// Middleware to validate request body
const validateBody = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    next();
  };
};

// Middleware to handle errors
const errorHandler = (err, req, res, next) => {
  console.error(err.stack);
  
  if (err.name === 'ValidationError') {
    return res.status(400).json({ error: err.message });
  }
  
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({ error: 'Invalid token' });
  }
  
  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({ error: 'Token expired' });
  }
  
  res.status(500).json({ error: 'Something went wrong!' });
};

module.exports = {
  auth,
  isParent,
  isTeen,
  canAccessResource,
  validateBody,
  errorHandler
};
