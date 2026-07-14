const mongoose = require('mongoose');

const safetyAlertSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  teenId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  type: {
    type: String,
    enum: ['speeding', 'dangerZoneEntered', 'dangerZoneApproaching', 'geofenceExit', 'sos', 'lowBattery', 'nightDriving', 'custom'],
    required: true
  },
  status: {
    type: String,
    enum: ['active', 'acknowledged', 'resolved'],
    default: 'active'
  },
  title: {
    type: String,
    required: true,
    trim: true
  },
  message: {
    type: String,
    required: true,
    trim: true
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number]
    }
  },
  speedMph: {
    type: Number
  },
  metadata: {
    type: mongoose.Schema.Types.Mixed
  },
  acknowledgedAt: {
    type: Date
  },
  resolvedAt: {
    type: Date
  }
}, {
  timestamps: true
});

// Create indexes
safetyAlertSchema.index({ userId: 1, createdAt: -1 });
safetyAlertSchema.index({ teenId: 1, createdAt: -1 });
safetyAlertSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('SafetyAlert', safetyAlertSchema);
