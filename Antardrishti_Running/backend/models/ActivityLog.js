const mongoose = require('mongoose');

const activityLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  activityType: {
    type: String,
    enum: ['login', 'test_start', 'test_complete', 'achievement_unlock', 'level_up'],
    required: true,
    index: true,
  },
  activityDate: {
    type: Date,
    default: Date.now,
    index: true,
  },
  metadata: {
    testId: {
      type: String,
    },
    testName: {
      type: String,
    },
    xpEarned: {
      type: Number,
    },
    achievementId: {
      type: String,
    },
    levelReached: {
      type: Number,
    },
    score: {
      type: Number,
    },
    rating: {
      type: String,
      enum: ['bronze', 'silver', 'gold', 'platinum'],
    },
    percentile: {
      type: Number,
    },
  },
}, {
  timestamps: true, // Adds createdAt and updatedAt
});

// Index for efficient queries
activityLogSchema.index({ userId: 1, activityType: 1, activityDate: -1 });

const ActivityLog = mongoose.model('ActivityLog', activityLogSchema);

module.exports = ActivityLog;


