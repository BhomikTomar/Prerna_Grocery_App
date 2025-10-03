const nodemailer = require('nodemailer');

// Create transporter using Mailtrap
const createTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: process.env.EMAIL_PORT,
    secure: false, // true for 465, false for other ports
    auth: {
      user: process.env.EMAIL_USERNAME,
      pass: process.env.EMAIL_PASSWORD,
    },
  });
};

// Generate 6-digit verification code
const generateVerificationCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Send verification email
const sendVerificationEmail = async (email, verificationCode) => {
  try {
    const transporter = createTransporter();
    
    const mailOptions = {
      from: process.env.EMAIL_FROM,
      to: email,
      subject: 'Verify Your Email - PrernaMart',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #4CAF50; color: white; padding: 20px; text-align: center;">
            <h1>PrernaMart</h1>
            <h2>Email Verification</h2>
          </div>
          <div style="padding: 30px; background-color: #f9f9f9;">
            <p>Hello,</p>
            <p>Thank you for registering with PrernaMart! To complete your registration and start placing orders, please verify your email address.</p>
            
            <div style="background-color: white; padding: 20px; margin: 20px 0; border-radius: 8px; text-align: center; border: 2px solid #4CAF50;">
              <h3 style="color: #4CAF50; margin: 0;">Your Verification Code</h3>
              <div style="font-size: 32px; font-weight: bold; color: #333; margin: 15px 0; letter-spacing: 5px;">
                ${verificationCode}
              </div>
              <p style="color: #666; margin: 0;">This code will expire in 10 minutes</p>
            </div>
            
            <p>Enter this code in the app to verify your email address.</p>
            <p>If you didn't request this verification, please ignore this email.</p>
            
            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 14px;">
              <p>Best regards,<br>The PrernaMart Team</p>
            </div>
          </div>
        </div>
      `,
    };

    const result = await transporter.sendMail(mailOptions);
    return {
      success: true,
      messageId: result.messageId,
    };
  } catch (error) {
    console.error('Email sending error:', error);
    return {
      success: false,
      error: error.message,
    };
  }
};

module.exports = {
  sendVerificationEmail,
  generateVerificationCode,
};
