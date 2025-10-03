const twilio = require('twilio');

// Twilio configuration
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

// Initialize Twilio client
const client = twilio(accountSid, authToken);

// Send verification email
const sendVerificationEmail = async (email) => {
  try {
    const verification = await client.verify.v2
      .services(verifyServiceSid)
      .verifications
      .create({
        to: email,
        channel: 'email'
      });
    
    return {
      success: true,
      sid: verification.sid,
      status: verification.status
    };
  } catch (error) {
    console.error('Twilio verification error:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

// Verify email code
const verifyEmailCode = async (email, code) => {
  try {
    const verificationCheck = await client.verify.v2
      .services(verifyServiceSid)
      .verificationChecks
      .create({
        to: email,
        code: code
      });
    
    return {
      success: verificationCheck.status === 'approved',
      status: verificationCheck.status,
      valid: verificationCheck.valid
    };
  } catch (error) {
    console.error('Twilio verification check error:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

module.exports = {
  sendVerificationEmail,
  verifyEmailCode
};
