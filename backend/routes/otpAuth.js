const express = require('express');
const User = require('../models/User');
const { generateToken } = require('../middleware/auth');
const { sendVerificationEmail, generateVerificationCode } = require('../config/email');

const router = express.Router();

// @desc    Send OTP for login
// @route   POST /api/auth/send-otp-login
// @access  Public
router.post('/send-otp-login', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    // Check if user exists
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'No account found with this email address'
      });
    }

    // Generate verification code
    const verificationCode = generateVerificationCode();
    
    // Store verification code in user document temporarily
    await User.findByIdAndUpdate(user._id, {
      verificationCode: verificationCode,
      verificationCodeExpires: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
    });

    // Send verification email via Mailtrap
    const result = await sendVerificationEmail(user.email, verificationCode);
    
    if (result.success) {
      res.status(200).json({
        success: true,
        message: 'OTP sent successfully to your email',
        messageId: result.messageId
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send OTP',
        error: result.error
      });
    }
  } catch (error) {
    console.error('Send OTP login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during OTP sending'
    });
  }
});

// @desc    Verify OTP for login
// @route   POST /api/auth/verify-otp-login
// @access  Public
router.post('/verify-otp-login', async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Email and OTP are required'
      });
    }

    // Find user and get verification code
    const user = await User.findOne({ email }).select('+verificationCode +verificationCodeExpires');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'No account found with this email address'
      });
    }

    if (!user.verificationCode) {
      return res.status(400).json({
        success: false,
        message: 'No OTP found. Please request a new one.'
      });
    }

    // Check if code has expired
    if (user.verificationCodeExpires < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'OTP has expired. Please request a new one.'
      });
    }

    // Verify the code
    if (user.verificationCode === otp) {
      // Update user's email verification status and clear verification code
      await User.findByIdAndUpdate(
        user._id,
        { 
          isEmailVerified: true,
          verificationCode: undefined,
          verificationCodeExpires: undefined
        },
        { new: true, runValidators: true }
      );

      // Generate token
      const token = generateToken(user._id);

      res.status(200).json({
        success: true,
        message: 'Login successful',
        user: {
          id: user._id,
          email: user.email,
          userType: user.userType,
          isEmailVerified: true, // Set to true since OTP login verifies email
          isPhoneVerified: user.isPhoneVerified,
          isProfileComplete: user.isProfileComplete,
          profile: user.profile,
          addresses: user.addresses,
          name: user.name,
          phone: user.phone,
          createdAt: user.createdAt
        },
        token
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Invalid OTP code'
      });
    }
  } catch (error) {
    console.error('Verify OTP login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during OTP verification'
    });
  }
});

module.exports = router;
