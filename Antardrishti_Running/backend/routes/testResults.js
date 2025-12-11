const express = require('express');
const router = express.Router();
const {
  saveTestResult,
  getUserTestResults,
  getLatestTestResult,
} = require('../controllers/testResultsController');
const auth = require('../middleware/auth');

// All routes require authentication
router.use(auth);

// Save a new test result
router.post('/', saveTestResult);

// Get all test results for the authenticated user
router.get('/', getUserTestResults);

// Get latest test result for a specific test
router.get('/:testName/latest', getLatestTestResult);

module.exports = router;



