// Test script to verify connection to your existing MongoDB database
const mongoose = require('mongoose');
require('dotenv').config();

const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGODB_URI;
    
    const conn = await mongoose.connect(mongoUri);

    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    console.log(`📊 Database: ${conn.connection.name}`);
    
    // List all collections in the database
    const collections = await conn.connection.db.listCollections().toArray();
    console.log(`📁 Collections found:`);
    collections.forEach(collection => {
      console.log(`   - ${collection.name}`);
    });
    
    // Check if users collection exists and show sample data
    if (collections.some(c => c.name === 'users')) {
      const User = mongoose.model('User', new mongoose.Schema({}, { strict: false }));
      const userCount = await User.countDocuments();
      console.log(`👥 Total users in database: ${userCount}`);
      
      if (userCount > 0) {
        const sampleUser = await User.findOne();
        console.log(`📋 Sample user structure:`);
        console.log(JSON.stringify(sampleUser, null, 2));
      }
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Database connection error:', error.message);
    process.exit(1);
  }
};

connectDB();
