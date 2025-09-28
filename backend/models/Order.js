const mongoose = require('mongoose');

const OrderSchema = new mongoose.Schema({
    orderNumber: { type: String, required: true, unique: true },
    buyerId: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
    sellerId: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
    items: [{
        productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
        name: { type: String, required: true },
        quantity: { type: Number, required: true },
        price: { type: Number, required: true },
    }],
    pricing: {
        subtotal: { type: Number, required: true },
        tax: { type: Number, default: 0 },
        delivery: { type: Number, default: 0 },
        total: { type: Number, required: true },
    },
    delivery: {
        address: {
            street: String, city: String, state: String, pincode: String,
        },
        expectedDate: Date,
    },
    payment: {
        method: { type: String, required: true, default: 'OnLine' },
        status: { type: String, enum: ['pending', 'paid', 'failed'], default: 'pending' },
        transactionId: String,
    },
    status: {
        type: String,
        enum: ['placed', 'confirmed', 'shipped', 'delivered', 'cancelled'],
        default: 'placed',
    },
}, { timestamps: true });

OrderSchema.index({ buyerId: 1, sellerId: 1 });

const Order = mongoose.model('Order', OrderSchema);
module.exports = Order;


