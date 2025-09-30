const express = require('express');
const { protect } = require('../middleware/auth');
const Review = require('../models/Review');

const router = express.Router();

// GET /api/reviews/product/:productId - list reviews for a product
router.get('/product/:productId', async (req, res) => {
  try {
    const { productId } = req.params;
    const { limit = 20, page = 1 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [reviews, total] = await Promise.all([
      Review.find({ product: productId })
        .populate('user', 'name email')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .select('-__v'),
      Review.countDocuments({ product: productId }),
    ]);

    res.json({
      success: true,
      data: reviews,
      pagination: {
        current: parseInt(page),
        pages: Math.ceil(total / parseInt(limit)),
        total,
        limit: parseInt(limit),
      },
    });
  } catch (error) {
    console.error('Error fetching reviews:', error);
    res.status(500).json({ success: false, message: 'Server error while fetching reviews' });
  }
});

// POST /api/reviews - create review (authenticated user)
router.post('/', protect, async (req, res) => {
  try {
    const { product, rating, comment } = req.body;
    if (!product || !rating) {
      return res.status(400).json({ success: false, message: 'Product and rating are required' });
    }

    const review = await Review.create({
      product,
      user: req.user._id,
      rating,
      comment: comment || '',
    });

    const populated = await review.populate('user', 'name email');

    res.status(201).json({ success: true, data: populated });
  } catch (error) {
    console.error('Error creating review:', error);
    res.status(500).json({ success: false, message: 'Server error while creating review' });
  }
});

module.exports = router;


