const mongoose = require('mongoose');

const geofenceSchema = new mongoose.Schema({
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
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  notifyOnEntry: {
    type: Boolean,
    default: true
  },
  notifyOnExit: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Create geospatial index
geofenceSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Geofence', geofenceSchema);
