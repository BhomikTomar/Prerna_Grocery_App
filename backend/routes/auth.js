const express = require('express');
const User = require('../models/User');
const { protect, generateToken } = require('../middleware/auth');
const { validateRegistration, validateLogin, validateProfileUpdate } = require('../middleware/validation');

const router = express.Router();

// @desc    Register user
// @route   POST /api/users/register
// @access  Public
router.post('/register', validateRegistration, async (req, res) => {
  try {
    const { email, password, name, phone, userType } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email address'
      });
    }

    // Create user with your existing schema
    const user = await User.create({
      email,
      password,
      userType: userType || 'consumer',
      isEmailVerified: false,
      name: name || '',
      phone: phone || ''
    });

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      user: {
        id: user._id,
        email: user.email,
        userType: user.userType,
        isEmailVerified: user.isEmailVerified,
        name: user.name,
        phone: user.phone,
        createdAt: user.createdAt
      },
      token
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during registration'
    });
  }
});

// @desc    Login user
// @route   POST /api/users/login
// @access  Public
router.post('/login', validateLogin, async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check for user and include password for comparison
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Check if account is active (using isEmailVerified as status indicator)
    if (user.isEmailVerified === false) {
      // For now, we'll allow login even if email is not verified
      // You can change this behavior later
    }

    // Check password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Generate token
    const token = generateToken(user._id);

    res.status(200).json({
      success: true,
      message: 'Login successful',
      user: {
        id: user._id,
        email: user.email,
        userType: user.userType,
        isEmailVerified: user.isEmailVerified,
        name: user.name,
        phone: user.phone,
        createdAt: user.createdAt
      },
      token
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login'
    });
  }
});

// @desc    Google Sign In
// @route   POST /api/users/google-signin
// @access  Public
router.post('/google-signin', async (req, res) => {
  try {
    const { googleToken } = req.body;

    if (!googleToken) {
      return res.status(400).json({
        success: false,
        message: 'Google token is required'
      });
    }

    // In a real implementation, you would verify the Google token here
    // For now, we'll create a placeholder response
    res.status(501).json({
      success: false,
      message: 'Google Sign In not implemented yet. Please implement Google OAuth verification.'
    });

    // Example implementation (commented out):
    /*
    const { OAuth2Client } = require('google-auth-library');
    const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
    
    const ticket = await client.verifyIdToken({
      idToken: googleToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    
    const payload = ticket.getPayload();
    const { sub: googleId, email, name, picture } = payload;

    // Check if user exists
    let user = await User.findOne({ googleId });
    
    if (!user) {
      // Check if user exists with same email
      user = await User.findOne({ email });
      if (user) {
        // Link Google account to existing user
        user.googleId = googleId;
        user.avatar = picture;
        await user.save();
      } else {
        // Create new user
        user = await User.create({
          name,
          email,
          googleId,
          avatar: picture,
          isEmailVerified: true
        });
      }
    }

    const token = generateToken(user._id);
    await user.updateLastLogin();

    res.status(200).json({
      success: true,
      message: 'Google sign in successful',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        avatar: user.avatar
      },
      token
    });
    */
  } catch (error) {
    console.error('Google sign in error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during Google sign in'
    });
  }
});

// @desc    Get current user
// @route   GET /api/users/me
// @access  Private
router.get('/me', protect, async (req, res) => {
  try {
    res.status(200).json({
      success: true,
      user: req.user
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// @desc    Update user profile
// @route   PUT /api/users/profile
// @access  Private
router.put('/profile', protect, validateProfileUpdate, async (req, res) => {
  try {
    const { name, phone } = req.body;
    const updateData = {};

    if (name) updateData.name = name;
    if (phone) updateData.phone = phone;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      updateData,
      { new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        updatedAt: user.updatedAt
      }
    });
  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during profile update'
    });
  }
});

// @desc    Delete user account
// @route   DELETE /api/users/delete
// @access  Private
router.delete('/delete', protect, async (req, res) => {
  try {
    await User.findByIdAndDelete(req.user._id);

    res.status(200).json({
      success: true,
      message: 'Account deleted successfully'
    });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during account deletion'
    });
  }
});

module.exports = router;
