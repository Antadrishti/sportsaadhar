const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  aadhaarNumber: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    validate: {
      validator: function(v) {
        return /^\d{12}$/.test(v);
      },
      message: 'Aadhaar number must be exactly 12 digits'
    }
  },
  age: {
    type: Number,
    required: true,
    min: 1,
    max: 120,
  },
  height: {
    type: Number,
    required: true,
    min: 50,
    max: 300,
  },
  weight: {
    type: Number,
    required: true,
    min: 10,
    max: 500,
  },
  gender: {
    type: String,
    required: true,
    enum: ['Male', 'Female', 'Other'],
  },
  address: {
    type: String,
    required: true,
    trim: true,
  },
  city: {
    type: String,
    required: true,
    trim: true,
  },
  state: {
    type: String,
    required: true,
    trim: true,
  },
  pincode: {
    type: String,
    required: true,
    trim: true,
  },
  disability: {
    type: String,
    enum: ['None', 'Visual', 'Hearing', 'Locomotor', 'Intellectual', 'Multiple'],
    default: 'None',
  },
  phoneNumber: {
    type: String,
    required: true,
    trim: true,
  },
  email: {
    type: String,
    required: false,
    lowercase: true,
    trim: true,
    sparse: true, // Allow multiple null values, but ensure unique non-null values
    unique: true, // Unique only for non-null emails
  },
  profileImageUrl: {
    type: String,
    default: null,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },

  // ============ GAMIFICATION CORE (UNLIMITED LEVELS) ============
  currentXP: {
    type: Number,
    default: 0,
    min: 0,
  },
  currentLevel: {
    type: Number,
    default: 1,
    min: 1,
    // NO MAX - unlimited levels with exponential XP scaling
  },
  levelTitle: {
    type: String,
    default: 'Rookie',
  },
  totalXPEarned: {
    type: Number,
    default: 0,
    min: 0,
  },

  // ============ STREAK & ACTIVITY ============
  currentStreak: {
    type: Number,
    default: 0,
    min: 0,
  },
  longestStreak: {
    type: Number,
    default: 0,
    min: 0,
  },
  lastLoginDate: {
    type: Date,
  },
  weekStreak: {
    type: [Boolean],
    default: [false, false, false, false, false, false, false], // Mon-Sun
  },

  // ============ PROGRESS TRACKING ============
  testsCompleted: {
    type: Number,
    default: 0,
    min: 0,
  },
  totalTests: {
    type: Number,
    default: 10, // Total number of physical tests
  },
  physicalScore: {
    type: Number,
    min: 0,
    max: 100,
    // CATEGORY-BASED overall physical score
  },
  psychometricCompleted: {
    type: Boolean,
    default: false,
  },
  mentalScore: {
    type: Number,
    min: 0,
    max: 100,
    // Overall mental/psychometric score
  },

  // ============ CATEGORY SCORES ============
  categoryScores: {
    strength: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    endurance: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    flexibility: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    agility: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    speed: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
  },

  // ============ MULTIPLE RANK TYPES (REAL-TIME UPDATES, TOP 50 + USER POSITION) ============
  rank: {
    type: Number,
    // Global rank
  },
  regionalRank: {
    type: Number,
    // State-level rank
  },
  ageGroupRank: {
    type: Number,
    // Age-group rank
  },
  genderRank: {
    type: Number,
    // Gender-based rank
  },

  // ============ TEST-SPECIFIC PROGRESS (BEST + LATEST 5 ATTEMPTS) ============
  testProgress: [{
    testId: {
      type: String,
      required: true,
    },
    testName: {
      type: String,
    },
    bestScore: {
      type: Number,
    },
    bestRating: {
      type: String,
      enum: ['bronze', 'silver', 'gold', 'platinum'],
    },
    bestPercentile: {
      type: Number,
      min: 0,
      max: 100,
    },
    attempts: {
      type: Number,
      default: 0,
    },
    lastAttemptDate: {
      type: Date,
    },
    recentAttempts: [{
      score: {
        type: Number,
      },
      rating: {
        type: String,
        enum: ['bronze', 'silver', 'gold', 'platinum'],
      },
      date: {
        type: Date,
      },
      xpEarned: {
        type: Number,
      },
    }],
  }],

  // ============ ACHIEVEMENTS (85+ COMPREHENSIVE) ============
  unlockedAchievements: [{
    achievementId: {
      type: String,
      required: true,
    },
    unlockedAt: {
      type: Date,
      default: Date.now,
    },
    xpEarned: {
      type: Number,
    },
  }],
});

const User = mongoose.model('User', userSchema);

module.exports = User;
