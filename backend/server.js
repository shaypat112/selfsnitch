const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const http = require('http');
const socketIo = require('socket.io');

// Load environment variables
dotenv.config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/selfsnitch';

mongoose.connect(MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

// Routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const locationRoutes = require('./routes/locations');
const dangerZoneRoutes = require('./routes/dangerZones');
const alertRoutes = require('./routes/alerts');
const geofenceRoutes = require('./routes/geofences');
const routeRoutes = require('./routes/routes');
const violationRoutes = require('./routes/violations');
const emergencyRoutes = require('./routes/emergency');
const settingsRoutes = require('./routes/settings');

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/locations', locationRoutes);
app.use('/api/danger-zones', dangerZoneRoutes);
app.use('/api/alerts', alertRoutes);
app.use('/api/geofences', geofenceRoutes);
app.use('/api/routes', routeRoutes);
app.use('/api/violations', violationRoutes);
app.use('/api/emergency', emergencyRoutes);
app.use('/api/settings', settingsRoutes);

// Socket.io for real-time updates
io.on('connection', (socket) => {
  console.log('New client connected:', socket.id);

  // Join user's room
  socket.on('joinUser', (userId) => {
    socket.join(userId);
    console.log(`User ${userId} joined their room`);
  });

  // Join parent's room for teen updates
  socket.on('joinParent', (parentId) => {
    socket.join(`parent_${parentId}`);
    console.log(`Socket joined parent room: ${parentId}`);
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Make io accessible to routes
app.set('io', io);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Export for testing
module.exports = { app, server, io };
