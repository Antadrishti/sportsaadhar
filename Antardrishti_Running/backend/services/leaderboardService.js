const User = require('../models/User');
const TestResult = require('../models/TestResult');

/**
 * Leaderboard Service - All Leaderboard Types with Real-Time Updates
 * 
 * Types: Global, Regional (state), Age Group, Gender, Test-Specific
 * Format: Top 50 + User Position
 */

/**
 * Get global leaderboard (top users by physical score)
 * @param {number} limit - Number of top users to return (default 50)
 * @param {string} userId - Optional user ID to get their position
 * @returns {Promise<object>} - Leaderboard data
 */
async function getGlobalLeaderboard(limit = 50, userId = null) {
  // Get top users
  const topUsers = await User.find({ physicalScore: { $gt: 0 } })
    .sort({ physicalScore: -1 })
    .limit(limit)
    .select('name physicalScore profileImageUrl currentLevel')
    .lean();
  
  // Format top users with rank
  const formattedTopUsers = topUsers.map((user, index) => ({
    userId: user._id.toString(),
    name: user.name,
    score: user.physicalScore,
    rank: index + 1,
    level: user.currentLevel || 1,
    profileImage: user.profileImageUrl,
  }));
  
  // Get total users count
  const totalUsers = await User.countDocuments({ physicalScore: { $gt: 0 } });
  
  // Get user position if userId provided
  let userPosition = null;
  if (userId) {
    userPosition = await getUserPosition(userId, 'global');
  }
  
  return {
    type: 'global',
    topUsers: formattedTopUsers,
    userPosition,
    totalUsers,
  };
}

/**
 * Get regional leaderboard (top users by state)
 * @param {string} state - State name
 * @param {number} limit - Number of top users
 * @param {string} userId - Optional user ID
 * @returns {Promise<object>} - Leaderboard data
 */
async function getRegionalLeaderboard(state, limit = 50, userId = null) {
  const topUsers = await User.find({ 
    state,
    physicalScore: { $gt: 0 } 
  })
    .sort({ physicalScore: -1 })
    .limit(limit)
    .select('name physicalScore profileImageUrl currentLevel state')
    .lean();
  
  const formattedTopUsers = topUsers.map((user, index) => ({
    userId: user._id.toString(),
    name: user.name,
    score: user.physicalScore,
    rank: index + 1,
    level: user.currentLevel || 1,
    profileImage: user.profileImageUrl,
    state: user.state,
  }));
  
  const totalUsers = await User.countDocuments({ 
    state,
    physicalScore: { $gt: 0 } 
  });
  
  let userPosition = null;
  if (userId) {
    userPosition = await getUserPosition(userId, 'regional', { state });
  }
  
  return {
    type: 'regional',
    state,
    topUsers: formattedTopUsers,
    userPosition,
    totalUsers,
  };
}

/**
 * Get age group leaderboard
 * @param {string} ageGroup - Age group (e.g., '10-12', '13-15')
 * @param {number} limit - Number of top users
 * @param {string} userId - Optional user ID
 * @returns {Promise<object>} - Leaderboard data
 */
async function getAgeGroupLeaderboard(ageGroup, limit = 50, userId = null) {
  const [minAge, maxAge] = ageGroup.split('-').map(Number);
  
  const topUsers = await User.find({ 
    age: { $gte: minAge, $lte: maxAge },
    physicalScore: { $gt: 0 } 
  })
    .sort({ physicalScore: -1 })
    .limit(limit)
    .select('name physicalScore profileImageUrl currentLevel age')
    .lean();
  
  const formattedTopUsers = topUsers.map((user, index) => ({
    userId: user._id.toString(),
    name: user.name,
    score: user.physicalScore,
    rank: index + 1,
    level: user.currentLevel || 1,
    profileImage: user.profileImageUrl,
    age: user.age,
  }));
  
  const totalUsers = await User.countDocuments({ 
    age: { $gte: minAge, $lte: maxAge },
    physicalScore: { $gt: 0 } 
  });
  
  let userPosition = null;
  if (userId) {
    userPosition = await getUserPosition(userId, 'ageGroup', { ageGroup });
  }
  
  return {
    type: 'ageGroup',
    ageGroup,
    topUsers: formattedTopUsers,
    userPosition,
    totalUsers,
  };
}

/**
 * Get gender leaderboard
 * @param {string} gender - Gender (Male, Female, Other)
 * @param {number} limit - Number of top users
 * @param {string} userId - Optional user ID
 * @returns {Promise<object>} - Leaderboard data
 */
async function getGenderLeaderboard(gender, limit = 50, userId = null) {
  const topUsers = await User.find({ 
    gender,
    physicalScore: { $gt: 0 } 
  })
    .sort({ physicalScore: -1 })
    .limit(limit)
    .select('name physicalScore profileImageUrl currentLevel gender')
    .lean();
  
  const formattedTopUsers = topUsers.map((user, index) => ({
    userId: user._id.toString(),
    name: user.name,
    score: user.physicalScore,
    rank: index + 1,
    level: user.currentLevel || 1,
    profileImage: user.profileImageUrl,
    gender: user.gender,
  }));
  
  const totalUsers = await User.countDocuments({ 
    gender,
    physicalScore: { $gt: 0 } 
  });
  
  let userPosition = null;
  if (userId) {
    userPosition = await getUserPosition(userId, 'gender', { gender });
  }
  
  return {
    type: 'gender',
    gender,
    topUsers: formattedTopUsers,
    userPosition,
    totalUsers,
  };
}

/**
 * Get test-specific leaderboard
 * @param {string} testId - Test identifier
 * @param {number} limit - Number of top results
 * @param {string} userId - Optional user ID
 * @returns {Promise<object>} - Leaderboard data
 */
async function getTestLeaderboard(testId, limit = 50, userId = null) {
  // Get best results for this test (one per user)
  const pipeline = [
    { $match: { testName: testId, percentile: { $exists: true } } },
    { $sort: { percentile: -1, date: -1 } },
    { $group: {
      _id: '$userId',
      bestPercentile: { $first: '$percentile' },
      bestRating: { $first: '$performanceRating' },
      score: { $first: '$comparisonScore' },
      date: { $first: '$date' },
    }},
    { $sort: { bestPercentile: -1 } },
    { $limit: limit },
  ];
  
  const topResults = await TestResult.aggregate(pipeline);
  
  // Populate user data
  const userIds = topResults.map(r => r._id);
  const users = await User.find({ _id: { $in: userIds } })
    .select('name profileImageUrl currentLevel')
    .lean();
  
  const userMap = {};
  users.forEach(u => {
    userMap[u._id.toString()] = u;
  });
  
  const formattedTopUsers = topResults.map((result, index) => {
    const user = userMap[result._id.toString()];
    return {
      userId: result._id.toString(),
      name: user?.name || 'Unknown',
      score: result.score,
      percentile: result.bestPercentile,
      rating: result.bestRating,
      rank: index + 1,
      level: user?.currentLevel || 1,
      profileImage: user?.profileImageUrl,
      date: result.date,
    };
  });
  
  const totalUsers = await TestResult.distinct('userId', { testName: testId }).then(ids => ids.length);
  
  let userPosition = null;
  if (userId) {
    userPosition = await getTestUserPosition(userId, testId);
  }
  
  return {
    type: 'test',
    testId,
    topUsers: formattedTopUsers,
    userPosition,
    totalUsers,
  };
}

/**
 * Get user's position in a specific leaderboard
 * @param {string} userId - User ID
 * @param {string} type - Leaderboard type (global, regional, ageGroup, gender)
 * @param {object} filters - Additional filters
 * @returns {Promise<object|null>} - User position data
 */
async function getUserPosition(userId, type, filters = {}) {
  const user = await User.findById(userId);
  if (!user || !user.physicalScore) return null;
  
  let query = { physicalScore: { $gt: user.physicalScore } };
  
  if (type === 'regional') {
    query.state = filters.state || user.state;
  } else if (type === 'ageGroup') {
    const [minAge, maxAge] = filters.ageGroup.split('-').map(Number);
    query.age = { $gte: minAge, $lte: maxAge };
  } else if (type === 'gender') {
    query.gender = filters.gender || user.gender;
  }
  
  const betterCount = await User.countDocuments(query);
  const rank = betterCount + 1;
  
  return {
    userId: userId,
    name: user.name,
    score: user.physicalScore,
    rank,
    level: user.currentLevel || 1,
    profileImage: user.profileImageUrl,
  };
}

/**
 * Get user's position in test-specific leaderboard
 * @param {string} userId - User ID
 * @param {string} testId - Test identifier
 * @returns {Promise<object|null>} - User position data
 */
async function getTestUserPosition(userId, testId) {
  // Get user's best result for this test
  const userBest = await TestResult.findOne({ 
    userId, 
    testName: testId,
    percentile: { $exists: true }
  })
    .sort({ percentile: -1 })
    .lean();
  
  if (!userBest) return null;
  
  // Count how many users have better percentile
  const betterCount = await TestResult.aggregate([
    { $match: { testName: testId, percentile: { $exists: true } } },
    { $sort: { percentile: -1 } },
    { $group: {
      _id: '$userId',
      bestPercentile: { $first: '$percentile' },
    }},
    { $match: { bestPercentile: { $gt: userBest.percentile } } },
    { $count: 'count' },
  ]);
  
  const rank = betterCount.length > 0 ? betterCount[0].count + 1 : 1;
  
  const user = await User.findById(userId).select('name profileImageUrl currentLevel');
  
  return {
    userId: userId,
    name: user?.name || 'Unknown',
    score: userBest.comparisonScore,
    percentile: userBest.percentile,
    rating: userBest.performanceRating,
    rank,
    level: user?.currentLevel || 1,
    profileImage: user?.profileImageUrl,
  };
}

/**
 * Get all ranks for a user
 * @param {string} userId - User ID
 * @returns {Promise<object>} - All ranks
 */
async function getUserRanks(userId) {
  const user = await User.findById(userId);
  if (!user) throw new Error('User not found');
  
  const ranks = {
    global: null,
    regional: null,
    ageGroup: null,
    gender: null,
  };
  
  // Global rank
  if (user.physicalScore > 0) {
    const globalRank = await User.countDocuments({ 
      physicalScore: { $gt: user.physicalScore } 
    }) + 1;
    ranks.global = globalRank;
  }
  
  // Regional rank
  if (user.state && user.physicalScore > 0) {
    const regionalRank = await User.countDocuments({ 
      state: user.state,
      physicalScore: { $gt: user.physicalScore } 
    }) + 1;
    ranks.regional = regionalRank;
  }
  
  // Age group rank
  if (user.age && user.physicalScore > 0) {
    const ageGroup = getAgeGroupForAge(user.age);
    const [minAge, maxAge] = ageGroup.split('-').map(Number);
    const ageGroupRank = await User.countDocuments({ 
      age: { $gte: minAge, $lte: maxAge },
      physicalScore: { $gt: user.physicalScore } 
    }) + 1;
    ranks.ageGroup = ageGroupRank;
  }
  
  // Gender rank
  if (user.gender && user.physicalScore > 0) {
    const genderRank = await User.countDocuments({ 
      gender: user.gender,
      physicalScore: { $gt: user.physicalScore } 
    }) + 1;
    ranks.gender = genderRank;
  }
  
  // Update user document with calculated ranks (for caching)
  user.rank = ranks.global;
  user.regionalRank = ranks.regional;
  user.ageGroupRank = ranks.ageGroup;
  user.genderRank = ranks.gender;
  await user.save();
  
  return ranks;
}

/**
 * Helper: Get age group string for an age
 * @param {number} age - User's age
 * @returns {string} - Age group
 */
function getAgeGroupForAge(age) {
  if (age <= 12) return '10-12';
  if (age <= 15) return '13-15';
  if (age <= 18) return '16-18';
  if (age <= 25) return '19-25';
  if (age <= 35) return '26-35';
  if (age <= 45) return '36-45';
  if (age <= 55) return '46-55';
  return '56+';
}

module.exports = {
  getGlobalLeaderboard,
  getRegionalLeaderboard,
  getAgeGroupLeaderboard,
  getGenderLeaderboard,
  getTestLeaderboard,
  getUserPosition,
  getTestUserPosition,
  getUserRanks,
};


