const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
    match: [/.+@.+\..+/, 'Please enter a valid email address']
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  role: {
    type: String,
    enum: ['parent', 'teen'],
    required: true
  },
  parentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  profileImageUrl: {
    type: String,
    trim: true
  },
  deviceToken: {
    type: String,
    trim: true
  },
  settings: {
    speedLimit: {
      type: Number,
      default: 80
    },
    dangerZoneAlerts: {
      type: Boolean,
      default: true
    },
    geofenceAlerts: {
      type: Boolean,
      default: true
    },
    speedingAlerts: {
      type: Boolean,
      default: true
    },
    nightDrivingAlerts: {
      type: Boolean,
      default: true
    }
  }
}, {
  timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (err) {
    next(err);
  }
});

// Method to compare passwords
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
