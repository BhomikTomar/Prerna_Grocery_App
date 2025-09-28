const express = require('express');
const { protect } = require('../middleware/auth');
const Cart = require('../models/Cart');
const Product = require('../models/Product');

const router = express.Router();

// Get current user's cart
router.get('/', protect, async (req, res) => {
  try {
    const cart = await Cart.findOne({ user: req.user._id }).populate('items.product', 'name images price');
    res.json({ success: true, data: cart || { user: req.user._id, items: [] } });
  } catch (e) {
    console.error('Error fetching cart:', e);
    res.status(500).json({ success: false, message: 'Server error while fetching cart' });
  }
});

// Add item to cart (or update quantity)
router.post('/add', protect, async (req, res) => {
  try {
    const { productId, quantity = 1 } = req.body;
    if (!productId || quantity <= 0) {
      return res.status(400).json({ success: false, message: 'Invalid product or quantity' });
    }

    const product = await Product.findById(productId).select('name images price');
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    // price at add-to-cart time prefers selling then amount then mrp
    const priceNumber = typeof product.price?.selling === 'number'
      ? product.price.selling
      : (typeof product.price?.amount === 'number' ? product.price.amount : product.price?.mrp || 0);

    let cart = await Cart.findOne({ user: req.user._id });
    if (!cart) {
      cart = new Cart({ user: req.user._id, items: [] });
    }

    const idx = cart.items.findIndex(i => i.product.toString() === productId);
    if (idx >= 0) {
      cart.items[idx].quantity += quantity;
      cart.items[idx].price = priceNumber; // update price snapshot
      cart.items[idx].name = product.name;
      cart.items[idx].image = Array.isArray(product.images) && product.images[0] ? product.images[0] : '';
    } else {
      cart.items.push({
        product: productId,
        quantity,
        price: priceNumber,
        name: product.name,
        image: Array.isArray(product.images) && product.images[0] ? product.images[0] : ''
      });
    }

    await cart.save();
    res.status(201).json({ success: true, data: cart });
  } catch (e) {
    console.error('Error adding to cart:', e);
    res.status(500).json({ success: false, message: 'Server error while adding to cart' });
  }
});

// Update item quantity
router.put('/item/:productId', protect, async (req, res) => {
  try {
    const { productId } = req.params;
    const { quantity } = req.body;
    if (!quantity || quantity <= 0) {
      return res.status(400).json({ success: false, message: 'Quantity must be greater than 0' });
    }
    const cart = await Cart.findOne({ user: req.user._id });
    if (!cart) return res.status(404).json({ success: false, message: 'Cart not found' });
    const idx = cart.items.findIndex(i => i.product.toString() === productId);
    if (idx < 0) return res.status(404).json({ success: false, message: 'Item not found in cart' });
    cart.items[idx].quantity = quantity;
    await cart.save();
    res.json({ success: true, data: cart });
  } catch (e) {
    console.error('Error updating cart item:', e);
    res.status(500).json({ success: false, message: 'Server error while updating cart item' });
  }
});

// Remove item
router.delete('/item/:productId', protect, async (req, res) => {
  try {
    const { productId } = req.params;
    const cart = await Cart.findOne({ user: req.user._id });
    if (!cart) return res.status(404).json({ success: false, message: 'Cart not found' });
    cart.items = cart.items.filter(i => i.product.toString() !== productId);
    await cart.save();
    res.json({ success: true, data: cart });
  } catch (e) {
    console.error('Error removing cart item:', e);
    res.status(500).json({ success: false, message: 'Server error while removing cart item' });
  }
});

// Clear cart
router.delete('/clear', protect, async (req, res) => {
  try {
    const cart = await Cart.findOne({ user: req.user._id });
    if (!cart) return res.status(404).json({ success: false, message: 'Cart not found' });
    cart.items = [];
    await cart.save();
    res.json({ success: true, data: cart });
  } catch (e) {
    console.error('Error clearing cart:', e);
    res.status(500).json({ success: false, message: 'Server error while clearing cart' });
  }
});

module.exports = router;


