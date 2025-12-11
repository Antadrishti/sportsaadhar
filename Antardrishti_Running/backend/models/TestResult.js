const mongoose = require('mongoose');

const testResultSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  testName: {
    type: String,
    required: true,
    trim: true,
  },
  testType: {
    type: String,
    required: true,
    enum: ['running', 'strength', 'flexibility', 'agility', 'measurement', 'height', 'vertical_jump', 'strength_endurance', 'shuttle_run'],
    default: 'running',
  },
  distance: {
    type: Number,
    required: true,
    min: 0,
    // Distance in meters
  },
  timeTaken: {
    type: Number,
    required: true,
    min: 0,
    // Time in seconds
  },
  speed: {
    type: Number,
    required: true,
    min: 0,
    // Speed in m/s
  },
  pace: {
    type: Number,
    // Pace in min/km (optional, calculated from speed)
  },
  // Height test specific fields
  measuredHeight: {
    type: Number,
    min: 0,
    // Measured height in cm (stored but not displayed for privacy)
  },
  registeredHeight: {
    type: Number,
    min: 0,
    // User's registered height in cm
  },
  isHeightVerified: {
    type: Boolean,
    // Whether measured height is within ±7cm tolerance
  },
  // Jump test specific fields
  jumpHeight: {
    type: Number,
    min: 0,
    // Jump height in cm (vertical or horizontal)
  },
  jumpType: {
    type: String,
    enum: ['vertical', 'broad', 'horizontal'],
    // Type of jump test (vertical, broad/standing broad jump, horizontal)
  },
  // Exercise repetition fields
  repsCount: {
    type: Number,
    min: 0,
    // Number of repetitions (sit-ups, push-ups, etc.)
  },
  exerciseType: {
    type: String,
    enum: ['situps', 'pushups', 'pullups', 'squats'],
    // Type of exercise
  },
  // Flexibility test fields (sit and reach)
  flexibilityAngle: {
    type: Number,
    min: 0,
    max: 180,
    // Flexibility angle in degrees (lower = better flexibility)
  },
  flexibilityRating: {
    type: String,
    enum: ['elite', 'excellent', 'very_good', 'good'],
    // Flexibility rating based on angle
  },
  // Shuttle run specific fields
  shuttleRunLaps: {
    type: Number,
    min: 0,
    max: 10,
    // Number of laps completed in shuttle run (target: 4)
  },
  directionChanges: {
    type: Number,
    min: 0,
    // Number of direction changes detected (target: 3)
  },
  averageGpsAccuracy: {
    type: Number,
    // Average GPS accuracy in meters during test
  },
  date: {
    type: Date,
    default: Date.now,
  },
  timestamp: {
    type: Date,
    default: Date.now,
  },

  // ============ PERFORMANCE RATING (PERCENTILE-BASED) ============
  performanceRating: {
    type: String,
    enum: ['bronze', 'silver', 'gold', 'platinum'],
    // Bronze: 0-25% percentile
    // Silver: 25-50% percentile  
    // Gold: 50-90% percentile
    // Platinum: 90-100% percentile (top 10%)
  },
  percentile: {
    type: Number,
    min: 0,
    max: 100,
    // User's percentile rank for this test
  },
  ageGroup: {
    type: String,
    // e.g., '10-12', '13-15', '16-18', '19-25', '26-35', etc.
  },
  gender: {
    type: String,
    enum: ['Male', 'Female', 'Other'],
    // For gender-specific leaderboards
  },
  comparisonScore: {
    type: Number,
    // Normalized score for leaderboard comparison
  },

  // ============ CATEGORY CLASSIFICATION (for CATEGORY-BASED physical score) ============
  category: {
    type: String,
    enum: ['strength', 'endurance', 'flexibility', 'agility', 'speed', 'measurement'],
    // Strength: sit-ups, push-ups, medicine_ball_throw
    // Endurance: 800m, 1600m runs
    // Flexibility: sit-and-reach
    // Agility: 4x10 shuttle run
    // Speed: 30m sprint, vertical/broad jump (explosive power)
    // Measurement: height (not included in physical score)
  },

  // ============ XP EARNED (CONSERVATIVE: 30 BASE + RATING BONUS) ============
  xpEarned: {
    type: Number,
    default: 30,
    // Base 30 XP per test
  },
  bonusXP: {
    type: Number,
    default: 0,
    // Rating bonus: Bronze:0, Silver:20, Gold:50, Platinum:100
  },

  // ============ IMPROVEMENT TRACKING (BONUS XP + ACHIEVEMENTS) ============
  isPersonalBest: {
    type: Boolean,
    default: false,
  },
  improvementFromLast: {
    type: Number,
    // % improvement from previous attempt
  },
  improvementBonusXP: {
    type: Number,
    default: 0,
    // +20 XP for personal best
  },
}, {
  timestamps: true, // Adds createdAt and updatedAt
});

// Indexes for efficient queries
testResultSchema.index({ userId: 1, testName: 1, date: -1 });
testResultSchema.index({ testName: 1, ageGroup: 1, gender: 1, comparisonScore: -1 }); // For percentile calculation
testResultSchema.index({ testName: 1, performanceRating: 1 }); // Test leaderboards
testResultSchema.index({ category: 1, userId: 1 }); // Category score calculation
testResultSchema.index({ userId: 1, date: -1 }); // Recent test activity

// Calculate pace from speed if not provided
testResultSchema.pre('save', function(next) {
  if (this.speed && !this.pace) {
    // Convert m/s to min/km: (1000 / speed) / 60
    this.pace = (1000 / this.speed) / 60;
  }
  next();
});

const TestResult = mongoose.model('TestResult', testResultSchema);

module.exports = TestResult;

