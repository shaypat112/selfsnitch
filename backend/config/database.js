const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/selfsnitch', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (err) {
    console.error(`Error: ${err.message}`);
    process.exit(1);
  }
};

const disconnectDB = async () => {
  try {
    await mongoose.disconnect();
    console.log('MongoDB Disconnected');
  } catch (err) {
    console.error(`Error disconnecting from MongoDB: ${err.message}`);
  }
};

module.exports = { connectDB, disconnectDB };
