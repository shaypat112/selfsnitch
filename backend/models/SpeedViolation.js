const mongoose = require('mongoose');

const speedViolationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  teenId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  speedMph: {
    type: Number,
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
  speedLimit: {
    type: Number,
    default: 80
  },
  exceededBy: {
    type: Number
  },
  acknowledged: {
    type: Boolean,
    default: false
  },
  acknowledgedAt: {
    type: Date
  },
  notes: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
});

// Create indexes
speedViolationSchema.index({ userId: 1, createdAt: -1 });
speedViolationSchema.index({ teenId: 1, createdAt: -1 });
speedViolationSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('SpeedViolation', speedViolationSchema);
