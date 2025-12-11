const TestResult = require('../models/TestResult');
const User = require('../models/User');
const { TEST_CATEGORIES, getTestCategory, getCategoryWeight, getAllCategories } = require('../config/testCategories');

/**
 * Rating Service - Percentile-Based Rating System with Category-Based Scoring
 * 
 * Ratings: Bronze (0-25%), Silver (25-50%), Gold (50-90%), Platinum (90-100%)
 * Physical Score: Weighted average of 5 category scores
 */

/**
 * Calculate user's percentile for a specific test
 * @param {string} testId - Test identifier
 * @param {number} score - User's score
 * @param {string} ageGroup - User's age group (e.g., '10-12', '13-15')
 * @param {string} gender - User's gender (Male, Female, Other)
 * @returns {Promise<number>} - Percentile (0-100)
 */
async function calculatePercentile(testId, score, ageGroup, gender) {
  // Count how many users scored worse than this score in the same demographic
  const totalCount = await TestResult.countDocuments({
    testName: testId,
    ageGroup,
    gender,
  });
  
  if (totalCount === 0) {
    // If no comparison data exists, return 50th percentile
    return 50;
  }
  
  // For most tests, higher score is better (reps, distance, etc.)
  // But for timed events and flexibility angle, lower is better
  const lowerIsBetter = testId.includes('run') || testId.includes('sprint') || testId === 'sit_and_reach';
  
  let worseCount;
  if (lowerIsBetter) {
    // Count users who took MORE time (worse)
    worseCount = await TestResult.countDocuments({
      testName: testId,
      ageGroup,
      gender,
      comparisonScore: { $gt: score },
    });
  } else {
    // Count users who scored less (worse)
    worseCount = await TestResult.countDocuments({
      testName: testId,
      ageGroup,
      gender,
      comparisonScore: { $lt: score },
    });
  }
  
  const percentile = (worseCount / totalCount) * 100;
  return Math.min(100, Math.max(0, Math.round(percentile)));
}

/**
 * Assign rating based on percentile
 * @param {number} percentile - Percentile (0-100)
 * @returns {string} - Rating (bronze, silver, gold, platinum)
 */
function assignRating(percentile) {
  if (percentile >= 90) return 'platinum';
  if (percentile >= 50) return 'gold';
  if (percentile >= 25) return 'silver';
  return 'bronze';
}

/**
 * Determine age group from age
 * @param {number} age - User's age
 * @returns {string} - Age group string
 */
function getAgeGroup(age) {
  if (age <= 12) return '10-12';
  if (age <= 15) return '13-15';
  if (age <= 18) return '16-18';
  if (age <= 25) return '19-25';
  if (age <= 35) return '26-35';
  if (age <= 45) return '36-45';
  if (age <= 55) return '46-55';
  return '56+';
}

/**
 * Calculate category score for a user (average percentile of tests in category)
 * @param {string} userId - User ID
 * @param {string} category - Category name (strength, endurance, etc.)
 * @returns {Promise<number>} - Category score (0-100)
 */
async function calculateCategoryScore(userId, category) {
  const user = await User.findById(userId);
  if (!user) return 0;
  
  const testsInCategory = TEST_CATEGORIES[category]?.tests || [];
  if (testsInCategory.length === 0) return 0;
  
  // Get user's test progress for this category
  const categoryTests = user.testProgress.filter(tp => 
    testsInCategory.includes(tp.testId) && tp.bestPercentile != null
  );
  
  if (categoryTests.length === 0) return 0;
  
  // Average the percentiles
  const totalPercentile = categoryTests.reduce((sum, test) => sum + test.bestPercentile, 0);
  return Math.round(totalPercentile / categoryTests.length);
}

/**
 * Calculate overall physical score (weighted average of category scores)
 * @param {string} userId - User ID
 * @returns {Promise<number>} - Overall physical score (0-100)
 */
async function calculateOverallPhysicalScore(userId) {
  const categories = getAllCategories();
  let totalScore = 0;
  let totalWeight = 0;
  
  for (const category of categories) {
    const categoryScore = await calculateCategoryScore(userId, category);
    const weight = getCategoryWeight(category);
    
    if (categoryScore > 0) {
      totalScore += categoryScore * weight;
      totalWeight += weight;
    }
  }
  
  if (totalWeight === 0) return 0;
  
  // Normalize to 0-100 based on completed categories
  return Math.round(totalScore / totalWeight);
}

/**
 * Update user's category scores and overall physical score
 * @param {string} userId - User ID
 * @returns {Promise<object>} - Updated scores
 */
async function updateUserScores(userId) {
  const user = await User.findById(userId);
  if (!user) throw new Error('User not found');
  
  const categories = getAllCategories();
  const categoryScores = {};
  
  // Calculate each category score
  for (const category of categories) {
    categoryScores[category] = await calculateCategoryScore(userId, category);
  }
  
  // Calculate overall physical score
  const physicalScore = await calculateOverallPhysicalScore(userId);
  
  // Update user document
  user.categoryScores = categoryScores;
  user.physicalScore = physicalScore;
  await user.save();
  
  return {
    categoryScores,
    physicalScore,
  };
}

/**
 * Normalize score for comparison (handles different test types)
 * @param {string} testId - Test identifier
 * @param {object} testData - Test result data
 * @returns {number} - Normalized comparison score
 */
function normalizeScore(testId, testData) {
  // For timed events (lower is better), use negative time so higher rank = better
  if (testId.includes('run') || testId.includes('sprint')) {
    return testData.timeTaken || 0;
  }
  
  // For flexibility (sit and reach), use angle (lower is better)
  if (testId === 'sit_and_reach') {
    return testData.flexibilityAngle || 0;
  }
  
  // For jump tests, use height
  if (testId.includes('jump')) {
    return testData.jumpHeight || 0;
  }
  
  // For rep-based tests (sit-ups, push-ups), use rep count
  if (testData.repsCount) {
    return testData.repsCount;
  }
  
  // For shuttle run, use time (lower is better)
  if (testId.includes('shuttle')) {
    return testData.timeTaken || 0;
  }
  
  // Default: use distance
  return testData.distance || 0;
}

/**
 * Update user's test progress after a new test result
 * @param {string} userId - User ID
 * @param {string} testId - Test identifier
 * @param {object} testResult - Test result document
 * @returns {Promise<void>}
 */
async function updateTestProgress(userId, testId, testResult) {
  const user = await User.findById(userId);
  if (!user) throw new Error('User not found');
  
  // Find existing test progress
  let testProgress = user.testProgress.find(tp => tp.testId === testId);
  
  if (!testProgress) {
    // Create new test progress entry
    testProgress = {
      testId,
      testName: testResult.testName,
      bestScore: testResult.comparisonScore,
      bestRating: testResult.performanceRating,
      bestPercentile: testResult.percentile,
      attempts: 0,
      recentAttempts: [],
    };
    user.testProgress.push(testProgress);
  }
  
  // Update attempts
  testProgress.attempts = (testProgress.attempts || 0) + 1;
  testProgress.lastAttemptDate = testResult.date;
  
  // Check if this is a personal best
  const isPersonalBest = !testProgress.bestScore || 
    (testResult.comparisonScore > testProgress.bestScore && !testId.includes('run') && !testId.includes('sprint')) ||
    (testResult.comparisonScore < testProgress.bestScore && (testId.includes('run') || testId.includes('sprint') || testId === 'sit_and_reach'));
  
  if (isPersonalBest) {
    testProgress.bestScore = testResult.comparisonScore;
    testProgress.bestRating = testResult.performanceRating;
    testProgress.bestPercentile = testResult.percentile;
  }
  
  // Add to recent attempts (keep latest 5)
  testProgress.recentAttempts.unshift({
    score: testResult.comparisonScore,
    rating: testResult.performanceRating,
    date: testResult.date,
    xpEarned: (testResult.xpEarned || 0) + (testResult.bonusXP || 0) + (testResult.improvementBonusXP || 0),
  });
  
  // Keep only latest 5 attempts
  if (testProgress.recentAttempts.length > 5) {
    testProgress.recentAttempts = testProgress.recentAttempts.slice(0, 5);
  }
  
  await user.save();
  
  return isPersonalBest;
}

module.exports = {
  calculatePercentile,
  assignRating,
  getAgeGroup,
  calculateCategoryScore,
  calculateOverallPhysicalScore,
  updateUserScores,
  normalizeScore,
  updateTestProgress,
};


