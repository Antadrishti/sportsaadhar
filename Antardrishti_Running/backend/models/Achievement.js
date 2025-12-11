const mongoose = require('mongoose');

const achievementSchema = new mongoose.Schema({
  achievementId: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  description: {
    type: String,
    required: true,
    trim: true,
  },
  icon: {
    type: String,
    // Icon name or emoji
  },
  category: {
    type: String,
    enum: ['physical', 'dedication', 'special', 'general'],
    required: true,
  },
  rarity: {
    type: String,
    enum: ['common', 'rare', 'epic', 'legendary'],
    default: 'common',
  },
  xpReward: {
    type: Number,
    required: true,
    min: 0,
  },
  requirements: {
    type: {
      type: String,
      enum: ['test_complete', 'streak', 'score', 'count', 'special', 'level', 'improvement', 'leaderboard'],
    },
    targetValue: {
      type: Number,
    },
    testId: {
      type: String,
      // For test-specific achievements
    },
    rating: {
      type: String,
      enum: ['bronze', 'silver', 'gold', 'platinum'],
      // For performance achievements
    },
    category: {
      type: String,
      enum: ['strength', 'endurance', 'flexibility', 'agility', 'speed'],
      // For category-specific achievements
    },
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  isHidden: {
    type: Boolean,
    default: false,
    // Hidden achievements (not shown until unlocked)
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

const Achievement = mongoose.model('Achievement', achievementSchema);

module.exports = Achievement;


