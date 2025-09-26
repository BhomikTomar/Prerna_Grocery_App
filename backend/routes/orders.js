const express = require('express');
const Order = require('../models/Order');

const router = express.Router();

// @route   GET /api/orders
// @desc    Get orders with optional filters; supports sellerId filter for seller analytics
// @access  Public (should be protected in real apps)
router.get('/', async (req, res) => {
  try {
    const { sellerId, buyerId, status, limit = 20, page = 1 } = req.query;

    const filter = {};
    if (sellerId) filter.sellerId = sellerId;
    if (buyerId) filter.buyerId = buyerId;
    if (status) filter.status = status;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const orders = await Order.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .select('-__v');

    const total = await Order.countDocuments(filter);

    res.json({
      success: true,
      data: orders,
      pagination: {
        current: parseInt(page),
        pages: Math.ceil(total / parseInt(limit)),
        total,
        limit: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ success: false, message: 'Server error while fetching orders' });
  }
});

module.exports = router;


