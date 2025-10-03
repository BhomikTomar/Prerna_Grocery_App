# Mailtrap Email Verification Setup Guide

## Step 1: Create .env file in backend directory

Create a file named `.env` in your `backend` directory with the following content:

```env
# Database
MONGODB_URI=mongodb://localhost:27017/prerna-mart

# JWT
JWT_SECRET=your_jwt_secret_here

# Server
PORT=5000

# Email Configuration (using Mailtrap for testing)
EMAIL_HOST=sandbox.smtp.mailtrap.io
EMAIL_PORT=2525
EMAIL_USERNAME=0a179403ca6d74
EMAIL_PASSWORD=9265fb67a83066
EMAIL_FROM=PrernaMart <noreply@prernamart.com>

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=digemmv9n
CLOUDINARY_API_KEY=882585223786515
CLOUDINARY_API_SECRET=XOrfpueQisUBVXbcibDI1bu1bG4

# SMS Configuration (Twilio)
TWILIO_ACCOUNT_SID=AC96a8ba810cd249403ee114f7c661d687
TWILIO_AUTH_TOKEN=6d23d8e50558d37cf3532cd76f228973
TWILIO_PHONE_NUMBER=+918178781068
```

## Step 2: Mailtrap Setup (Already Done!)

Your friend has already set up Mailtrap with the credentials above. Mailtrap is perfect for testing email functionality as it:
- ✅ **Captures all emails** sent during development
- ✅ **No real emails sent** to users
- ✅ **Easy to view** verification codes in Mailtrap inbox
- ✅ **Free tier** available for testing

## Step 3: Test the Setup

1. **Create your .env file** in the backend directory with the credentials above

2. **Start your backend server:**
   ```bash
   cd backend
   npm start
   ```

3. **Test the email verification endpoint:**
   ```bash
   # Send verification email
   POST http://localhost:5000/api/email/send-verification
   Headers: Authorization: Bearer YOUR_JWT_TOKEN
   ```

4. **Check Mailtrap inbox** for the verification email:
   - Go to [Mailtrap](https://mailtrap.io/)
   - Login with your friend's credentials
   - Check the inbox for verification emails

5. **Verify the code:**
   ```bash
   # Verify email with code
   POST http://localhost:5000/api/email/verify
   Headers: Authorization: Bearer YOUR_JWT_TOKEN
   Body: {"code": "123456"}
   ```

## Step 4: Test in Flutter App

1. **Run your Flutter app**
2. **Go to Profile → Personal Details**
3. **Click "Verify Email" button**
4. **Check Mailtrap inbox** for verification code
5. **Enter the code and verify**

## Step 5: View Verification Emails

1. **Go to [Mailtrap.io](https://mailtrap.io/)**
2. **Login with credentials:**
   - Username: `0a179403ca6d74`
   - Password: `9265fb67a83066`
3. **Check the inbox** for verification emails
4. **Copy the 6-digit code** from the email
5. **Enter it in the Flutter app**

## Troubleshooting

- ✅ **Make sure your .env file** is in the backend directory
- ✅ **Check Mailtrap inbox** for verification emails
- ✅ **Verify all credentials** are correct in .env
- ✅ **Check backend logs** for any email sending errors
- ✅ **Ensure nodemailer** is installed (`npm install nodemailer`)
