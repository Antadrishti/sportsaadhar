const PsychometricTest = require('../models/PsychometricTest');
const User = require('../models/User');
const { addXPToUser } = require('../services/xpService');
const { checkAchievements } = require('../services/achievementService');
const ActivityLog = require('../models/ActivityLog');

/**
 * Submit psychometric test results
 * POST /psychometric/submit
 */
const submitPsychometricTest = async (req, res) => {
  try {
    const { answers } = req.body;
    const userId = req.user.id;

    // Validation
    if (!answers || !Array.isArray(answers) || answers.length !== 20) {
      return res.status(400).json({
        error: 'Please provide exactly 20 answers',
      });
    }

    // Validate each answer
    const validSections = ['mental_toughness', 'focus', 'stress', 'teamwork'];
    for (const answer of answers) {
      if (!answer.section || !validSections.includes(answer.section)) {
        return res.status(400).json({
          error: 'Invalid section name',
        });
      }
      if (!answer.question || !answer.answer) {
        return res.status(400).json({
          error: 'Each answer must have question and answer fields',
        });
      }
      if (typeof answer.answer !== 'string' || answer.answer.trim().length < 10) {
        return res.status(400).json({
          error: 'Answers must be at least 10 characters long',
        });
      }
    }

    // Get user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if already completed
    if (user.psychometricCompleted) {
      const existingTest = await PsychometricTest.findOne({ userId }).sort({ completedAt: -1 });
      if (existingTest) {
        return res.json({
          success: true,
          message: 'Psychometric test already completed',
          test: {
            id: existingTest._id.toString(),
            overallScore: existingTest.overallScore,
            sectionScores: existingTest.sectionScores,
            completedAt: existingTest.completedAt,
            alreadyCompleted: true,
          },
        });
      }
    }

    // Hardcoded 70% score for now (future: LLM analysis)
    const overallScore = 70;
    const sectionScores = {
      mental_toughness: 70,
      focus: 70,
      stress: 70,
      teamwork: 70,
    };

    // Create psychometric test document
    const psychometricTest = await PsychometricTest.create({
      userId,
      answers,
      overallScore,
      sectionScores,
      analysisStatus: 'pending',
    });

    // Update user's psychometric status
    user.psychometricCompleted = true;
    user.mentalScore = overallScore;
    await user.save();

    // Award XP (+200 for completing psychometric test)
    const xpData = await addXPToUser(userId, 200, 'psychometric_complete');

    // Check for achievement unlocks
    const unlockedAchievements = await checkAchievements(userId, 'psychometric_complete', {
      score: overallScore,
    });

    // Log activity
    await ActivityLog.create({
      userId,
      activityType: 'psychometric_complete',
      metadata: {
        testId: psychometricTest._id,
        overallScore,
        xpEarned: 200,
      },
    });

    res.status(201).json({
      success: true,
      message: 'Psychometric test completed successfully',
      test: {
        id: psychometricTest._id.toString(),
        overallScore,
        sectionScores,
        completedAt: psychometricTest.completedAt,
      },
      xpEarned: 200,
      levelUp: xpData.levelUp,
      unlockedAchievements,
    });
  } catch (error) {
    console.error('Submit psychometric test error:', error);
    res.status(500).json({ error: 'Failed to submit psychometric test' });
  }
};

/**
 * Get user's psychometric test results
 * GET /psychometric/:userId
 */
const getUserPsychometric = async (req, res) => {
  try {
    const { userId } = req.params;

    // Verify user exists
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Get latest psychometric test
    const psychometricTest = await PsychometricTest.findOne({ userId })
      .sort({ completedAt: -1 })
      .lean();

    if (!psychometricTest) {
      return res.json({
        success: true,
        completed: false,
        test: null,
      });
    }

    res.json({
      success: true,
      completed: true,
      test: {
        id: psychometricTest._id.toString(),
        overallScore: psychometricTest.overallScore,
        sectionScores: psychometricTest.sectionScores,
        completedAt: psychometricTest.completedAt,
        analysisStatus: psychometricTest.analysisStatus,
      },
    });
  } catch (error) {
    console.error('Get user psychometric error:', error);
    res.status(500).json({ error: 'Failed to fetch psychometric test results' });
  }
};

/**
 * Get all answers for a psychometric test (admin/analysis)
 * GET /psychometric/answers/:testId
 */
const getPsychometricAnswers = async (req, res) => {
  try {
    const { testId } = req.params;
    const userId = req.user.id;

    const psychometricTest = await PsychometricTest.findById(testId).lean();

    if (!psychometricTest) {
      return res.status(404).json({ error: 'Psychometric test not found' });
    }

    // Verify ownership
    if (psychometricTest.userId.toString() !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    res.json({
      success: true,
      test: {
        id: psychometricTest._id.toString(),
        answers: psychometricTest.answers,
        overallScore: psychometricTest.overallScore,
        sectionScores: psychometricTest.sectionScores,
        completedAt: psychometricTest.completedAt,
        analysisStatus: psychometricTest.analysisStatus,
      },
    });
  } catch (error) {
    console.error('Get psychometric answers error:', error);
    res.status(500).json({ error: 'Failed to fetch psychometric answers' });
  }
};

module.exports = {
  submitPsychometricTest,
  getUserPsychometric,
  getPsychometricAnswers,
};


