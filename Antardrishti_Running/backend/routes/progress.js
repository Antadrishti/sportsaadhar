const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { authenticateToken } = require('../middleware/auth');
const { getUserXPProgress, addXPToUser } = require('../services/xpService');
const { updateStreak, getStreakStats } = require('../services/streakService');
const { getAllAchievements, unlockAchievement, getUnlockedAchievements, getAchievementProgress } = require('../services/achievementService');
const { updateUserScores } = require('../services/ratingService');

/**
 * GET /progress/:userId
 * Get user's complete progress data
 */
router.get('/:userId', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Get XP progress
    const xpProgress = await getUserXPProgress(userId);
    
    // Get streak stats
    const streakStats = await getStreakStats(userId);
    
    // Get achievement progress
    const achievementProgress = await getAchievementProgress(userId);
    
    // Calculate journey progress
    const journeyProgress = {
      phase: user.testsCompleted >= user.totalTests ? (user.testsCompleted >= 10 ? 3 : 2) : 1,
      testsCompleted: user.testsCompleted,
      totalTests: user.totalTests,
      percentComplete: (user.testsCompleted / user.totalTests) * 100,
    };
    
    res.json({
      success: true,
      progress: {
        xp: xpProgress,
        streak: streakStats,
        journey: journeyProgress,
        achievements: achievementProgress,
        categoryScores: user.categoryScores,
        physicalScore: user.physicalScore,
        ranks: {
          global: user.rank,
          regional: user.regionalRank,
          ageGroup: user.ageGroupRank,
          gender: user.genderRank,
        },
        testProgress: user.testProgress,
      },
    });
  } catch (error) {
    console.error('Error fetching progress:', error);
    res.status(500).json({ error: 'Failed to fetch progress data' });
  }
});

/**
 * POST /progress/update-xp
 * Add XP to user and check for level up
 */
router.post('/update-xp', authenticateToken, async (req, res) => {
  try {
    const { userId, xpAmount, source } = req.body;
    
    if (!userId || !xpAmount) {
      return res.status(400).json({ error: 'userId and xpAmount are required' });
    }
    
    const result = await addXPToUser(userId, xpAmount, source || 'manual');
    
    res.json({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error('Error updating XP:', error);
    res.status(500).json({ error: 'Failed to update XP' });
  }
});

/**
 * POST /progress/update-streak
 * Update daily streak on login
 */
router.post('/update-streak', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }
    
    const result = await updateStreak(userId);
    
    res.json({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error('Error updating streak:', error);
    res.status(500).json({ error: 'Failed to update streak' });
  }
});

/**
 * GET /progress/achievements
 * Get all available achievements with unlock status for user
 */
router.get('/achievements/:userId?', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    
    const achievements = await getAllAchievements(userId);
    
    res.json({
      success: true,
      achievements,
    });
  } catch (error) {
    console.error('Error fetching achievements:', error);
    res.status(500).json({ error: 'Failed to fetch achievements' });
  }
});

/**
 * POST /progress/unlock-achievement
 * Manually unlock an achievement (usually auto-triggered)
 */
router.post('/unlock-achievement', authenticateToken, async (req, res) => {
  try {
    const { userId, achievementId } = req.body;
    
    if (!userId || !achievementId) {
      return res.status(400).json({ error: 'userId and achievementId are required' });
    }
    
    const result = await unlockAchievement(userId, achievementId);
    
    res.json({
      success: true,
      achievement: result,
    });
  } catch (error) {
    console.error('Error unlocking achievement:', error);
    res.status(500).json({ error: error.message || 'Failed to unlock achievement' });
  }
});

/**
 * GET /progress/test-history/:testId
 * Get user's test history (best + latest 5 attempts)
 */
router.get('/test-history/:userId/:testId', authenticateToken, async (req, res) => {
  try {
    const { userId, testId } = req.params;
    
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const testProgress = user.testProgress.find(tp => tp.testId === testId);
    
    if (!testProgress) {
      return res.json({
        success: true,
        testProgress: null,
      });
    }
    
    res.json({
      success: true,
      testProgress: {
        testId: testProgress.testId,
        testName: testProgress.testName,
        bestScore: testProgress.bestScore,
        bestRating: testProgress.bestRating,
        bestPercentile: testProgress.bestPercentile,
        attempts: testProgress.attempts,
        lastAttemptDate: testProgress.lastAttemptDate,
        recentAttempts: testProgress.recentAttempts,
      },
    });
  } catch (error) {
    console.error('Error fetching test history:', error);
    res.status(500).json({ error: 'Failed to fetch test history' });
  }
});

/**
 * GET /progress/category-scores/:userId
 * Get category breakdown
 */
router.get('/category-scores/:userId', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Update scores first (ensures latest data)
    const scores = await updateUserScores(userId);
    
    res.json({
      success: true,
      ...scores,
    });
  } catch (error) {
    console.error('Error fetching category scores:', error);
    res.status(500).json({ error: 'Failed to fetch category scores' });
  }
});

module.exports = router;


