const express = require('express');
const { protect } = require('../middleware/auth');
const Order = require('../models/Order');
const Cart = require('../models/Cart');
const Product = require('../models/Product');

const router = express.Router();

// Generate unique order number
const generateOrderNumber = () => {
  const prefix = 'PM-';
  const randomString = Math.random().toString(36).substring(2, 10).toUpperCase();
  return prefix + randomString;
};

// @route   POST /api/orders
// @desc    Create a new order from cart
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const { deliveryAddress, paymentMethod = 'OnLine' } = req.body;

    // Get user's cart
    const cart = await Cart.findOne({ user: req.user._id }).populate('items.product');
    if (!cart || cart.items.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: 'Cart is empty' 
      });
    }

    // Validate delivery address
    if (!deliveryAddress || !deliveryAddress.street || !deliveryAddress.city || 
        !deliveryAddress.state || !deliveryAddress.pincode) {
      return res.status(400).json({ 
        success: false, 
        message: 'Complete delivery address is required' 
      });
    }

    // Group items by seller
    const sellerGroups = {};
    let totalSubtotal = 0;

    for (const item of cart.items) {
      const product = item.product;
      if (!product) {
        return res.status(400).json({ 
          success: false, 
          message: `Product ${item.product} not found` 
        });
      }

      const sellerId = product.seller || product.sellerId;
      if (!sellerId) {
        return res.status(400).json({ 
          success: false, 
          message: `Product ${product.name} has no seller` 
        });
      }

      if (!sellerGroups[sellerId]) {
        sellerGroups[sellerId] = {
          sellerId: sellerId,
          items: [],
          subtotal: 0
        };
      }

      const itemTotal = item.price * item.quantity;
      sellerGroups[sellerId].items.push({
        productId: product._id,
        name: product.name,
        quantity: item.quantity,
        price: item.price
      });
      sellerGroups[sellerId].subtotal += itemTotal;
      totalSubtotal += itemTotal;
    }

    // Create orders for each seller
    const createdOrders = [];
    const orderNumber = generateOrderNumber();

    for (const [sellerId, group] of Object.entries(sellerGroups)) {
      const orderData = {
        orderNumber: `${orderNumber}-${sellerId}`,
        buyerId: req.user._id,
        sellerId: sellerId,
        items: group.items,
        pricing: {
          subtotal: group.subtotal,
          tax: 0, // You can add tax calculation logic here
          delivery: 0, // You can add delivery charges logic here
          total: group.subtotal
        },
        delivery: {
          address: deliveryAddress,
          expectedDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days from now
        },
        payment: {
          method: paymentMethod,
          status: 'pending',
          transactionId: null
        },
        status: 'placed'
      };

      const order = new Order(orderData);
      await order.save();
      createdOrders.push(order);
    }

    // Clear the cart after successful order creation
    await Cart.findOneAndUpdate(
      { user: req.user._id },
      { items: [] }
    );

    res.status(201).json({
      success: true,
      message: 'Order placed successfully',
      data: {
        orders: createdOrders,
        totalAmount: totalSubtotal
      }
    });

  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error while creating order' 
    });
  }
});

// @route   GET /api/orders
// @desc    Get orders with optional filters; supports sellerId filter for seller analytics
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const { sellerId, buyerId, status, limit = 20, page = 1 } = req.query;

    const filter = {};
    
    // If no specific buyerId provided, default to current user's orders
    if (buyerId) {
      filter.buyerId = buyerId;
    } else if (!sellerId) {
      filter.buyerId = req.user._id;
    }
    
    if (sellerId) filter.sellerId = sellerId;
    if (status) filter.status = status;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const orders = await Order.find(filter)
      .populate('buyerId', 'name email')
      .populate('sellerId', 'name email')
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

// @route   GET /api/orders/:id
// @desc    Get order by ID
// @access  Private
router.get('/:id', protect, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('buyerId', 'name email')
      .populate('sellerId', 'name email')
      .populate('items.productId', 'name images');

    if (!order) {
      return res.status(404).json({ 
        success: false, 
        message: 'Order not found' 
      });
    }

    // Check if user has access to this order
    if (order.buyerId._id.toString() !== req.user._id.toString() && 
        order.sellerId._id.toString() !== req.user._id.toString()) {
      return res.status(403).json({ 
        success: false, 
        message: 'Access denied' 
      });
    }

    res.json({
      success: true,
      data: order
    });
  } catch (error) {
    console.error('Error fetching order:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error while fetching order' 
    });
  }
});

// @route   PUT /api/orders/:id/status
// @desc    Update order status
// @access  Private
router.put('/:id/status', protect, async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['placed', 'confirmed', 'shipped', 'delivered', 'cancelled'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid status' 
      });
    }

    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ 
        success: false, 
        message: 'Order not found' 
      });
    }

    // Check if user has permission to update this order
    if (order.sellerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ 
        success: false, 
        message: 'Only seller can update order status' 
      });
    }

    order.status = status;
    await order.save();

    res.json({
      success: true,
      message: 'Order status updated successfully',
      data: order
    });
  } catch (error) {
    console.error('Error updating order status:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Server error while updating order status' 
    });
  }
});

module.exports = router;


