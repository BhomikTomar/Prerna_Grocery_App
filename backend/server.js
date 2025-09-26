const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const connectDB = require('./config/database');
const authRoutes = require('./routes/auth');
const categoryRoutes = require('./routes/categories');
const productRoutes = require('./routes/products');
const orderRoutes = require('./routes/orders');

// Connect to database
connectDB();

const app = express();

// Security middleware
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later.'
  }
});
app.use(limiter);

// CORS configuration
app.use(cors({
  origin: [
    'http://localhost:3000',
    'http://localhost:57493',
    'http://10.0.2.2:3000',
    'http://10.0.2.2:57493',
    'http://192.168.1.XXX:3000', // Replace XXX with your IP
    'http://192.168.1.XXX:57493' // Replace XXX with your IP
  ],
  credentials: true
}));

// Body parser middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/users', authRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Prerna Grocery API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Global error:', err);
  
  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`🚀 Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
  console.log(`📱 API Health Check: http://localhost:${PORT}/api/health`);
  console.log(`🔐 Auth Endpoints:`);
  console.log(`   POST http://localhost:${PORT}/api/users/register`);
  console.log(`   POST http://localhost:${PORT}/api/users/login`);
  console.log(`   GET  http://localhost:${PORT}/api/users/me`);
  console.log(`   PUT  http://localhost:${PORT}/api/users/profile`);
  console.log(`📂 Category Endpoints:`);
  console.log(`   GET  http://localhost:${PORT}/api/categories`);
  console.log(`   GET  http://localhost:${PORT}/api/categories/:id`);
  console.log(`🛍️  Product Endpoints:`);
  console.log(`   GET  http://localhost:${PORT}/api/products`);
  console.log(`   GET  http://localhost:${PORT}/api/products/category/:categoryId`);
  console.log(`   GET  http://localhost:${PORT}/api/products/:id`);
  console.log(`📦 Order Endpoints:`);
  console.log(`   GET  http://localhost:${PORT}/api/orders`);
});
