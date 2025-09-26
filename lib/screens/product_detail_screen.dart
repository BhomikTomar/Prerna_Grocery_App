import 'package:flutter/material.dart';
import '../services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  bool _isLoading = true;
  Map<String, dynamic>? _product;
  String? _error;
  int _quantity = 1;

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
    final price =
        p['price']?['selling']?.toString() ??
        p['price']?['amount']?.toString() ??
        '0';
    final currency = p['price']?['currency']?.toString() ?? 'INR';
    final inventory = p['inventory']?['quantity'] ?? 0;
    final inStock = (inventory is num ? inventory > 0 : false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Image carousel (basic)
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
            Text(
              '$currency $price',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
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
      ],
    );
  }

  void _handleAddToCart() {
    final name = _product?['name']?.toString() ?? 'Product';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $_quantity × $name to cart'),
        duration: const Duration(seconds: 2),
      ),
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
