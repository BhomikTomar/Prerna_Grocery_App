const { body, validationResult } = require('express-validator');

// Handle validation errors
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array()
    });
  }
  next();
};

// User registration validation
const validateRegistration = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),
  
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  
  body('name')
    .optional()
    .custom((value) => {
      if (value !== undefined && value !== null && value.trim() !== '') {
        const trimmedValue = value.trim();
        if (trimmedValue.length < 2 || trimmedValue.length > 50) {
          throw new Error('Name must be between 2 and 50 characters');
        }
      }
      return true;
    }),
  
  body('phone')
    .optional()
    .custom((value) => {
      if (value && value.trim() !== '') {
        // Only validate if phone is provided and not empty
        const phoneRegex = /^[\+]?[1-9][\d]{0,15}$/;
        if (!phoneRegex.test(value)) {
          throw new Error('Please provide a valid phone number');
        }
      }
      return true;
    }),
  
  body('userType')
    .optional()
    .isIn(['consumer', 'admin', 'vendor'])
    .withMessage('User type must be consumer, admin, or vendor'),
  
  handleValidationErrors
];

// User login validation
const validateLogin = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),
  
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
  
  handleValidationErrors
];

// Profile update validation
const validateProfileUpdate = [
  body('name')
    .optional()
    .custom((value) => {
      if (value !== undefined && value !== null && value.trim() !== '') {
        const trimmedValue = value.trim();
        if (trimmedValue.length < 2 || trimmedValue.length > 50) {
          throw new Error('Name must be between 2 and 50 characters');
        }
      }
      return true;
    }),
  
  body('phone')
    .optional()
    .custom((value) => {
      if (value && value.trim() !== '') {
        // Only validate if phone is provided and not empty
        const phoneRegex = /^[\+]?[1-9][\d]{0,15}$/;
        if (!phoneRegex.test(value)) {
          throw new Error('Please provide a valid phone number');
        }
      }
      return true;
    }),
  
  handleValidationErrors
];

module.exports = {
  validateRegistration,
  validateLogin,
  validateProfileUpdate,
  handleValidationErrors
};
