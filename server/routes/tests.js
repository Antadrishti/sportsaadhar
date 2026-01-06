const express = require('express');
const Test = require('../models/Test');
const TestResult = require('../models/TestResult');

const router = express.Router();

// GET /api/tests - Get all available tests
router.get('/', async (req, res) => {
    try {
        const tests = await Test.find({ isActive: true });
        res.json(tests);
    } catch (error) {
        console.error('Tests fetch error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// POST /api/tests/submit - Submit a test result
router.post('/submit', async (req, res) => {
    try {
        const { testName, value, unit, metadata } = req.body;

        if (!testName || value === undefined || !unit) {
            return res.status(400).json({ error: 'testName, value, and unit are required' });
        }

        // Find or create the test type
        let test = await Test.findOne({ name: testName });
        if (!test) {
            test = new Test({ name: testName, unit: unit });
            await test.save();
        }

        // Create test result
        const testResult = new TestResult({
            userId: req.user._id,
            testId: test._id,
            value: value,
            unit: unit,
            metadata: metadata || {},
            takenAt: new Date()
        });

        await testResult.save();

        res.json({
            message: 'Test result saved successfully',
            result: {
                id: testResult._id,
                testName: test.name,
                value: testResult.value,
                unit: testResult.unit,
                takenAt: testResult.takenAt
            }
        });
    } catch (error) {
        console.error('Test submit error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/tests/history - Get user's test history
router.get('/history', async (req, res) => {
    try {
        const results = await TestResult.find({ userId: req.user._id })
            .populate('testId', 'name unit')
            .sort({ takenAt: -1 })
            .limit(100);

        const formattedResults = results.map(r => ({
            id: r._id,
            testName: r.testId?.name || 'Unknown',
            value: r.value,
            unit: r.unit,
            takenAt: r.takenAt
        }));

        res.json(formattedResults);
    } catch (error) {
        console.error('History fetch error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// GET /api/tests/latest/:testName - Get latest result for a specific test
router.get('/latest/:testName', async (req, res) => {
    try {
        const test = await Test.findOne({ name: req.params.testName });
        if (!test) {
            return res.json({ value: null });
        }

        const result = await TestResult.findOne({
            userId: req.user._id,
            testId: test._id
        }).sort({ takenAt: -1 });

        if (!result) {
            return res.json({ value: null });
        }

        res.json({
            value: result.value,
            unit: result.unit,
            takenAt: result.takenAt
        });
    } catch (error) {
        console.error('Latest result fetch error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
