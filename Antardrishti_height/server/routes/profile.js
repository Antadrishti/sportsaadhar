const express = require('express');
const router = express.Router();

// GET /api/profile - Get user profile
router.get('/', async (req, res) => {
    try {
        res.json({
            id: req.user._id,
            username: req.user.username,
            profile: req.user.profile,
            createdAt: req.user.createdAt
        });
    } catch (error) {
        console.error('Profile fetch error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// PUT /api/profile - Update user profile
router.put('/', async (req, res) => {
    try {
        const { age, gender, address, region, pincode } = req.body;

        // Update profile fields
        if (age !== undefined) req.user.profile.age = age;
        if (gender !== undefined) req.user.profile.gender = gender;
        if (address !== undefined) req.user.profile.address = address;
        if (region !== undefined) req.user.profile.region = region;
        if (pincode !== undefined) req.user.profile.pincode = pincode;

        await req.user.save();

        res.json({
            message: 'Profile updated successfully',
            profile: req.user.profile
        });
    } catch (error) {
        console.error('Profile update error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
