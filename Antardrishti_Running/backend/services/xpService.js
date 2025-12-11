const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');

/**
 * XP Service - Conservative XP System with Unlimited Levels
 * 
 * Base XP: 30 per test
 * Rating Bonuses: Bronze: 0, Silver: 20, Gold: 50, Platinum: 100
 * Personal Best Bonus: 20 XP
 * Level System: 1-10 use predefined thresholds, 11+ exponential scaling
 */

// Level thresholds for levels 1-10 (same as existing system)
const LEVEL_THRESHOLDS = {
  1: 0,
  2: 200,
  3: 500,
  4: 1000,
  5: 2000,
  6: 3500,
  7: 5500,
  8: 8000,
  9: 12000,
  10: 20000,
};

// Level titles for levels 1-10
const LEVEL_TITLES = {
  1: 'Rookie',
  2: 'Beginner',
  3: 'Amateur',
  4: 'Rising Star',
  5: 'Competitor',
  6: 'Athlete',
  7: 'Pro Athlete',
  8: 'Elite',
  9: 'Champion',
  10: 'Legend',
};

/**
 * Calculate XP for completing a test based on performance rating
 * @param {string} rating - Performance rating (bronze, silver, gold, platinum)
 * @returns {object} - { baseXP, bonusXP, totalXP }
 */
function calculateXPForTest(rating) {
  const baseXP = 30;
  let bonusXP = 0;
  
  switch (rating) {
    case 'platinum':
      bonusXP = 100;
      break;
    case 'gold':
      bonusXP = 50;
      break;
    case 'silver':
      bonusXP = 20;
      break;
    case 'bronze':
    default:
      bonusXP = 0;
      break;
  }
  
  return {
    baseXP,
    bonusXP,
    totalXP: baseXP + bonusXP,
  };
}

/**
 * Calculate improvement bonus XP
 * @param {number} improvementPercent - Percentage improvement from last attempt
 * @returns {number} - Bonus XP (20 for any positive improvement)
 */
function calculateImprovementBonus(improvementPercent) {
  return improvementPercent > 0 ? 20 : 0;
}

/**
 * Calculate XP required for a given level (with unlimited scaling)
 * @param {number} level - Target level
 * @returns {number} - Total XP required to reach this level
 */
function getXPForLevel(level) {
  if (level <= 1) return 0;
  if (level <= 10) return LEVEL_THRESHOLDS[level];
  
  // For level 11+, use exponential scaling: xpForLevel(n) = 20000 * 1.5^(n-10)
  const baseXP = LEVEL_THRESHOLDS[10]; // 20000
  const multiplier = Math.pow(1.5, level - 10);
  return Math.floor(baseXP * multiplier);
}

/**
 * Calculate level from total XP (with unlimited levels)
 * @param {number} xp - Total XP
 * @returns {number} - Current level
 */
function getLevelForXP(xp) {
  // Check levels 1-10 first
  for (let level = 10; level >= 1; level--) {
    if (xp >= LEVEL_THRESHOLDS[level]) {
      // If we're at level 10 threshold, check if we've exceeded it
      if (level === 10 && xp > LEVEL_THRESHOLDS[10]) {
        // Calculate level beyond 10
        const excessXP = xp - LEVEL_THRESHOLDS[10];
        const baseXP = LEVEL_THRESHOLDS[10];
        
        // Solve for n in: excessXP >= baseXP * (1.5^n - 1)
        // This gives us the additional levels beyond 10
        const additionalLevels = Math.floor(Math.log(excessXP / baseXP + 1) / Math.log(1.5));
        return 10 + additionalLevels;
      }
      return level;
    }
  }
  return 1;
}

/**
 * Get level title
 * @param {number} level - Level number
 * @returns {string} - Level title
 */
function getLevelTitle(level) {
  if (level <= 10) {
    return LEVEL_TITLES[level] || 'Rookie';
  }
  
  // For levels 11+, generate titles
  if (level <= 20) return `Master Lv.${level}`;
  if (level <= 50) return `Grand Master Lv.${level}`;
  if (level <= 100) return `Legend Lv.${level}`;
  return `Immortal Lv.${level}`;
}

/**
 * Check if user leveled up and return level-up data
 * @param {number} oldXP - Previous XP
 * @param {number} newXP - New XP
 * @returns {object|null} - Level-up data or null if no level up
 */
function checkLevelUp(oldXP, newXP) {
  const oldLevel = getLevelForXP(oldXP);
  const newLevel = getLevelForXP(newXP);
  
  if (newLevel > oldLevel) {
    return {
      levelsGained: newLevel - oldLevel,
      oldLevel,
      newLevel,
      newLevelTitle: getLevelTitle(newLevel),
      xpForNextLevel: getXPForLevel(newLevel + 1),
    };
  }
  
  return null;
}

/**
 * Add XP to user and check for level up
 * @param {string} userId - User ID
 * @param {number} xpAmount - Amount of XP to add
 * @param {string} source - Source of XP (test_complete, achievement, streak, etc.)
 * @returns {Promise<object>} - Updated user data with level-up info
 */
async function addXPToUser(userId, xpAmount, source = 'unknown') {
  const user = await User.findById(userId);
  
  if (!user) {
    throw new Error('User not found');
  }
  
  const oldXP = user.currentXP || 0;
  const newXP = oldXP + xpAmount;
  
  // Check for level up
  const levelUpData = checkLevelUp(oldXP, newXP);
  
  // Update user
  user.currentXP = newXP;
  user.totalXPEarned = (user.totalXPEarned || 0) + xpAmount;
  
  if (levelUpData) {
    user.currentLevel = levelUpData.newLevel;
    user.levelTitle = levelUpData.newLevelTitle;
    
    // Log level-up activity
    await ActivityLog.create({
      userId,
      activityType: 'level_up',
      metadata: {
        levelReached: levelUpData.newLevel,
        xpEarned: xpAmount,
      },
    });
  }
  
  await user.save();
  
  return {
    success: true,
    xpAdded: xpAmount,
    currentXP: newXP,
    currentLevel: user.currentLevel,
    levelTitle: user.levelTitle,
    levelUp: levelUpData,
    xpForNextLevel: getXPForLevel(user.currentLevel + 1),
    progressToNextLevel: (newXP - getXPForLevel(user.currentLevel)) / 
                        (getXPForLevel(user.currentLevel + 1) - getXPForLevel(user.currentLevel)),
  };
}

/**
 * Get user's XP progress information
 * @param {string} userId - User ID
 * @returns {Promise<object>} - XP progress data
 */
async function getUserXPProgress(userId) {
  const user = await User.findById(userId);
  
  if (!user) {
    throw new Error('User not found');
  }
  
  const currentXP = user.currentXP || 0;
  const currentLevel = user.currentLevel || 1;
  const xpForCurrentLevel = getXPForLevel(currentLevel);
  const xpForNextLevel = getXPForLevel(currentLevel + 1);
  
  return {
    currentXP,
    currentLevel,
    levelTitle: user.levelTitle || getLevelTitle(currentLevel),
    totalXPEarned: user.totalXPEarned || 0,
    xpForCurrentLevel,
    xpForNextLevel,
    xpInCurrentLevel: currentXP - xpForCurrentLevel,
    xpNeededForNextLevel: xpForNextLevel - currentXP,
    progressToNextLevel: (currentXP - xpForCurrentLevel) / (xpForNextLevel - xpForCurrentLevel),
  };
}

module.exports = {
  calculateXPForTest,
  calculateImprovementBonus,
  getXPForLevel,
  getLevelForXP,
  getLevelTitle,
  checkLevelUp,
  addXPToUser,
  getUserXPProgress,
};


