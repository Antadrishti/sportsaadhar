const mongoose = require('mongoose');
require('dotenv').config();

/**
 * Script to create database indexes for optimal performance
 * Run this after setting up the database
 */

async function createIndexes() {
  try {
    await mongoose.connect(process.env.MONGO_URI || process.env.MONGODB_URI || 'mongodb://localhost:27017/antardrishti');
    console.log('📦 Connected to MongoDB');

    const db = mongoose.connection.db;

    // ============ USER COLLECTION INDEXES ============
    console.log('\n📊 Creating User collection indexes...');
    
    const usersCollection = db.collection('users');
    
    // Global leaderboard
    await usersCollection.createIndex({ physicalScore: -1 });
    console.log('✅ Created index: physicalScore (desc)');
    
    // Regional leaderboard
    await usersCollection.createIndex({ state: 1, physicalScore: -1 });
    console.log('✅ Created index: state + physicalScore (desc)');
    
    // Age group leaderboard  
    await usersCollection.createIndex({ age: 1, physicalScore: -1 });
    console.log('✅ Created index: age + physicalScore (desc)');
    
    // Gender leaderboard
    await usersCollection.createIndex({ gender: 1, physicalScore: -1 });
    console.log('✅ Created index: gender + physicalScore (desc)');
    
    // XP-based rankings
    await usersCollection.createIndex({ currentXP: -1 });
    console.log('✅ Created index: currentXP (desc)');
    
    // User lookup (should already exist from unique constraint)
    await usersCollection.createIndex({ aadhaarNumber: 1 }, { unique: true });
    console.log('✅ Created index: aadhaarNumber (unique)');
    
    // Email index - sparse unique (allows multiple null values)
    // Drop existing email index if it exists (to fix the null duplicate issue)
    try {
      await usersCollection.dropIndex('email_1');
      console.log('✅ Dropped old email index');
    } catch (dropError) {
      // Index doesn't exist, that's fine
      console.log('ℹ️  No existing email index to drop');
    }
    await usersCollection.createIndex({ email: 1 }, { unique: true, sparse: true });
    console.log('✅ Created index: email (unique, sparse - allows multiple nulls)');

    // ============ TEST RESULT COLLECTION INDEXES ============
    console.log('\n📊 Creating TestResult collection indexes...');
    
    const testResultsCollection = db.collection('testresults');
    
    // User's test history (best + latest 5)
    await testResultsCollection.createIndex({ userId: 1, testName: 1, date: -1 });
    console.log('✅ Created index: userId + testName + date (desc)');
    
    // For percentile calculation
    await testResultsCollection.createIndex({ 
      testName: 1, 
      ageGroup: 1, 
      gender: 1, 
      comparisonScore: -1 
    });
    console.log('✅ Created index: testName + ageGroup + gender + comparisonScore (desc)');
    
    // Test leaderboards
    await testResultsCollection.createIndex({ testName: 1, performanceRating: 1 });
    console.log('✅ Created index: testName + performanceRating');
    
    // Category score calculation
    await testResultsCollection.createIndex({ category: 1, userId: 1 });
    console.log('✅ Created index: category + userId');
    
    // Recent test activity
    await testResultsCollection.createIndex({ userId: 1, date: -1 });
    console.log('✅ Created index: userId + date (desc)');

    // ============ ACTIVITY LOG COLLECTION INDEXES ============
    console.log('\n📊 Creating ActivityLog collection indexes...');
    
    const activityLogsCollection = db.collection('activitylogs');
    
    // User activity history
    await activityLogsCollection.createIndex({ userId: 1, activityDate: -1 });
    console.log('✅ Created index: userId + activityDate (desc)');
    
    // Activity analytics
    await activityLogsCollection.createIndex({ activityType: 1, activityDate: -1 });
    console.log('✅ Created index: activityType + activityDate (desc)');
    
    // Specific activity lookup
    await activityLogsCollection.createIndex({ userId: 1, activityType: 1, activityDate: -1 });
    console.log('✅ Created index: userId + activityType + activityDate (desc)');

    // ============ ACHIEVEMENT COLLECTION INDEXES ============
    console.log('\n📊 Creating Achievement collection indexes...');
    
    const achievementsCollection = db.collection('achievements');
    
    // Achievement lookup
    await achievementsCollection.createIndex({ achievementId: 1 }, { unique: true });
    console.log('✅ Created index: achievementId (unique)');
    
    // Category filtering
    await achievementsCollection.createIndex({ category: 1, isActive: 1 });
    console.log('✅ Created index: category + isActive');

    console.log('\n✅ All indexes created successfully!');
    console.log('\n📋 Index Summary:');
    console.log('   - User collection: 7 indexes (including sparse email index)');
    console.log('   - TestResult collection: 5 indexes');
    console.log('   - ActivityLog collection: 3 indexes');
    console.log('   - Achievement collection: 2 indexes');
    console.log('   - Total: 17 indexes\n');

    await mongoose.disconnect();
    console.log('👋 Disconnected from MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating indexes:', error);
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  createIndexes();
}

module.exports = { createIndexes };
