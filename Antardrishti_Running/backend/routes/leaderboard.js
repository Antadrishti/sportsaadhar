const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const {
  getGlobalLeaderboard,
  getRegionalLeaderboard,
  getAgeGroupLeaderboard,
  getGenderLeaderboard,
  getTestLeaderboard,
  getUserRanks,
} = require('../services/leaderboardService');

/**
 * GET /leaderboard/global
 * Get global leaderboard (top 50 + user position)
 * Query params: userId (optional)
 */
router.get('/global', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.query;
    const limit = parseInt(req.query.limit) || 50;
    
    const leaderboard = await getGlobalLeaderboard(limit, userId);
    
    res.json({
      success: true,
      ...leaderboard,
    });
  } catch (error) {
    console.error('Error fetching global leaderboard:', error);
    res.status(500).json({ error: 'Failed to fetch global leaderboard' });
  }
});

/**
 * GET /leaderboard/regional/:state
 * Get regional leaderboard (top 50 + user position)
 * Query params: userId (optional)
 */
router.get('/regional/:state', authenticateToken, async (req, res) => {
  try {
    const { state } = req.params;
    const { userId } = req.query;
    const limit = parseInt(req.query.limit) || 50;
    
    const leaderboard = await getRegionalLeaderboard(state, limit, userId);
    
    res.json({
      success: true,
      ...leaderboard,
    });
  } catch (error) {
    console.error('Error fetching regional leaderboard:', error);
    res.status(500).json({ error: 'Failed to fetch regional leaderboard' });
  }
});

/**
 * GET /leaderboard/age-group/:group
 * Get age group leaderboard (top 50 + user position)
 * Query params: userId (optional)
 */
router.get('/age-group/:group', authenticateToken, async (req, res) => {
  try {
    const { group } = req.params; // e.g., '10-12', '13-15'
    const { userId } = req.query;
    const limit = parseInt(req.query.limit) || 50;
    
    const leaderboard = await getAgeGroupLeaderboard(group, limit, userId);
    
    res.json({
      success: true,
      ...leaderboard,
    });
  } catch (error) {
    console.error('Error fetching age group leaderboard:', error);
    res.status(500).json({ error: 'Failed to fetch age group leaderboard' });
  }
});

/**
 * GET /leaderboard/gender/:gender
 * Get gender leaderboard (top 50 + user position)
 * Query params: userId (optional)
 */
router.get('/gender/:gender', authenticateToken, async (req, res) => {
  try {
    const { gender } = req.params; // Male, Female, Other
    const { userId } = req.query;
    const limit = parseInt(req.query.limit) || 50;
    
    const leaderboard = await getGenderLeaderboard(gender, limit, userId);
    
    res.json({
      success: true,
      ...leaderboard,
    });
  } catch (error) {
    console.error('Error fetching gender leaderboard:', error);
    res.status(500).json({ error: 'Failed to fetch gender leaderboard' });
  }
});

/**
 * GET /leaderboard/test/:testId
 * Get test-specific leaderboard (top 50 + user position)
 * Query params: userId (optional)
 */
router.get('/test/:testId', authenticateToken, async (req, res) => {
  try {
    const { testId } = req.params;
    const { userId } = req.query;
    const limit = parseInt(req.query.limit) || 50;
    
    const leaderboard = await getTestLeaderboard(testId, limit, userId);
    
    res.json({
      success: true,
      ...leaderboard,
    });
  } catch (error) {
    console.error('Error fetching test leaderboard:', error);
    res.status(500).json({ error: 'Failed to fetch test leaderboard' });
  }
});

/**
 * GET /leaderboard/user-rank/:userId
 * Get user's ranks in ALL categories
 */
router.get('/user-rank/:userId', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    
    const ranks = await getUserRanks(userId);
    
    res.json({
      success: true,
      ranks,
    });
  } catch (error) {
    console.error('Error fetching user ranks:', error);
    res.status(500).json({ error: 'Failed to fetch user ranks' });
  }
});

module.exports = router;


