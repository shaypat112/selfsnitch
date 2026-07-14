const mongoose = require('mongoose');

const routeSuggestionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  start: {
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
  end: {
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
  waypoints: [{
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number],
      required: true
    }
  }],
  distance: {
    type: Number,
    required: true
  },
  duration: {
    type: Number,
    required: true
  },
  safetyScore: {
    type: Number,
    min: 0,
    max: 100,
    default: 50
  },
  avoidedDangers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'DangerZone'
  }],
  warnings: [String],
  status: {
    type: String,
    enum: ['pending', 'active', 'completed', 'cancelled'],
    default: 'pending'
  }
}, {
  timestamps: true
});

// Create indexes
routeSuggestionSchema.index({ userId: 1, createdAt: -1 });
routeSuggestionSchema.index({ safetyScore: -1 });

module.exports = mongoose.model('RouteSuggestion', routeSuggestionSchema);
