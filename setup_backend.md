# 🚀 Backend Setup Guide

## Quick Start

### 1. Navigate to Backend Directory
```bash
cd backend
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Set Up Environment Variables
```bash
# Copy the example environment file
cp .env.example .env

# Edit the .env file with your MongoDB connection string
# Replace the MONGODB_URI with your actual MongoDB Atlas connection string
```

### 4. Update MongoDB Connection
Edit the `.env` file and replace:
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/prerna_grocery?retryWrites=true&w=majority
```

With your actual MongoDB Atlas connection string from your cluster.

### 5. Start the Server
```bash
# Development mode (with auto-restart)
npm run dev

# Or production mode
npm start
```

### 6. Test the API
Open your browser and go to: `http://localhost:5000/api/health`

You should see:
```json
{
  "success": true,
  "message": "Prerna Grocery API is running",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "environment": "development"
}
```

## 🧪 Test Authentication

### Register a User
```bash
curl -X POST http://localhost:5000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePass123",
    "phone": "+1234567890"
  }'
```

### Login User
```bash
curl -X POST http://localhost:5000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass123"
  }'
```

## 📱 Flutter App Integration

Your Flutter app is already configured to use `http://localhost:5000/api` as the backend URL.

### For Production/Deployment:
1. Deploy your backend to a cloud service (Heroku, Vercel, Railway, etc.)
2. Update the `_baseUrl` in `lib/services/auth_service.dart`:
   ```dart
   static const String _baseUrl = 'https://your-deployed-api.com/api';
   ```

## 🔧 Troubleshooting

### MongoDB Connection Issues
- Check your MongoDB Atlas connection string
- Ensure your IP is whitelisted in MongoDB Atlas
- Verify your username and password are correct

### Port Already in Use
If port 5000 is already in use, change the PORT in your `.env` file:
```env
PORT=3001
```

### CORS Issues
If you get CORS errors, update the `FRONTEND_URL` in your `.env` file to match your Flutter app's URL.

## 🎉 You're Ready!

Once the backend is running, your Flutter app will be able to:
- ✅ Register new users
- ✅ Login existing users  
- ✅ Store user sessions
- ✅ Update user profiles
- ✅ Logout users

The backend includes:
- 🔐 JWT authentication
- 🛡️ Password hashing
- 📊 MongoDB integration
- 🚀 RESTful API endpoints
- 🛡️ Security middleware
- ✅ Input validation
