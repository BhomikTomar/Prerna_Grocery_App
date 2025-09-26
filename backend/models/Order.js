const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true
  },
  name: {
    type: String,
    required: true
  },
  quantity: {
    type: Number,
    required: true,
    min: [1, 'Quantity must be at least 1']
  },
  price: {
    amount: { type: Number, required: true, min: [0, 'Price cannot be negative'] },
    currency: { type: String, default: 'USD', enum: ['USD', 'EUR', 'GBP', 'INR'] }
  }
}, { _id: false });

const orderSchema = new mongoose.Schema({
  orderNumber: {
    type: String,
    required: true,
    unique: true
  },
  sellerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  buyerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  items: {
    type: [orderItemSchema],
    validate: [arr => arr.length > 0, 'Order must have at least one item']
  },
  pricing: {
    subtotal: {
      amount: { type: Number, default: 0, min: [0, 'Subtotal cannot be negative'] },
      currency: { type: String, default: 'USD', enum: ['USD', 'EUR', 'GBP', 'INR'] }
    },
    shipping: {
      amount: { type: Number, default: 0, min: [0, 'Shipping cannot be negative'] },
      currency: { type: String, default: 'USD', enum: ['USD', 'EUR', 'GBP', 'INR'] }
    },
    tax: {
      amount: { type: Number, default: 0, min: [0, 'Tax cannot be negative'] },
      currency: { type: String, default: 'USD', enum: ['USD', 'EUR', 'GBP', 'INR'] }
    },
    total: {
      amount: { type: Number, required: true, min: [0, 'Total cannot be negative'] },
      currency: { type: String, default: 'USD', enum: ['USD', 'EUR', 'GBP', 'INR'] }
    }
  },
  delivery: {
    address: { type: String },
    eta: { type: Date }
  },
  payment: {
    method: { type: String },
    transactionId: { type: String }
  },
  status: {
    type: String,
    enum: ['placed', 'pending', 'confirmed', 'shipped', 'delivered', 'cancelled'],
    default: 'placed'
  }
}, { timestamps: true });

orderSchema.index({ sellerId: 1, createdAt: -1 });
orderSchema.index({ buyerId: 1, createdAt: -1 });

module.exports = mongoose.model('Order', orderSchema);


