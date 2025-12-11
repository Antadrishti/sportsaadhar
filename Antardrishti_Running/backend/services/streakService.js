const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');
const { addXPToUser } = require('./xpService');

/**
 * Streak Service - Low XP Rewards for Daily Activity
 * 
 * Daily Login: 5 XP
 * 7-day streak: +50 XP
 * 14-day streak: +50 XP  
 * 30-day streak: +200 XP
 */

/**
 * Update user's login streak
 * @param {string} userId - User ID
 * @returns {Promise<object>} - Updated streak data
 */
async function updateStreak(userId) {
  const user = await User.findById(userId);
  
  if (!user) {
    throw new Error('User not found');
  }
  
  const now = new Date();
  const lastLogin = user.lastLoginDate;
  
  // Calculate days since last login
  let daysSinceLastLogin = 0;
  if (lastLogin) {
    const diffTime = Math.abs(now - lastLogin);
    daysSinceLastLogin = Math.floor(diffTime / (1000 * 60 * 60 * 24));
  }
  
  let streakUpdated = false;
  let xpEarned = 0;
  let milestoneReached = null;
  
  if (!lastLogin || daysSinceLastLogin === 0) {
    // Same day login - no streak update
    return {
      streak: user.currentStreak,
      streakUpdated: false,
      xpEarned: 0,
      milestoneReached: null,
    };
  } else if (daysSinceLastLogin === 1) {
    // Consecutive day - increment streak
    const oldStreak = user.currentStreak || 0;
    user.currentStreak = oldStreak + 1;
    
    // Update longest streak if needed
    if (user.currentStreak > (user.longestStreak || 0)) {
      user.longestStreak = user.currentStreak;
    }
    
    streakUpdated = true;
    
    // Award daily login XP
    xpEarned = 5;
    
    // Check for streak milestones
    milestoneReached = checkStreakMilestone(user.currentStreak, oldStreak);
    if (milestoneReached) {
      xpEarned += milestoneReached.bonusXP;
    }
  } else {
    // Streak broken - reset to 1
    user.currentStreak = 1;
    streakUpdated = true;
    xpEarned = 5; // Daily login XP
  }
  
  // Update last login date
  user.lastLoginDate = now;
  
  // Update week streak (Monday = 0, Sunday = 6)
  const dayOfWeek = now.getDay();
  const mondayIndex = dayOfWeek === 0 ? 6 : dayOfWeek - 1; // Convert to Mon=0, Sun=6
  user.weekStreak[mondayIndex] = true;
  
  await user.save();
  
  // Award XP if earned
  if (xpEarned > 0) {
    await addXPToUser(userId, xpEarned, 'daily_login');
  }
  
  // Log activity
  await ActivityLog.create({
    userId,
    activityType: 'login',
    metadata: {
      xpEarned,
      streak: user.currentStreak,
    },
  });
  
  return {
    streak: user.currentStreak,
    longestStreak: user.longestStreak,
    streakUpdated,
    xpEarned,
    milestoneReached,
  };
}

/**
 * Check if a streak milestone was reached
 * @param {number} newStreak - New streak value
 * @param {number} oldStreak - Previous streak value
 * @returns {object|null} - Milestone data or null
 */
function checkStreakMilestone(newStreak, oldStreak) {
  const milestones = [
    { days: 7, bonusXP: 50, name: '7-Day Dedication' },
    { days: 14, bonusXP: 50, name: '14-Day Unstoppable' },
    { days: 30, bonusXP: 200, name: '30-Day On Fire' },
    { days: 90, bonusXP: 500, name: '90-Day Eternal Flame' },
  ];
  
  for (const milestone of milestones) {
    if (newStreak === milestone.days && oldStreak < milestone.days) {
      return milestone;
    }
  }
  
  return null;
}

/**
 * Calculate week streak pattern
 * @param {string} userId - User ID
 * @returns {Promise<object>} - Week streak data
 */
async function calculateWeekStreak(userId) {
  const user = await User.findById(userId);
  
  if (!user) {
    throw new Error('User not found');
  }
  
  const weekStreak = user.weekStreak || [false, false, false, false, false, false, false];
  const daysActive = weekStreak.filter(day => day === true).length;
  const isPerfectWeek = daysActive === 7;
  
  return {
    weekStreak,
    daysActive,
    isPerfectWeek,
  };
}

/**
 * Reset weekly streak (called on Monday)
 * @param {string} userId - User ID
 * @returns {Promise<void>}
 */
async function resetWeekStreak(userId) {
  const user = await User.findById(userId);
  
  if (!user) {
    throw new Error('User not found');
  }
  
  user.weekStreak = [false, false, false, false, false, false, false];
  await user.save();
}

/**
 * Get streak statistics for user
 * @param {string} userId - User ID
 * @returns {Promise<object>} - Streak statistics
 */
async function getStreakStats(userId) {
  const user = await User.findById(userId);
  
  if (!user) {
    throw new Error('User not found');
  }
  
  const weekData = await calculateWeekStreak(userId);
  
  return {
    currentStreak: user.currentStreak || 0,
    longestStreak: user.longestStreak || 0,
    weekStreak: weekData.weekStreak,
    daysActiveThisWeek: weekData.daysActive,
    isPerfectWeek: weekData.isPerfectWeek,
    lastLoginDate: user.lastLoginDate,
  };
}

module.exports = {
  updateStreak,
  checkStreakMilestone,
  calculateWeekStreak,
  resetWeekStreak,
  getStreakStats,
};


