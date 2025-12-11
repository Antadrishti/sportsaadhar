const TestResult = require('../models/TestResult');
const User = require('../models/User');
const ActivityLog = require('../models/ActivityLog');
const { getTestCategory } = require('../config/testCategories');
const { 
  calculatePercentile, 
  assignRating, 
  getAgeGroup, 
  normalizeScore,
  updateTestProgress,
  updateUserScores 
} = require('../services/ratingService');
const { calculateXPForTest, calculateImprovementBonus } = require('../services/xpService');
const { checkAchievements } = require('../services/achievementService');
const { getUserRanks } = require('../services/leaderboardService');

// Save a new test result with full gamification integration
const saveTestResult = async (req, res) => {
  try {
    const { 
      testName, 
      testType, 
      distance, 
      timeTaken, 
      speed, 
      pace,
      measuredHeight,
      registeredHeight,
      isHeightVerified,
      jumpHeight,
      jumpType,
      repsCount,
      exerciseType,
      flexibilityAngle,
      flexibilityRating,
      shuttleRunLaps,
      directionChanges,
      averageGpsAccuracy
    } = req.body;
    const userId = req.user.id; // From auth middleware

    // Validation
    if (!testName) {
      return res.status(400).json({
        error: 'Please provide testName',
      });
    }

    // Get user data for age/gender
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // For non-height, non-jump, non-rep, non-flexibility, and non-shuttle tests, validate distance, time, and speed
    if (testType !== 'height' && testType !== 'vertical_jump' && testType !== 'strength_endurance' && testType !== 'flexibility' && testType !== 'agility' && testType !== 'shuttle_run') {
      if (!distance || !timeTaken || !speed) {
        return res.status(400).json({
          error: 'Please provide distance, timeTaken, and speed',
        });
      }
      if (distance <= 0 || timeTaken <= 0 || speed <= 0) {
        return res.status(400).json({
          error: 'Distance, timeTaken, and speed must be positive numbers',
        });
      }
    }

    // Create base test result data
    const testResultData = {
      userId,
      testName: testName.trim(),
      testType: testType || 'running',
      distance: parseFloat(distance || 0),
      timeTaken: parseFloat(timeTaken || 0),
      speed: parseFloat(speed || 0),
      pace: pace ? parseFloat(pace) : undefined,
      date: new Date(),
      gender: user.gender,
      ageGroup: getAgeGroup(user.age),
    };

    // Add test-specific fields
    if (measuredHeight !== undefined) testResultData.measuredHeight = parseFloat(measuredHeight);
    if (registeredHeight !== undefined) testResultData.registeredHeight = parseFloat(registeredHeight);
    if (isHeightVerified !== undefined) testResultData.isHeightVerified = Boolean(isHeightVerified);
    if (jumpHeight !== undefined) testResultData.jumpHeight = parseFloat(jumpHeight);
    if (jumpType !== undefined) testResultData.jumpType = String(jumpType);
    if (repsCount !== undefined) testResultData.repsCount = parseInt(repsCount);
    if (exerciseType !== undefined) testResultData.exerciseType = String(exerciseType);
    if (flexibilityAngle !== undefined) testResultData.flexibilityAngle = parseFloat(flexibilityAngle);
    if (flexibilityRating !== undefined) testResultData.flexibilityRating = String(flexibilityRating);
    if (shuttleRunLaps !== undefined) testResultData.shuttleRunLaps = parseInt(shuttleRunLaps);
    if (directionChanges !== undefined) testResultData.directionChanges = parseInt(directionChanges);
    if (averageGpsAccuracy !== undefined) testResultData.averageGpsAccuracy = parseFloat(averageGpsAccuracy);

    // ============ GAMIFICATION LOGIC ============
    
    // 1. Determine category
    const category = getTestCategory(testName);
    testResultData.category = category;
    
    // 2. Normalize score for comparison
    const comparisonScore = normalizeScore(testName, testResultData);
    testResultData.comparisonScore = comparisonScore;
    
    // 3. Calculate percentile (skip for height measurement)
    let percentile = null;
    let rating = null;
    if (category !== 'measurement') {
      percentile = await calculatePercentile(testName, comparisonScore, testResultData.ageGroup, user.gender);
      rating = assignRating(percentile);
      testResultData.percentile = percentile;
      testResultData.performanceRating = rating;
    }
    
    // 4. Calculate XP rewards
    let totalXP = 0;
    let xpBreakdown = {};
    
    if (category !== 'measurement') {
      const xpData = calculateXPForTest(rating);
      testResultData.xpEarned = xpData.baseXP;
      testResultData.bonusXP = xpData.bonusXP;
      totalXP = xpData.totalXP;
      xpBreakdown = { base: xpData.baseXP, ratingBonus: xpData.bonusXP };
      
      // 5. Check for personal best and calculate improvement
      const previousBest = user.testProgress.find(tp => tp.testId === testName);
      if (previousBest && previousBest.bestScore) {
        const lowerIsBetter = testName.includes('run') || testName.includes('sprint') || testName === 'sit_and_reach';
        const improved = lowerIsBetter 
          ? comparisonScore < previousBest.bestScore
          : comparisonScore > previousBest.bestScore;
        
        if (improved) {
          testResultData.isPersonalBest = true;
          const improvementPercent = Math.abs(((comparisonScore - previousBest.bestScore) / previousBest.bestScore) * 100);
          testResultData.improvementFromLast = improvementPercent;
          
          const improvementBonus = calculateImprovementBonus(improvementPercent);
          testResultData.improvementBonusXP = improvementBonus;
          totalXP += improvementBonus;
          xpBreakdown.improvementBonus = improvementBonus;
        }
      } else {
        // First attempt is automatically personal best
        testResultData.isPersonalBest = true;
      }
    }
    
    // Create test result
    const testResult = await TestResult.create(testResultData);

    // ============ POST-TEST UPDATES ============
    
    if (category !== 'measurement') {
      // 6. Update user's test progress (best + latest 5)
      await updateTestProgress(userId, testName, testResult);
      
      // 7. Update user's tests completed count
      const existingProgress = user.testProgress.find(tp => tp.testId === testName);
      if (!existingProgress || existingProgress.attempts === 0) {
        user.testsCompleted = (user.testsCompleted || 0) + 1;
        await user.save();
      }
      
      // 8. Update category scores and overall physical score
      await updateUserScores(userId);
      
      // 9. Check for achievement unlocks
      const unlockedAchievements = await checkAchievements(userId, 'test_complete', {
        testId: testName,
        rating: rating,
        percentile: percentile,
        isPersonalBest: testResultData.isPersonalBest,
        improvementPercent: testResultData.improvementFromLast,
      });
      
      // 10. Update leaderboard ranks (real-time)
      await getUserRanks(userId);
      
      // 11. Log activity
      await ActivityLog.create({
        userId,
        activityType: 'test_complete',
        metadata: {
          testId: testName,
          testName: testResult.testName,
          xpEarned: totalXP,
          score: comparisonScore,
          rating: rating,
          percentile: percentile,
          isPersonalBest: testResultData.isPersonalBest,
        },
      });
      
      // Prepare response with gamification data
      const responseData = {
        id: testResult._id.toString(),
        testName: testResult.testName,
        testType: testResult.testType,
        distance: testResult.distance,
        timeTaken: testResult.timeTaken,
        speed: testResult.speed,
        pace: testResult.pace,
        date: testResult.date,
        // Gamification data
        performanceRating: rating,
        percentile: percentile,
        xpEarned: totalXP,
        xpBreakdown: xpBreakdown,
        isPersonalBest: testResultData.isPersonalBest,
        improvementPercent: testResultData.improvementFromLast,
        unlockedAchievements: unlockedAchievements,
      };
      
      // Add test-specific fields to response
      if (testResult.measuredHeight !== undefined) responseData.measuredHeight = testResult.measuredHeight;
      if (testResult.registeredHeight !== undefined) responseData.registeredHeight = testResult.registeredHeight;
      if (testResult.isHeightVerified !== undefined) responseData.isHeightVerified = testResult.isHeightVerified;
      if (testResult.jumpHeight !== undefined) responseData.jumpHeight = testResult.jumpHeight;
      if (testResult.jumpType !== undefined) responseData.jumpType = testResult.jumpType;
      if (testResult.repsCount !== undefined) responseData.repsCount = testResult.repsCount;
      if (testResult.exerciseType !== undefined) responseData.exerciseType = testResult.exerciseType;
      if (testResult.flexibilityAngle !== undefined) responseData.flexibilityAngle = testResult.flexibilityAngle;
      if (testResult.flexibilityRating !== undefined) responseData.flexibilityRating = testResult.flexibilityRating;
      if (testResult.shuttleRunLaps !== undefined) responseData.shuttleRunLaps = testResult.shuttleRunLaps;
      if (testResult.directionChanges !== undefined) responseData.directionChanges = testResult.directionChanges;
      if (testResult.averageGpsAccuracy !== undefined) responseData.averageGpsAccuracy = testResult.averageGpsAccuracy;
      
      res.status(201).json({
        success: true,
        message: 'Test result saved successfully',
        testResult: responseData,
      });
    } else {
      // Measurement test (height) - simpler response
      const responseData = {
        id: testResult._id.toString(),
        testName: testResult.testName,
        testType: testResult.testType,
        distance: testResult.distance,
        timeTaken: testResult.timeTaken,
        speed: testResult.speed,
        date: testResult.date,
        measuredHeight: testResult.measuredHeight,
        registeredHeight: testResult.registeredHeight,
        isHeightVerified: testResult.isHeightVerified,
      };
      
      res.status(201).json({
        success: true,
        message: 'Test result saved successfully',
        testResult: responseData,
      });
    }
  } catch (error) {
    console.error('Save test result error:', error);
    res.status(500).json({ error: 'Failed to save test result' });
  }
};

// Get all test results for the authenticated user
const getUserTestResults = async (req, res) => {
  try {
    const userId = req.user.id;
    const { testName, limit = 50 } = req.query;

    // Build query
    const query = { userId };
    if (testName) {
      query.testName = testName;
    }

    // Fetch test results, sorted by date (most recent first)
    const testResults = await TestResult.find(query)
      .sort({ date: -1 })
      .limit(parseInt(limit))
      .lean();

    res.json({
      success: true,
      count: testResults.length,
      testResults: testResults.map((result) => {
        const mapped = {
          id: result._id.toString(),
          testName: result.testName,
          testType: result.testType,
          distance: result.distance,
          timeTaken: result.timeTaken,
          speed: result.speed,
          pace: result.pace,
          date: result.date,
          // Gamification fields
          performanceRating: result.performanceRating,
          percentile: result.percentile,
          category: result.category,
          xpEarned: result.xpEarned,
          bonusXP: result.bonusXP,
          improvementBonusXP: result.improvementBonusXP,
          isPersonalBest: result.isPersonalBest,
          improvementFromLast: result.improvementFromLast,
        };
        // Add test-specific fields if present
        if (result.measuredHeight !== undefined) mapped.measuredHeight = result.measuredHeight;
        if (result.registeredHeight !== undefined) mapped.registeredHeight = result.registeredHeight;
        if (result.isHeightVerified !== undefined) mapped.isHeightVerified = result.isHeightVerified;
        if (result.jumpHeight !== undefined) mapped.jumpHeight = result.jumpHeight;
        if (result.jumpType !== undefined) mapped.jumpType = result.jumpType;
        if (result.repsCount !== undefined) mapped.repsCount = result.repsCount;
        if (result.exerciseType !== undefined) mapped.exerciseType = result.exerciseType;
        if (result.flexibilityAngle !== undefined) mapped.flexibilityAngle = result.flexibilityAngle;
        if (result.flexibilityRating !== undefined) mapped.flexibilityRating = result.flexibilityRating;
        if (result.shuttleRunLaps !== undefined) mapped.shuttleRunLaps = result.shuttleRunLaps;
        if (result.directionChanges !== undefined) mapped.directionChanges = result.directionChanges;
        if (result.averageGpsAccuracy !== undefined) mapped.averageGpsAccuracy = result.averageGpsAccuracy;
        return mapped;
      }),
    });
  } catch (error) {
    console.error('Get user test results error:', error);
    res.status(500).json({ error: 'Failed to fetch test results' });
  }
};

// Get latest test result for a specific test
const getLatestTestResult = async (req, res) => {
  try {
    const userId = req.user.id;
    const { testName } = req.params;

    if (!testName) {
      return res.status(400).json({ error: 'Test name is required' });
    }

    const latestResult = await TestResult.findOne({
      userId,
      testName,
    })
      .sort({ date: -1 })
      .lean();

    if (!latestResult) {
      return res.status(404).json({
        error: 'No test results found for this test',
      });
    }

    const responseData = {
      id: latestResult._id.toString(),
      testName: latestResult.testName,
      testType: latestResult.testType,
      distance: latestResult.distance,
      timeTaken: latestResult.timeTaken,
      speed: latestResult.speed,
      pace: latestResult.pace,
      date: latestResult.date,
    };

    // Add height fields if present
    if (latestResult.measuredHeight !== undefined) {
      responseData.measuredHeight = latestResult.measuredHeight;
    }
    if (latestResult.registeredHeight !== undefined) {
      responseData.registeredHeight = latestResult.registeredHeight;
    }
    if (latestResult.isHeightVerified !== undefined) {
      responseData.isHeightVerified = latestResult.isHeightVerified;
    }

    // Add jump fields if present
    if (latestResult.jumpHeight !== undefined) {
      responseData.jumpHeight = latestResult.jumpHeight;
    }
    if (latestResult.jumpType !== undefined) {
      responseData.jumpType = latestResult.jumpType;
    }

    // Add reps fields if present
    if (latestResult.repsCount !== undefined) {
      responseData.repsCount = latestResult.repsCount;
    }
    if (latestResult.exerciseType !== undefined) {
      responseData.exerciseType = latestResult.exerciseType;
    }

    // Add flexibility fields if present
    if (latestResult.flexibilityAngle !== undefined) {
      responseData.flexibilityAngle = latestResult.flexibilityAngle;
    }
    if (latestResult.flexibilityRating !== undefined) {
      responseData.flexibilityRating = latestResult.flexibilityRating;
    }

    // Add shuttle run fields if present
    if (latestResult.shuttleRunLaps !== undefined) {
      responseData.shuttleRunLaps = latestResult.shuttleRunLaps;
    }
    if (latestResult.directionChanges !== undefined) {
      responseData.directionChanges = latestResult.directionChanges;
    }
    if (latestResult.averageGpsAccuracy !== undefined) {
      responseData.averageGpsAccuracy = latestResult.averageGpsAccuracy;
    }

    res.json({
      success: true,
      testResult: responseData,
    });
  } catch (error) {
    console.error('Get latest test result error:', error);
    res.status(500).json({ error: 'Failed to fetch latest test result' });
  }
};

module.exports = {
  saveTestResult,
  getUserTestResults,
  getLatestTestResult,
};

