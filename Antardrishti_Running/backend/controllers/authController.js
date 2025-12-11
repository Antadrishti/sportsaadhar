const User = require('../models/User');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { uploadImage } = require('../services/cloudinaryService');
const { updateStreak } = require('../services/streakService');
const { checkAchievements } = require('../services/achievementService');

// Generate JWT token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: '30d', // Token expires in 30 days
  });
};

// Generate a mock request ID for Aadhaar verification
const generateMockRequestId = (aadhaarNumber) => {
  return crypto.randomBytes(16).toString('hex') + '_' + aadhaarNumber;
};

// Mock OTP code that will be accepted
const MOCK_OTP_CODE = '123456';

// Valid gender options
const VALID_GENDERS = ['Male', 'Female', 'Other'];

// Valid disability options
const VALID_DISABILITIES = ['None', 'Visual', 'Hearing', 'Locomotor', 'Intellectual', 'Multiple'];

// Send OTP for Aadhaar verification (mock implementation)
const sendOTPController = async (req, res) => {
  try {
    const { aadhaarNumber } = req.body;

    // Validation
    if (!aadhaarNumber) {
      return res.status(400).json({ error: 'Please provide Aadhaar number' });
    }

    // Validate Aadhaar number format (12 digits)
    const cleanAadhaar = aadhaarNumber.trim().replace(/\D/g, '');
    if (cleanAadhaar.length !== 12) {
      return res.status(400).json({ error: 'Please provide a valid 12-digit Aadhaar number' });
    }

    // Generate mock request ID (simulating OTP sent to Aadhaar-linked phone)
    const requestId = generateMockRequestId(cleanAadhaar);

    console.log(`Mock OTP sent for Aadhaar: ${cleanAadhaar.substring(0, 4)}XXXXXXXX`);

    res.json({
      requestId: requestId,
      message: 'OTP sent to Aadhaar-linked mobile number',
    });
  } catch (error) {
    console.error('Send OTP error:', error);
    res.status(500).json({ error: error.message || 'Failed to send OTP' });
  }
};

// Verify OTP and login or redirect to registration
const verifyOTPController = async (req, res) => {
  try {
    const { requestId, code, aadhaarNumber } = req.body;

    // Validation
    if (!requestId || !code || !aadhaarNumber) {
      return res.status(400).json({ error: 'Please provide requestId, code, and aadhaarNumber' });
    }

    // Mock OTP verification - only accept "123456"
    if (code !== MOCK_OTP_CODE) {
      return res.status(400).json({ error: 'Invalid OTP. Please enter 123456' });
    }

    // Clean Aadhaar number
    const cleanAadhaar = aadhaarNumber.trim().replace(/\D/g, '');
    if (cleanAadhaar.length !== 12) {
      return res.status(400).json({ error: 'Invalid Aadhaar number format' });
    }

    // Check if user exists by Aadhaar number
    console.log(`[OTP Verification] Checking for user with Aadhaar: "${cleanAadhaar}" (length: ${cleanAadhaar.length})`);
    const user = await User.findOne({ aadhaarNumber: cleanAadhaar });
    
    if (user) {
      console.log(`[OTP Verification] User found. ID: ${user._id}, Name: ${user.name}`);
    } else {
      console.log(`[OTP Verification] No user found. User needs to register.`);
    }

    if (user) {
      // User exists - generate token and return user data
      const token = generateToken(user._id);
      
      // ============ STREAK UPDATE ON LOGIN ============
      let streakData = null;
      try {
        streakData = await updateStreak(user._id.toString());
        
        // Check for streak-related achievements
        if (streakData.streakUpdated) {
          await checkAchievements(user._id.toString(), 'streak_update', {
            streak: streakData.streak,
          });
        }
      } catch (streakError) {
        console.error('Error updating streak on login:', streakError);
        // Continue login even if streak update fails
      }
      
      res.json({
        id: user._id.toString(),
        name: user.name,
        aadhaarNumber: user.aadhaarNumber,
        age: user.age,
        height: user.height,
        weight: user.weight,
        gender: user.gender,
        address: user.address,
        city: user.city,
        state: user.state,
        pincode: user.pincode,
        disability: user.disability,
        phoneNumber: user.phoneNumber,
        email: user.email || '',
        profileImageUrl: user.profileImageUrl || '',
        token,
        requiresRegistration: false,
        // Include streak data if updated
        streakUpdate: streakData ? {
          streak: streakData.streak,
          streakUpdated: streakData.streakUpdated,
          xpEarned: streakData.xpEarned,
          milestoneReached: streakData.milestoneReached,
        } : null,
      });
    } else {
      // User doesn't exist - return special status to redirect to registration
      res.json({
        requestId,
        aadhaarNumber: cleanAadhaar,
        requiresRegistration: true,
        message: 'Aadhaar verified. Please complete registration.',
      });
    }
  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({ error: error.message || 'Failed to verify OTP' });
  }
};

// Complete registration after Aadhaar OTP verification
const completeRegistration = async (req, res) => {
  try {
    const { 
      name, 
      aadhaarNumber, 
      requestId, 
      age, 
      height, 
      weight, 
      gender, 
      address, 
      city, 
      state, 
      pincode, 
      disability,
      phoneNumber,
      email
    } = req.body;

    // Validation - phoneNumber is now mandatory
    if (!name || !aadhaarNumber || !requestId || !age || !height || !weight || !gender || !address || !city || !state || !pincode || !phoneNumber) {
      return res.status(400).json({ 
        error: 'Please provide all required fields: name, aadhaarNumber, requestId, age, height, weight, gender, address, city, state, pincode, phoneNumber' 
      });
    }

    // Clean Aadhaar number
    const cleanAadhaar = aadhaarNumber.trim().replace(/\D/g, '');
    if (cleanAadhaar.length !== 12) {
      return res.status(400).json({ error: 'Invalid Aadhaar number format' });
    }

    // Validate phone number (10 digits)
    const cleanPhone = phoneNumber.trim().replace(/\D/g, '');
    if (cleanPhone.length !== 10) {
      return res.status(400).json({ error: 'Please provide a valid 10-digit phone number' });
    }

    // Validate email format if provided
    if (email && email.trim()) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        return res.status(400).json({ error: 'Invalid email format' });
      }
    }

    // Validate age
    const ageNum = parseInt(age);
    if (isNaN(ageNum) || ageNum < 1 || ageNum > 120) {
      return res.status(400).json({ error: 'Age must be between 1 and 120' });
    }

    // Validate height (in cm)
    const heightNum = parseFloat(height);
    if (isNaN(heightNum) || heightNum < 50 || heightNum > 300) {
      return res.status(400).json({ error: 'Height must be between 50 and 300 cm' });
    }

    // Validate weight (in kg)
    const weightNum = parseFloat(weight);
    if (isNaN(weightNum) || weightNum < 10 || weightNum > 500) {
      return res.status(400).json({ error: 'Weight must be between 10 and 500 kg' });
    }

    // Validate gender
    if (!VALID_GENDERS.includes(gender)) {
      return res.status(400).json({ error: 'Gender must be Male, Female, or Other' });
    }

    // Validate disability (optional, default to 'None')
    const disabilityValue = disability || 'None';
    if (!VALID_DISABILITIES.includes(disabilityValue)) {
      return res.status(400).json({ error: 'Invalid disability value' });
    }

    // Check if user already exists
    // IMPORTANT: This check must match verifyOTPController exactly
    // The Aadhaar number is already cleaned and validated above
    console.log(`[Registration] Checking for existing user with Aadhaar: "${cleanAadhaar}"`);
    
    // Use the exact same query as verifyOTPController
    const userExists = await User.findOne({ aadhaarNumber: cleanAadhaar });
    
    if (userExists) {
      console.log(`[Registration] ❌ User already exists! Aadhaar: ${userExists.aadhaarNumber}, ID: ${userExists._id}, Name: ${userExists.name}`);
      return res.status(400).json({ 
        error: 'This Aadhaar number is already registered. Please login instead.' 
      });
    }
    
    console.log(`[Registration] ✅ No existing user found. Proceeding with registration for Aadhaar: ${cleanAadhaar}`);

    // Validate profile image is provided (mandatory)
    if (!req.file) {
      return res.status(400).json({ error: 'Profile image is required' });
    }

    // Upload profile image to Cloudinary
    let profileImageUrl;
    try {
      profileImageUrl = await uploadImage(req.file);
    } catch (imageError) {
      console.error('Image upload error:', imageError);
      return res.status(500).json({ error: 'Failed to upload profile image. Please try again.' });
    }

    // Double-check user doesn't exist right before creation (race condition protection)
    const finalCheck = await User.findOne({ aadhaarNumber: cleanAadhaar });
    if (finalCheck) {
      console.log(`[Registration] Race condition detected - user found just before creation. Aadhaar: ${cleanAadhaar}`);
      return res.status(400).json({ 
        error: 'This Aadhaar number is already registered. Please login instead.' 
      });
    }

    // Create new user
    console.log(`[Registration] Creating new user with Aadhaar: ${cleanAadhaar}`);
    const user = await User.create({
      name: name.trim(),
      aadhaarNumber: cleanAadhaar, // Ensure this is exactly 12 digits, no spaces
      age: ageNum,
      height: heightNum,
      weight: weightNum,
      gender: gender,
      address: address.trim(),
      city: city.trim(),
      state: state.trim(),
      pincode: pincode.trim(),
      disability: disabilityValue,
      phoneNumber: cleanPhone,
      email: email ? email.toLowerCase().trim() : null,
      profileImageUrl: profileImageUrl,
    });
    
    console.log(`[Registration] User created successfully. ID: ${user._id}, Aadhaar: ${user.aadhaarNumber}`);

    // Generate token
    const token = generateToken(user._id);

    // Return user data
    res.status(201).json({
      id: user._id.toString(),
      name: user.name,
      aadhaarNumber: user.aadhaarNumber,
      age: user.age,
      height: user.height,
      weight: user.weight,
      gender: user.gender,
      address: user.address,
      city: user.city,
      state: user.state,
      pincode: user.pincode,
      disability: user.disability,
      phoneNumber: user.phoneNumber,
      email: user.email || '',
      profileImageUrl: user.profileImageUrl || '',
      token,
    });
  } catch (error) {
    console.error('Complete registration error:', error);
    console.error('Error details:', {
      code: error.code,
      name: error.name,
      message: error.message,
      keyPattern: error.keyPattern,
      keyValue: error.keyValue
    });
    
    // Handle duplicate key error from MongoDB unique constraint
    if (error.code === 11000 || error.name === 'MongoServerError') {
      // Check if it's a duplicate key error on aadhaarNumber
      if (error.keyPattern && error.keyPattern.aadhaarNumber) {
        console.log(`[Registration] Duplicate key error detected for Aadhaar: ${error.keyValue?.aadhaarNumber || cleanAadhaar}`);
        return res.status(400).json({ 
          error: 'This Aadhaar number is already registered. Please login instead.' 
        });
      }
      
      // Check if it's a duplicate key error on email (null email issue)
      if (error.keyPattern && error.keyPattern.email) {
        console.log(`[Registration] Duplicate key error detected for email: ${error.keyValue?.email}`);
        console.log(`[Registration] This is likely due to a non-sparse unique index on email field.`);
        console.log(`[Registration] Run: npm run fix-email-index to fix this issue.`);
        return res.status(500).json({ 
          error: 'Registration failed due to database configuration. Please run "npm run fix-email-index" in the backend directory to fix this issue, or contact support.' 
        });
      }
    }
    
    // Handle validation errors
    if (error.name === 'ValidationError') {
      const firstError = Object.values(error.errors)[0];
      return res.status(400).json({ 
        error: firstError?.message || 'Validation error during registration' 
      });
    }
    
    res.status(500).json({ error: 'Server error during registration. Please try again.' });
  }
};

module.exports = {
  sendOTP: sendOTPController,
  verifyOTP: verifyOTPController,
  completeRegistration,
};
