const express = require('express');
const User = require('../models/User');
const { protect } = require('../middleware/auth');
const { sendVerificationEmail, generateVerificationCode } = require('../config/email');

const router = express.Router();

// @desc    Send verification email
// @route   POST /api/email/send-verification
// @access  Private
router.post('/send-verification', protect, async (req, res) => {
  try {
    const user = req.user;
    
    // Check if email is already verified
    if (user.isEmailVerified) {
      return res.status(400).json({
        success: false,
        message: 'Email is already verified'
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
        message: 'Verification email sent successfully',
        messageId: result.messageId
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send verification email',
        error: result.error
      });
    }
  } catch (error) {
    console.error('Send verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during email verification'
    });
  }
});

// @desc    Verify email with code
// @route   POST /api/email/verify
// @access  Private
router.post('/verify', protect, async (req, res) => {
  try {
    const { code } = req.body;
    const user = req.user;

    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'Verification code is required'
      });
    }

    // Get user with verification code (explicitly select the verification fields)
    const userWithCode = await User.findById(user._id).select('+verificationCode +verificationCodeExpires');
    
    if (!userWithCode.verificationCode) {
      return res.status(400).json({
        success: false,
        message: 'No verification code found. Please request a new one.'
      });
    }

    // Check if code has expired
    if (userWithCode.verificationCodeExpires < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Verification code has expired. Please request a new one.'
      });
    }

    // Verify the code
    if (userWithCode.verificationCode === code) {
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

      res.status(200).json({
        success: true,
        message: 'Email verified successfully'
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Invalid verification code'
      });
    }
  } catch (error) {
    console.error('Verify email error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during email verification'
    });
  }
});

// @desc    Resend verification email
// @route   POST /api/email/resend-verification
// @access  Private
router.post('/resend-verification', protect, async (req, res) => {
  try {
    const user = req.user;
    
    // Check if email is already verified
    if (user.isEmailVerified) {
      return res.status(400).json({
        success: false,
        message: 'Email is already verified'
      });
    }

    // Generate new verification code
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
        message: 'Verification email resent successfully',
        messageId: result.messageId
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to resend verification email',
        error: result.error
      });
    }
  } catch (error) {
    console.error('Resend verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during email verification'
    });
  }
});

module.exports = router;
