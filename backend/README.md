# Prerna Grocery Backend API

A Node.js + Express + MongoDB backend API for the Prerna Grocery Flutter app.

## Features

- 🔐 User authentication (register, login, logout)
- 🛡️ JWT token-based authentication
- 🔒 Password hashing with bcrypt
- 📱 MongoDB database integration
- 🚀 Express.js REST API
- 🛡️ Security middleware (Helmet, CORS, Rate limiting)
- ✅ Input validation
- 📝 Comprehensive error handling

## Quick Start

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Environment Setup

Copy the example environment file and update with your values:

```bash
cp .env.example .env
```

Update the following variables in `.env`:

```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/prerna_grocery?retryWrites=true&w=majority
JWT_SECRET=your_super_secret_jwt_key_here_make_it_long_and_random
```

### 3. Start the Server

**Development mode (with auto-restart):**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

The server will start on `http://localhost:5000`

## API Endpoints

### Authentication

| Method | Endpoint | Description | Access |
|--------|----------|-------------|---------|
| POST | `/api/users/register` | Register new user | Public |
| POST | `/api/users/login` | Login user | Public |
| POST | `/api/users/google-signin` | Google Sign In | Public |
| GET | `/api/users/me` | Get current user | Private |
| PUT | `/api/users/profile` | Update user profile | Private |
| DELETE | `/api/users/delete` | Delete user account | Private |

### Health Check

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | API health status |

## API Usage Examples

### Register User

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

### Get Current User (with token)

```bash
curl -X GET http://localhost:5000/api/users/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Database Schema

### User Model

```javascript
{
  _id: ObjectId,
  name: String (required, 2-50 chars),
  email: String (required, unique, valid email),
  password: String (required, min 6 chars, hashed),
  phone: String (optional, max 15 chars),
  googleId: String (optional, for Google OAuth),
  avatar: String (optional, default empty),
  role: String (enum: 'user', 'admin', default: 'user'),
  isActive: Boolean (default: true),
  lastLogin: Date,
  createdAt: Date,
  updatedAt: Date
}
```

## Security Features

- **Password Hashing**: Uses bcrypt with salt rounds of 12
- **JWT Tokens**: Secure token-based authentication
- **Rate Limiting**: 100 requests per 15 minutes per IP
- **CORS**: Configurable cross-origin resource sharing
- **Helmet**: Security headers
- **Input Validation**: Comprehensive request validation
- **Error Handling**: Secure error responses

## Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `MONGODB_URI` | MongoDB connection string | Yes | - |
| `JWT_SECRET` | Secret key for JWT tokens | Yes | - |
| `JWT_EXPIRE` | JWT token expiration | No | 7d |
| `PORT` | Server port | No | 5000 |
| `NODE_ENV` | Environment mode | No | development |
| `FRONTEND_URL` | Frontend URL for CORS | No | http://localhost:3000 |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | No | - |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret | No | - |

## Flutter App Integration

Update your Flutter app's `AuthService` with the backend URL:

```dart
// In lib/services/auth_service.dart
static const String _baseUrl = 'http://localhost:5000/api';
```

## Deployment

### Heroku

1. Create a Heroku app
2. Set environment variables in Heroku dashboard
3. Deploy using Git

```bash
git add .
git commit -m "Deploy to Heroku"
git push heroku main
```

### Vercel

1. Install Vercel CLI
2. Deploy

```bash
npm i -g vercel
vercel
```

### Railway

1. Connect your GitHub repository
2. Set environment variables
3. Deploy automatically

## Development

### Project Structure

```
backend/
├── config/
│   └── database.js          # MongoDB connection
├── middleware/
│   ├── auth.js             # Authentication middleware
│   └── validation.js       # Input validation
├── models/
│   └── User.js             # User model
├── routes/
│   └── auth.js             # Authentication routes
├── .env.example            # Environment variables template
├── package.json            # Dependencies
├── server.js               # Main server file
└── README.md               # This file
```

### Adding New Features

1. Create new models in `models/`
2. Add routes in `routes/`
3. Create middleware in `middleware/`
4. Update validation as needed

## Troubleshooting

### Common Issues

1. **MongoDB Connection Error**
   - Check your MongoDB URI
   - Ensure your IP is whitelisted in MongoDB Atlas
   - Verify network connectivity

2. **JWT Token Issues**
   - Ensure JWT_SECRET is set
   - Check token expiration
   - Verify token format in requests

3. **CORS Errors**
   - Update FRONTEND_URL in environment variables
   - Check CORS configuration

## Support

For issues and questions:
1. Check the logs in the console
2. Verify environment variables
3. Test API endpoints with Postman/curl
4. Check MongoDB connection

## License

MIT License - feel free to use this code for your projects!
