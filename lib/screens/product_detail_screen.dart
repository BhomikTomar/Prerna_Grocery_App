import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../services/review_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  bool _isLoading = true;
  Map<String, dynamic>? _product;
  String? _error;
  int _quantity = 1;
  List<dynamic> _reviews = [];
  bool _loadingReviews = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _productService.getProduct(widget.productId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res['success'] == true) {
        _product = res['product'];
      } else {
        _error = res['message']?.toString() ?? 'Failed to load product';
      }
    });
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    final res = await ReviewService().getProductReviews(
      productId: widget.productId,
    );
    if (!mounted) return;
    setState(() {
      _loadingReviews = false;
      if (res['success'] == true) {
        _reviews = res['reviews'] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _product?['name']?.toString() ?? 'Product',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _buildBody(),
      bottomNavigationBar: _error == null && !_isLoading && _product != null
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    _QuantityStepper(
                      quantity: _quantity,
                      onChanged: (q) => setState(() => _quantity = q),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _handleAddToCart,
                          icon: const Icon(Icons.add_shopping_cart_outlined),
                          label: const Text('Add to cart'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    final p = _product!;
    final images = (p['images'] as List<dynamic>?) ?? [];

    num? _toNum(dynamic v) {
      if (v is num) return v;
      if (v is String) return num.tryParse(v);
      return null;
    }

    final priceMap = p['price'];
    final num? selling = priceMap is Map
        ? (_toNum(priceMap['selling']) ?? _toNum(priceMap['amount']))
        : _toNum(priceMap);
    final num? mrp = priceMap is Map
        ? (_toNum(priceMap['mrp']) ??
              _toNum(priceMap['list']) ??
              _toNum(priceMap['original']) ??
              _toNum(priceMap['mrpAmount']))
        : null;
    final String currency = (priceMap is Map && priceMap['currency'] != null)
        ? priceMap['currency'].toString()
        : 'INR';
    final int? discountPct =
        (mrp != null && selling != null && mrp > 0 && selling < mrp)
        ? (((mrp - selling) / mrp) * 100).round()
        : null;

    final inventory = p['inventory']?['quantity'] ?? 0;
    final inStock = (inventory is num ? inventory > 0 : false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Image carousel (with discount badge)
        Stack(
          children: [
            SizedBox(
              height: 260,
              child: PageView.builder(
                itemCount: images.isEmpty ? 1 : images.length,
                itemBuilder: (context, index) {
                  if (images.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  final img = images[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      img.toString(),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (discountPct != null)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$discountPct% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          p['name']?.toString() ?? 'Product',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          p['description']?.toString() ?? '',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '${currency == 'INR' ? '₹' : '$currency '}${(selling ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                if (mrp != null && selling != null && mrp > selling)
                  Text(
                    '${currency == 'INR' ? '₹' : '$currency '}${mrp.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: inStock ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                inStock ? 'In Stock' : 'Out of Stock',
                style: TextStyle(
                  color: inStock ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if ((p['tags'] as List<dynamic>?)?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ...((p['tags'] as List<dynamic>).map(
                (t) => Chip(label: Text(t.toString())),
              )),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reviews',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_loadingReviews)
                  const Center(child: CircularProgressIndicator())
                else if (_reviews.isEmpty)
                  const Text('No reviews yet')
                else
                  ..._reviews.map((r) {
                    final int rating = (r['rating'] ?? 0) as int;
                    final String comment = (r['comment'] ?? '').toString();
                    final String user = (r['user']?['name'] ?? 'User')
                        .toString();
                    final String createdAt = (r['createdAt'] ?? '').toString();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment.isEmpty ? 'No comment' : comment),
                                const SizedBox(height: 2),
                                Text(
                                  '$user • ${createdAt.split('T').first}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 12),
                _ReviewInput(
                  productId: widget.productId,
                  onSubmitted: (rating, comment) async {
                    final res = await ReviewService().addReview(
                      productId: widget.productId,
                      rating: rating,
                      comment: comment,
                    );
                    if (!mounted) return;
                    if (res['success'] == true) {
                      setState(() {
                        _reviews.insert(0, res['review']);
                      });
                    } else {
                      final msg = (res['message'] ?? 'Failed to add review')
                          .toString();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(msg)));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAddToCart() async {
    final productId =
        _product?['_id']?.toString() ?? _product?['id']?.toString();
    if (productId == null) return;

    final res = await _cartService.addToCart(
      productId: productId,
      quantity: _quantity,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      final name = _product?['name']?.toString() ?? 'Product';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $_quantity × $name to cart'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final msg = res['message']?.toString() ?? 'Failed to add to cart';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _ReviewInput extends StatefulWidget {
  final String productId;
  final Future<void> Function(int rating, String comment) onSubmitted;
  const _ReviewInput({required this.productId, required this.onSubmitted});

  @override
  State<_ReviewInput> createState() => _ReviewInputState();
}

class _ReviewInputState extends State<_ReviewInput> {
  int _rating = 0;
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            5,
            (i) => IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                i < _rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: () => setState(() => _rating = i + 1),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Write a review (optional)',
            border: OutlineInputBorder(),
          ),
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _submitting
                ? null
                : () async {
                    if (_rating <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a rating')),
                      );
                      return;
                    }
                    setState(() => _submitting = true);
                    await widget.onSubmitted(_rating, _controller.text.trim());
                    if (!mounted) return;
                    setState(() {
                      _submitting = false;
                      _rating = 0;
                      _controller.clear();
                    });
                  },
            child: Text(_submitting ? 'Submitting...' : 'Submit Review'),
          ),
        ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  const _QuantityStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
            icon: const Icon(Icons.remove),
            splashRadius: 20,
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: () => onChanged(quantity + 1),
            icon: const Icon(Icons.add),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
