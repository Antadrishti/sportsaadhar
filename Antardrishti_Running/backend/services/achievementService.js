const Achievement = require('../models/Achievement');
const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');
const { addXPToUser } = require('./xpService');

/**
 * Achievement Service - 85+ Comprehensive Achievements
 * 
 * Categories: physical, dedication, special, general
 * Rarities: common, rare, epic, legendary
 * Requirements: test_complete, streak, score, count, special, level, improvement, leaderboard
 */

/**
 * Check and unlock achievements for a user after an action
 * @param {string} userId - User ID
 * @param {string} actionType - Type of action (test_complete, level_up, streak_update, etc.)
 * @param {object} actionData - Data about the action
 * @returns {Promise<Array>} - Array of newly unlocked achievements
 */
async function checkAchievements(userId, actionType, actionData = {}) {
  const user = await User.findById(userId);
  if (!user) return [];
  
  const unlockedAchievementIds = user.unlockedAchievements.map(a => a.achievementId);
  const newlyUnlocked = [];
  
  // Get all achievements that haven't been unlocked yet
  const pendingAchievements = await Achievement.find({
    achievementId: { $nin: unlockedAchievementIds },
    isActive: true,
  });
  
  for (const achievement of pendingAchievements) {
    const isUnlocked = await checkAchievementRequirement(
      user,
      achievement,
      actionType,
      actionData
    );
    
    if (isUnlocked) {
      await unlockAchievement(userId, achievement.achievementId);
      newlyUnlocked.push({
        achievementId: achievement.achievementId,
        title: achievement.title,
        description: achievement.description,
        xpReward: achievement.xpReward,
        rarity: achievement.rarity,
        category: achievement.category,
      });
    }
  }
  
  return newlyUnlocked;
}

/**
 * Check if a specific achievement requirement is met
 * @param {object} user - User document
 * @param {object} achievement - Achievement document
 * @param {string} actionType - Type of action
 * @param {object} actionData - Action data
 * @returns {Promise<boolean>} - Whether requirement is met
 */
async function checkAchievementRequirement(user, achievement, actionType, actionData) {
  const req = achievement.requirements;
  
  switch (req.type) {
    case 'test_complete':
      // Check if user completed a specific test
      if (actionType === 'test_complete' && req.testId) {
        return actionData.testId === req.testId;
      }
      // Or completed any test
      if (actionType === 'test_complete' && !req.testId) {
        return true;
      }
      // Or check if test is in user's completed tests
      if (req.testId) {
        return user.testProgress.some(tp => tp.testId === req.testId && tp.attempts > 0);
      }
      break;
      
    case 'score':
      // Check if user achieved a specific rating for a test
      if (actionType === 'test_complete' && req.testId && req.rating) {
        return actionData.testId === req.testId && actionData.rating === req.rating;
      }
      // Or check existing progress
      if (req.testId && req.rating) {
        const testProgress = user.testProgress.find(tp => tp.testId === req.testId);
        return testProgress && testProgress.bestRating === req.rating;
      }
      break;
      
    case 'count':
      // Check if user completed a certain number of tests
      if (req.targetValue) {
        return user.testsCompleted >= req.targetValue;
      }
      break;
      
    case 'streak':
      // Check if user reached a streak milestone
      if (actionType === 'streak_update' && req.targetValue) {
        return user.currentStreak >= req.targetValue;
      }
      if (req.targetValue) {
        return user.currentStreak >= req.targetValue;
      }
      break;
      
    case 'level':
      // Check if user reached a specific level
      if (req.targetValue) {
        return user.currentLevel >= req.targetValue;
      }
      break;
      
    case 'improvement':
      // Check if user improved by a certain percentage
      if (actionType === 'test_complete' && actionData.improvementPercent) {
        return actionData.improvementPercent >= req.targetValue;
      }
      break;
      
    case 'leaderboard':
      // Check if user reached a specific rank
      if (req.targetValue) {
        return user.rank && user.rank <= req.targetValue;
      }
      break;
      
    case 'special':
      // Handle special achievement conditions
      if (achievement.achievementId === 'all_rounder') {
        // Completed all 10 physical tests
        return user.testsCompleted >= 10;
      }
      if (achievement.achievementId === 'perfect_performance') {
        // Gold or better in all completed tests
        const completedTests = user.testProgress.filter(tp => tp.attempts > 0);
        return completedTests.length > 0 && 
               completedTests.every(tp => tp.bestRating === 'gold' || tp.bestRating === 'platinum');
      }
      if (achievement.achievementId === 'platinum_perfection') {
        // Platinum in all completed tests
        const completedTests = user.testProgress.filter(tp => tp.attempts > 0);
        return completedTests.length === 10 && 
               completedTests.every(tp => tp.bestRating === 'platinum');
      }
      if (achievement.achievementId === 'perfect_week') {
        // Login all 7 days in a week
        return user.weekStreak.every(day => day === true);
      }
      if (achievement.achievementId === 'category_master_strength') {
        // Gold in all strength tests
        const strengthTests = ['sit_ups', 'push_ups', 'medicine_ball_throw'];
        return strengthTests.every(testId => {
          const tp = user.testProgress.find(t => t.testId === testId);
          return tp && (tp.bestRating === 'gold' || tp.bestRating === 'platinum');
        });
      }
      if (achievement.achievementId === 'category_master_endurance') {
        // Gold in all endurance tests
        const enduranceTests = ['800m_run', '1600m_run'];
        const userEnduranceTests = user.testProgress.filter(tp => 
          enduranceTests.includes(tp.testId) && tp.attempts > 0
        );
        return userEnduranceTests.length > 0 && 
               userEnduranceTests.every(tp => tp.bestRating === 'gold' || tp.bestRating === 'platinum');
      }
      if (achievement.achievementId === 'category_master_flexibility') {
        // Gold in sit and reach
        const tp = user.testProgress.find(t => t.testId === 'sit_and_reach');
        return tp && (tp.bestRating === 'gold' || tp.bestRating === 'platinum');
      }
      if (achievement.achievementId === 'category_master_agility') {
        // Gold in shuttle run
        const tp = user.testProgress.find(t => t.testId === '4x10_shuttle');
        return tp && (tp.bestRating === 'gold' || tp.bestRating === 'platinum');
      }
      if (achievement.achievementId === 'category_master_speed') {
        // Gold in all speed tests
        const speedTests = ['30m_sprint', 'standing_vertical_jump', 'standing_broad_jump'];
        return speedTests.every(testId => {
          const tp = user.testProgress.find(t => t.testId === testId);
          return tp && (tp.bestRating === 'gold' || tp.bestRating === 'platinum');
        });
      }
      if (achievement.achievementId === 'serial_improver') {
        // Set 5 personal bests
        const pbCount = await ActivityLog.countDocuments({
          userId: user._id,
          activityType: 'test_complete',
          'metadata.isPersonalBest': true,
        });
        return pbCount >= 5;
      }
      if (achievement.achievementId === 'always_improving') {
        // Set 10 personal bests
        const pbCount = await ActivityLog.countDocuments({
          userId: user._id,
          activityType: 'test_complete',
          'metadata.isPersonalBest': true,
        });
        return pbCount >= 10;
      }
      break;
  }
  
  return false;
}

/**
 * Unlock an achievement for a user
 * @param {string} userId - User ID
 * @param {string} achievementId - Achievement ID
 * @returns {Promise<object>} - Unlocked achievement data
 */
async function unlockAchievement(userId, achievementId) {
  const user = await User.findById(userId);
  const achievement = await Achievement.findOne({ achievementId });
  
  if (!user || !achievement) {
    throw new Error('User or achievement not found');
  }
  
  // Check if already unlocked
  const alreadyUnlocked = user.unlockedAchievements.some(
    a => a.achievementId === achievementId
  );
  
  if (alreadyUnlocked) {
    throw new Error('Achievement already unlocked');
  }
  
  // Add to unlocked achievements
  user.unlockedAchievements.push({
    achievementId,
    unlockedAt: new Date(),
    xpEarned: achievement.xpReward,
  });
  
  await user.save();
  
  // Award XP
  await addXPToUser(userId, achievement.xpReward, 'achievement');
  
  // Log activity
  await ActivityLog.create({
    userId,
    activityType: 'achievement_unlock',
    metadata: {
      achievementId,
      xpEarned: achievement.xpReward,
    },
  });
  
  return {
    achievementId,
    title: achievement.title,
    description: achievement.description,
    xpReward: achievement.xpReward,
    rarity: achievement.rarity,
    category: achievement.category,
    unlockedAt: new Date(),
  };
}

/**
 * Get all unlocked achievements for a user
 * @param {string} userId - User ID
 * @returns {Promise<Array>} - Array of unlocked achievements with details
 */
async function getUnlockedAchievements(userId) {
  const user = await User.findById(userId);
  if (!user) return [];
  
  const achievementIds = user.unlockedAchievements.map(a => a.achievementId);
  const achievements = await Achievement.find({ 
    achievementId: { $in: achievementIds } 
  });
  
  const achievementMap = {};
  achievements.forEach(a => {
    achievementMap[a.achievementId] = a;
  });
  
  return user.unlockedAchievements.map(ua => {
    const achievement = achievementMap[ua.achievementId];
    return {
      achievementId: ua.achievementId,
      title: achievement?.title || 'Unknown',
      description: achievement?.description || '',
      icon: achievement?.icon || '',
      category: achievement?.category || 'general',
      rarity: achievement?.rarity || 'common',
      xpReward: ua.xpEarned,
      unlockedAt: ua.unlockedAt,
    };
  });
}

/**
 * Get all available achievements with unlock status
 * @param {string} userId - User ID (optional)
 * @returns {Promise<Array>} - Array of all achievements
 */
async function getAllAchievements(userId = null) {
  const achievements = await Achievement.find({ isActive: true })
    .sort({ rarity: 1, xpReward: 1 });
  
  let unlockedIds = [];
  if (userId) {
    const user = await User.findById(userId);
    if (user) {
      unlockedIds = user.unlockedAchievements.map(a => a.achievementId);
    }
  }
  
  return achievements.map(a => ({
    achievementId: a.achievementId,
    title: a.title,
    description: a.description,
    icon: a.icon,
    category: a.category,
    rarity: a.rarity,
    xpReward: a.xpReward,
    isHidden: a.isHidden,
    isUnlocked: userId ? unlockedIds.includes(a.achievementId) : false,
  }));
}

/**
 * Get achievement progress statistics
 * @param {string} userId - User ID
 * @returns {Promise<object>} - Progress statistics
 */
async function getAchievementProgress(userId) {
  const user = await User.findById(userId);
  if (!user) return null;
  
  const totalAchievements = await Achievement.countDocuments({ isActive: true, isHidden: false });
  const unlockedCount = user.unlockedAchievements.length;
  
  // Count by rarity
  const unlockedIds = user.unlockedAchievements.map(a => a.achievementId);
  const unlockedAchievements = await Achievement.find({ 
    achievementId: { $in: unlockedIds } 
  });
  
  const rarityCount = {
    common: 0,
    rare: 0,
    epic: 0,
    legendary: 0,
  };
  
  unlockedAchievements.forEach(a => {
    rarityCount[a.rarity] = (rarityCount[a.rarity] || 0) + 1;
  });
  
  return {
    total: totalAchievements,
    unlocked: unlockedCount,
    percentComplete: (unlockedCount / totalAchievements) * 100,
    byRarity: rarityCount,
  };
}

module.exports = {
  checkAchievements,
  checkAchievementRequirement,
  unlockAchievement,
  getUnlockedAchievements,
  getAllAchievements,
  getAchievementProgress,
};


