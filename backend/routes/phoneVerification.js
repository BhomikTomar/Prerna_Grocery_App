const express = require('express');
const User = require('../models/User');
const { protect } = require('../middleware/auth');
const twilio = require('twilio');

const router = express.Router();

// Initialize Twilio client
const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

// @desc    Send phone verification SMS
// @route   POST /api/phone/send-verification
// @access  Private
router.post('/send-verification', protect, async (req, res) => {
  try {
    const { phoneNumber } = req.body;
    const user = req.user;
    
    if (!phoneNumber) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    // Validate phone number format (basic validation)
    const phoneRegex = /^\+[1-9]\d{1,14}$/;
    if (!phoneRegex.test(phoneNumber)) {
      return res.status(400).json({
        success: false,
        message: 'Please enter a valid phone number with country code (e.g., +1234567890)'
      });
    }

    // Check if phone is already verified
    if (user.isPhoneVerified) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is already verified'
      });
    }

    // Generate 6-digit verification code
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store verification code in user document temporarily
    await User.findByIdAndUpdate(user._id, {
      phoneVerificationCode: verificationCode,
      phoneVerificationExpires: new Date(Date.now() + 10 * 60 * 1000), // 10 minutes
      phoneNumber: phoneNumber
    });

    // Send SMS via Twilio
    try {
      const message = await client.messages.create({
        body: `Your PrernaMart verification code is: ${verificationCode}. This code expires in 10 minutes.`,
        from: process.env.TWILIO_PHONE_NUMBER,
        to: phoneNumber
      });

      res.status(200).json({
        success: true,
        message: 'Verification SMS sent successfully',
        messageId: message.sid
      });
    } catch (twilioError) {
      console.error('Twilio SMS error:', twilioError);
      res.status(500).json({
        success: false,
        message: 'Failed to send SMS. Please check the phone number and try again.',
        error: twilioError.message
      });
    }
  } catch (error) {
    console.error('Send phone verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during phone verification'
    });
  }
});

// @desc    Verify phone with code
// @route   POST /api/phone/verify
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

    // Get user with phone verification code
    const userWithCode = await User.findById(user._id).select('+phoneVerificationCode +phoneVerificationExpires');
    
    if (!userWithCode.phoneVerificationCode) {
      return res.status(400).json({
        success: false,
        message: 'No verification code found. Please request a new one.'
      });
    }

    // Check if code has expired
    if (userWithCode.phoneVerificationExpires < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Verification code has expired. Please request a new one.'
      });
    }

    // Verify the code
    if (userWithCode.phoneVerificationCode === code) {
      // Update user's phone verification status and clear verification code
      await User.findByIdAndUpdate(
        user._id,
        { 
          isPhoneVerified: true,
          phoneVerificationCode: undefined,
          phoneVerificationExpires: undefined
        },
        { new: true, runValidators: true }
      );

      res.status(200).json({
        success: true,
        message: 'Phone number verified successfully'
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Invalid verification code'
      });
    }
  } catch (error) {
    console.error('Verify phone error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during phone verification'
    });
  }
});

// @desc    Resend phone verification SMS
// @route   POST /api/phone/resend-verification
// @access  Private
router.post('/resend-verification', protect, async (req, res) => {
  try {
    const user = req.user;
    
    // Check if phone is already verified
    if (user.isPhoneVerified) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is already verified'
      });
    }

    if (!user.phoneNumber) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a phone number first'
      });
    }

    // Generate new verification code
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store verification code in user document temporarily
    await User.findByIdAndUpdate(user._id, {
      phoneVerificationCode: verificationCode,
      phoneVerificationExpires: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
    });

    // Send SMS via Twilio
    try {
      const message = await client.messages.create({
        body: `Your PrernaMart verification code is: ${verificationCode}. This code expires in 10 minutes.`,
        from: process.env.TWILIO_PHONE_NUMBER,
        to: user.phoneNumber
      });

      res.status(200).json({
        success: true,
        message: 'Verification SMS resent successfully',
        messageId: message.sid
      });
    } catch (twilioError) {
      console.error('Twilio SMS error:', twilioError);
      res.status(500).json({
        success: false,
        message: 'Failed to resend SMS. Please check the phone number and try again.',
        error: twilioError.message
      });
    }
  } catch (error) {
    console.error('Resend phone verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during phone verification'
    });
  }
});

module.exports = router;
