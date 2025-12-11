const express = require('express');
const router = express.Router();
const { sendOTP, verifyOTP, completeRegistration } = require('../controllers/authController');
const uploadSingle = require('../middleware/upload');

// @route   POST /auth/send-otp
// @desc    Send mock OTP for Aadhaar verification
// @access  Public
router.post('/send-otp', sendOTP);

// @route   POST /auth/verify-otp
// @desc    Verify OTP (accepts "123456") and login or indicate registration needed
// @access  Public
router.post('/verify-otp', verifyOTP);

// @route   POST /auth/complete-registration
// @desc    Complete user registration after Aadhaar OTP verification
// @access  Public
router.post('/complete-registration', uploadSingle, completeRegistration);

module.exports = router;
