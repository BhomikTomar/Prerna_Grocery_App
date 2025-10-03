// Test script for phone verification
require('dotenv').config();
const twilio = require('twilio');

async function testPhone() {
  console.log('Testing phone verification...');
  
  // Debug: Check environment variables
  console.log('TWILIO_ACCOUNT_SID:', process.env.TWILIO_ACCOUNT_SID ? 'Found' : 'Missing');
  console.log('TWILIO_AUTH_TOKEN:', process.env.TWILIO_AUTH_TOKEN ? 'Found' : 'Missing');
  console.log('TWILIO_PHONE_NUMBER:', process.env.TWILIO_PHONE_NUMBER || 'Missing');
  
  // Initialize Twilio client
  const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
  
  // Test SMS sending
  try {
    const message = await client.messages.create({
      body: 'Test SMS from PrernaMart: Your verification code is 123456',
      from: process.env.TWILIO_PHONE_NUMBER,
      to: '+919971385281' // Replace with YOUR real phone number for testing
    });
    
    console.log('✅ SMS sent successfully!');
    console.log('Message ID:', message.sid);
    console.log('Status:', message.status);
  } catch (error) {
    console.log('❌ Failed to send SMS:', error.message);
  }
}

testPhone().catch(console.error);
