# MongoDB Authentication Backend Setup

## Overview
Your Flutter app now uses MongoDB authentication instead of Firebase. You'll need to create a backend API to handle authentication requests.

## Required Backend Endpoints

### 1. User Registration
**POST** `/users/register`
```json
{
  "email": "user@example.com",
  "password": "hashed_password",
  "name": "John Doe",
  "phone": "+1234567890",
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "John Doe",
    "phone": "+1234567890",
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### 2. User Login
**POST** `/users/login`
```json
{
  "email": "user@example.com",
  "password": "hashed_password"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "name": "John Doe",
    "phone": "+1234567890"
  }
}
```

### 3. Google Sign In
**POST** `/users/google-signin`
```json
{
  "googleToken": "google_id_token"
}
```

### 4. Update Profile
**PUT** `/users/profile`
**Headers:** `Authorization: Bearer <token>`
```json
{
  "name": "Updated Name",
  "phone": "+1234567890"
}
```

## MongoDB Schema Example

```javascript
// User Collection
{
  _id: ObjectId,
  email: String (unique),
  password: String (hashed),
  name: String,
  phone: String,
  googleId: String (optional),
  createdAt: Date,
  updatedAt: Date
}
```

## Backend Technology Options

### Node.js + Express + MongoDB
```bash
npm init -y
npm install express mongoose bcryptjs jsonwebtoken cors dotenv
```

### Python + FastAPI + MongoDB
```bash
pip install fastapi uvicorn motor pymongo bcrypt python-jose
```

### Next.js API Routes + MongoDB
```bash
npx create-next-app@latest
npm install mongodb bcryptjs jsonwebtoken
```

## Environment Variables
Create a `.env` file in your backend:
```
MONGODB_URI=mongodb+srv://YOUR_USERNAME:YOUR_PASSWORD@YOUR_CLUSTER.mongodb.net/YOUR_DATABASE
JWT_SECRET=your_jwt_secret_key
GOOGLE_CLIENT_ID=your_google_client_id
```

## Update Flutter App Configuration

1. **Update the base URL** in `lib/services/auth_service.dart`:
```dart
static const String _baseUrl = 'https://your-backend-api.com/api';
```

2. **Add your MongoDB connection string** to your backend environment variables.

3. **Implement proper JWT token handling** in your backend for secure authentication.

## Security Considerations

1. **Hash passwords** using bcrypt or similar
2. **Use HTTPS** for all API calls
3. **Implement JWT tokens** for session management
4. **Validate input data** on the backend
5. **Use environment variables** for sensitive data
6. **Implement rate limiting** to prevent abuse

## Testing

You can test your API endpoints using tools like:
- Postman
- Insomnia
- curl commands
- Thunder Client (VS Code extension)

## Next Steps

1. Choose your backend technology
2. Set up MongoDB Atlas cluster
3. Implement the required endpoints
4. Update the `_baseUrl` in your Flutter app
5. Test the authentication flow
6. Deploy your backend to a cloud service (Vercel, Heroku, AWS, etc.)
