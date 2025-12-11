const mongoose = require('mongoose');
require('dotenv').config();

/**
 * Quick fix script to drop and recreate email index as sparse
 * This fixes the "duplicate key error: email: null" issue
 * Run: node scripts/fixEmailIndex.js
 */

async function fixEmailIndex() {
  try {
    await mongoose.connect(process.env.MONGO_URI || process.env.MONGODB_URI || 'mongodb://localhost:27017/antardrishti');
    console.log('📦 Connected to MongoDB');

    const db = mongoose.connection.db;
    const usersCollection = db.collection('users');

    // Drop existing email index if it exists
    try {
      await usersCollection.dropIndex('email_1');
      console.log('✅ Dropped old email index (email_1)');
    } catch (dropError) {
      if (dropError.code === 27) {
        console.log('ℹ️  Email index does not exist, skipping drop');
      } else {
        throw dropError;
      }
    }

    // Create new sparse unique index on email
    // Sparse index allows multiple null values but ensures unique non-null values
    await usersCollection.createIndex({ email: 1 }, { unique: true, sparse: true });
    console.log('✅ Created new sparse unique index on email');
    console.log('   - Allows multiple users with email: null');
    console.log('   - Ensures unique email addresses when provided');

    await mongoose.disconnect();
    console.log('\n✅ Email index fixed successfully!');
    console.log('👋 Disconnected from MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error fixing email index:', error);
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  fixEmailIndex();
}

module.exports = { fixEmailIndex };


