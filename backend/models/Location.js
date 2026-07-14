const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number],
      required: true
    }
  },
  speedMph: {
    type: Number
  },
  heading: {
    type: Number
  },
  batteryLevel: {
    type: Number
  },
  isMoving: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

// Create indexes
locationSchema.index({ userId: 1, createdAt: -1 });
locationSchema.index({ location: '2dsphere' });

// TTL index to auto-delete old locations after 24 hours
locationSchema.index({ createdAt: 1 }, { expireAfterSeconds: 86400 });

module.exports = mongoose.model('Location', locationSchema);
