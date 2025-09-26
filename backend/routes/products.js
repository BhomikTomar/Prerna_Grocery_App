const express = require('express');
const Product = require('../models/Product');
const Category = require('../models/Category');
const { protect } = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/products
// @desc    Get all products with optional filtering and search
// @access  Public
router.get('/', async (req, res) => {
  try {
    const { category, status, search, sellerId, limit = 20, page = 1 } = req.query;
    
    // Build filter object
    const filter = {};
    if (category) filter.category = category;
    if (status) filter.status = status;
    else filter.status = 'active'; // Default to active products only

    // Filter by seller if provided
    if (sellerId) filter.sellerId = sellerId;

    // Add search functionality
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { tags: { $in: [new RegExp(search, 'i')] } }
      ];
    }

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const products = await Product.find(filter)
      .populate('category', 'name slug')
      .populate('sellerId', 'name email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .select('-__v');

    const total = await Product.countDocuments(filter);

    res.json({
      success: true,
      data: products,
      pagination: {
        current: parseInt(page),
        pages: Math.ceil(total / parseInt(limit)),
        total: total,
        limit: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching products'
    });
  }
});

// @route   GET /api/products/category/:categoryId
// @desc    Get products by category
// @access  Public
router.get('/category/:categoryId', async (req, res) => {
  try {
    const { categoryId } = req.params;
    const { limit = 20, page = 1 } = req.query;

    // Verify category exists
    const category = await Category.findById(categoryId);
    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const products = await Product.find({ 
      category: categoryId, 
      status: 'active' 
    })
      .populate('category', 'name slug')
      .populate('sellerId', 'name email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .select('-__v');

    const total = await Product.countDocuments({ 
      category: categoryId, 
      status: 'active' 
    });

    res.json({
      success: true,
      data: products,
      category: {
        id: category._id,
        name: category.name,
        slug: category.slug
      },
      pagination: {
        current: parseInt(page),
        pages: Math.ceil(total / parseInt(limit)),
        total: total,
        limit: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Error fetching products by category:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching products by category'
    });
  }
});

// @route   GET /api/products/:id
// @desc    Get single product
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id)
      .populate('category', 'name slug')
      .populate('sellerId', 'name email')
      .select('-__v');

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    res.json({
      success: true,
      data: product
    });
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching product'
    });
  }
});

// @route   POST /api/products
// @desc    Create a product (seller only)
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const user = req.user;
    if (!user || !['seller', 'vendor', 'admin'].includes(user.userType)) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const {
      name,
      description,
      category,
      price = {},
      inventory = {},
      images,
      tags,
      status
    } = req.body;

    // Accept both app and website payloads
    const amountFromApp = typeof price.amount === 'number' ? price.amount : undefined;
    const mrpFromWeb = typeof price.mrp === 'number' ? price.mrp : undefined;
    const sellingFromWeb = typeof price.selling === 'number' ? price.selling : undefined;
    const amountForApp = amountFromApp ?? sellingFromWeb ?? mrpFromWeb;
    const currencyForApp = price.currency || 'INR';

    if (!name || !description || !category || typeof amountForApp !== 'number' || !inventory?.quantity || !images || images.length === 0) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    const product = await Product.create({
      sellerId: user._id,
      name,
      description,
      category,
      // Persist in website-native shape
      price: {
        mrp: mrpFromWeb ?? amountForApp,
        selling: sellingFromWeb ?? amountForApp
      },
      inventory: {
        quantity: inventory.quantity,
        unit: inventory.unit || 'piece'
      },
      images,
      tags: tags || [],
      status: status || 'active'
    });

    // For app clients expecting amount/currency/lowStockThreshold, enrich response on the fly
    const responseData = product.toObject();
    responseData.price = {
      ...responseData.price,
      amount: amountForApp,
      currency: currencyForApp
    };
    responseData.inventory = {
      ...responseData.inventory,
      lowStockThreshold: inventory.lowStockThreshold ?? 10
    };

    res.status(201).json({ success: true, data: responseData });
  } catch (error) {
    console.error('Error creating product:', error);
    res.status(500).json({ success: false, message: 'Server error while creating product' });
  }
});

module.exports = router;
