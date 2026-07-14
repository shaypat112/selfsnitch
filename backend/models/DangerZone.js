const mongoose = require('mongoose');

const dangerZoneSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
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
  radius: {
    type: Number,
    required: true,
    min: 10,
    max: 10000
  },
  type: {
    type: String,
    enum: ['schoolZone', 'highCrime', 'poorLighting', 'construction', 'accidentProne', 'highTraffic', 'custom'],
    default: 'custom'
  },
  severity: {
    type: Number,
    min: 1,
    max: 10,
    default: 5
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true
});

// Create geospatial index
dangerZoneSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('DangerZone', dangerZoneSchema);
