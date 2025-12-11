const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const {
  submitPsychometricTest,
  getUserPsychometric,
  getPsychometricAnswers,
} = require('../controllers/psychometricController');

/**
 * POST /psychometric/submit
 * Submit psychometric test answers and get results
 */
router.post('/submit', authenticateToken, submitPsychometricTest);

/**
 * GET /psychometric/:userId
 * Get user's psychometric test results
 */
router.get('/:userId', authenticateToken, getUserPsychometric);

/**
 * GET /psychometric/answers/:testId
 * Get detailed answers for a specific test
 */
router.get('/answers/:testId', authenticateToken, getPsychometricAnswers);

module.exports = router;


