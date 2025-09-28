import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../services/cart_service.dart';
import '../widgets/categories_section.dart';
import 'login_screen.dart';
import 'search_results_screen.dart';
import 'products_screen.dart';
import 'product_detail_screen.dart';
import 'checkout_screen.dart';
import 'order_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _carouselController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  final Map<_ProductItem, int> _cart = {};
  final CartService _cartService = CartService();
  int _serverCartCount = 0;

  // Categories state
  final CategoryService _categoryService = CategoryService();
  List<dynamic> _categories = [];
  bool _isLoadingCategories = true;

  Map<String, dynamic>? _currentUser;
  bool _isSeller = false;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearchText = false;

  final List<_BannerItem> _banners = const [
    _BannerItem(
      color: Color(0xFFE8F5E9),
      title: 'Fast Delivery',
      subtitle: 'Groceries in minutes',
      icon: Icons.delivery_dining,
    ),
    _BannerItem(
      color: Color(0xFFFFF3E0),
      title: 'Fresh & Quality',
      subtitle: 'Handpicked daily',
      icon: Icons.shopping_basket_outlined,
    ),
    _BannerItem(
      color: Color(0xFFE3F2FD),
      title: 'Great Offers',
      subtitle: 'Save on every order',
      icon: Icons.local_offer_outlined,
    ),
  ];

  // Dynamic products per category (from backend)
  final ProductService _productService = ProductService();
  final Map<String, List<dynamic>> _categoryProducts = {};
  final Set<String> _loadingCategoryIds = {};
  final Map<String, String?> _categoryErrors = {};

  @override
  void initState() {
    super.initState();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_carouselController.hasClients) return;
      final next = (_currentCarouselIndex + 1) % _banners.length;
      _carouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
    _loadCategories();
    _loadCurrentUser();
    _refreshCartCount();
  }

  Future<void> _refreshCartCount() async {
    try {
      final res = await _cartService.getCart();
      if (!mounted) return;
      if (res['success'] == true) {
        final items = (res['cart']?['items'] as List<dynamic>?) ?? [];
        int count = 0;
        for (final it in items) {
          final q = (it is Map && it['quantity'] is int)
              ? it['quantity'] as int
              : 0;
          count += q;
        }
        setState(() => _serverCartCount = count);
      }
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _categoryService.getCategories();
      if (result['success'] && mounted) {
        setState(() {
          _categories = result['categories'] ?? [];
          _isLoadingCategories = false;
        });
        _loadInitialCategoryProducts();
      } else if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  void _loadInitialCategoryProducts() {
    // Fetch first few categories to show on home
    final int maxSections = 4;
    final selected = _categories.take(maxSections).toList();
    for (final cat in selected) {
      final id = cat['_id']?.toString();
      if (id != null) {
        _loadProductsForCategory(id);
      }
    }
  }

  Future<void> _loadProductsForCategory(String categoryId) async {
    if (_loadingCategoryIds.contains(categoryId)) return;
    setState(() {
      _loadingCategoryIds.add(categoryId);
      _categoryErrors.remove(categoryId);
    });
    try {
      final result = await _productService.getProductsByCategory(
        categoryId,
        limit: 10,
      );
      if (!mounted) return;
      setState(() {
        if (result['success'] == true) {
          _categoryProducts[categoryId] = result['products'] ?? [];
        } else {
          _categoryErrors[categoryId] = result['message']?.toString();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoryErrors[categoryId] = 'Failed to load products';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingCategoryIds.remove(categoryId);
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    final auth = AuthService();
    Map<String, dynamic>? user = await auth.getOrFetchCurrentUser();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      final type = (user?['userType'] ?? user?['role'] ?? '')
          .toString()
          .toLowerCase();
      _isSeller = type == 'seller' || type == 'vendor';
    });
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(searchQuery: query),
        ),
      );
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // legacy cart handlers for hardcoded showcase kept for future use

  void _incrementItem(_ProductItem item) {
    setState(() {
      _cart.update(item, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  void _decrementItem(_ProductItem item) {
    setState(() {
      final current = _cart[item] ?? 0;
      if (current <= 1) {
        _cart.remove(item);
      } else {
        _cart[item] = current - 1;
      }
    });
  }

  int get _cartCount => _cart.values.fold(0, (sum, n) => sum + n);
  double get _cartTotal =>
      _cart.entries.fold(0.0, (sum, e) => sum + (e.key.price * e.value));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Prerna',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  onPressed: _openCart,
                ),
                if (_serverCartCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _serverCartCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _showUserMenu,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadCurrentUser,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildCarousel(),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 24),
            CategoriesSection(
              categories: _categories,
              isLoading: _isLoadingCategories,
            ),
            const SizedBox(height: 24),
            ..._buildCategorySections(),
          ],
        ),
      ),
      floatingActionButton: _isSeller
          ? FloatingActionButton.extended(
              onPressed: _openSellerAnalytics,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Seller Analytics'),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              }
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: banner.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(banner.icon, size: 56, color: Colors.black54),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner.subtitle,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentCarouselIndex == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentCarouselIndex == index
                    ? Colors.black87
                    : Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for products...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
          suffixIcon: _hasSearchText
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _hasSearchText = false;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _hasSearchText = value.isNotEmpty;
          });
        },
        onSubmitted: (value) {
          _performSearch();
        },
      ),
    );
  }

  Widget _buildCategoryHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    );
  }

  // legacy hardcoded product list removed (using API instead)

  List<Widget> _buildCategorySections() {
    final List<Widget> sections = [];
    for (final cat in _categories) {
      final id = cat['_id']?.toString();
      final name = cat['name']?.toString() ?? 'Category';
      if (id == null) continue;
      final products = _categoryProducts[id] ?? [];
      final isLoading = _loadingCategoryIds.contains(id);
      final error = _categoryErrors[id];

      sections.add(
        _buildCategoryHeader(
          name,
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductsScreen(categoryId: id, categoryName: name),
              ),
            );
          },
        ),
      );
      sections.add(const SizedBox(height: 12));

      if (isLoading) {
        sections.add(
          const SizedBox(
            height: 170,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      } else if (error != null) {
        sections.add(SizedBox(height: 170, child: Center(child: Text(error))));
      } else if (products.isEmpty) {
        sections.add(
          const SizedBox(
            height: 170,
            child: Center(child: Text('No products')),
          ),
        );
      } else {
        sections.add(_buildHorizontalProductsFromApi(products));
      }

      sections.add(const SizedBox(height: 24));
    }
    return sections;
  }

  Widget _buildHorizontalProductsFromApi(List<dynamic> products) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final p = products[index] as Map<String, dynamic>;
          final price = _extractProductPriceString(p);
          final images = p['images'] as List<dynamic>? ?? [];
          final image = images.isNotEmpty ? images[0] : null;
          final inStock = (p['inventory']?['quantity'] ?? 0) > 0;

          return GestureDetector(
            onTap: () {
              final id = p['_id']?.toString();
              if (id != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(productId: id),
                  ),
                );
              }
            },
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                image.toString(),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stack) =>
                                    const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                      ),
                                    ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p['name']?.toString() ?? 'Product',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹$price',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: inStock ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          inStock ? 'In Stock' : 'Out of Stock',
                          style: TextStyle(
                            color: inStock
                                ? Colors.green[800]
                                : Colors.red[800],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _extractProductPriceString(Map<String, dynamic> product) {
    final price = product['price'];
    if (price is Map) {
      final selling = price['selling'];
      if (selling is num) return selling.toStringAsFixed(2);
      if (selling is String) {
        final parsed = num.tryParse(selling);
        if (parsed != null) return parsed.toStringAsFixed(2);
        return selling; // already formatted string
      }
      final amount = price['amount'];
      if (amount is num) return amount.toStringAsFixed(2);
      if (amount is String) {
        final parsed = num.tryParse(amount);
        if (parsed != null) return parsed.toStringAsFixed(2);
        return amount;
      }
    }
    return '0.00';
  }

  void _openCart() async {
    // Fetch latest cart from backend so newly added items are visible
    final res = await _cartService.getCart();
    if (!mounted) return;
    if (res['success'] == true) {
      final cart = res['cart'] as Map<String, dynamic>?;
      final items = (cart?['items'] as List<dynamic>?) ?? [];
      setState(() {
        _serverCartCount = items.fold<int>(
          0,
          (sum, e) => sum + ((e['quantity'] ?? 0) as int),
        );
      });
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _RemoteCartScreen(items: items)),
      );
      // Refresh count on return to reflect any changes made in cart
      await _refreshCartCount();
    } else {
      final msg = res['message']?.toString() ?? 'Failed to load cart';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _openSellerAnalytics() {
    if (_currentUser == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SellerAnalyticsScreen(
          sellerId: _currentUser!['_id'] ?? _currentUser!['id'],
        ),
      ),
    );
  }

  void _showUserMenu() async {
    final user = await AuthService().getCurrentUser();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(user?['name'] ?? user?['displayName'] ?? 'User'),
              subtitle: Text(user?['email'] ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Order History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    try {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _BannerItem {
  final Color color;
  final String title;
  final String subtitle;
  final IconData icon;
  const _BannerItem({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ProductItem {
  final String name;
  final double price;
  final Color color;
  final String emoji;
  const _ProductItem({
    required this.name,
    required this.price,
    required this.color,
    required this.emoji,
  });
}

class _CartScreen extends StatelessWidget {
  final Map<_ProductItem, int> items;
  final void Function(_ProductItem) onIncrement;
  final void Function(_ProductItem) onDecrement;
  final double total;

  const _CartScreen({
    required this.items,
    required this.onIncrement,
    required this.onDecrement,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: items.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = items.entries.elementAt(index);
                      final product = entry.key;
                      final qty = entry.value;
                      return Container(
                        decoration: BoxDecoration(
                          color: product.color.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Text(
                              product.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => onDecrement(product),
                                  icon: const Icon(Icons.remove),
                                ),
                                Text(
                                  qty.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => onIncrement(product),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(color: Colors.black54),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {},
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _RemoteCartScreen extends StatefulWidget {
  final List<dynamic> items;
  const _RemoteCartScreen({required this.items});

  @override
  State<_RemoteCartScreen> createState() => _RemoteCartScreenState();
}

class _RemoteCartScreenState extends State<_RemoteCartScreen> {
  final CartService _cartService = CartService();
  late List<Map<String, dynamic>> _items;
  bool _updating = false;

  String _extractProductId(Map<String, dynamic> item) {
    final p = item['product'];
    if (p is String) return p;
    if (p is Map && p['_id'] != null) return p['_id'].toString();
    final pid = item['productId'];
    if (pid != null) return pid.toString();
    return '';
  }

  @override
  void initState() {
    super.initState();
    _items = widget.items
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  num get _total {
    num t = 0;
    for (final it in _items) {
      final q = (it['quantity'] ?? 0) as int;
      final p = (it['price'] ?? 0) as num;
      t += q * p;
    }
    return t;
  }

  Future<void> _setQuantity(String productId, int quantity) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      if (quantity <= 0) {
        final res = await _cartService.removeItem(productId: productId);
        if (!mounted) return;
        if (res['success'] == true) {
          setState(() {
            _items.removeWhere(
              (e) => (e['product']?.toString() ?? '') == productId,
            );
          });
        }
      } else {
        final res = await _cartService.updateItem(
          productId: productId,
          quantity: quantity,
        );
        if (!mounted) return;
        if (res['success'] == true) {
          setState(() {
            final idx = _items.indexWhere(
              (e) => (e['product']?.toString() ?? '') == productId,
            );
            if (idx >= 0) _items[idx]['quantity'] = quantity;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _proceedToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = _items.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: !hasItems
          ? const Center(child: Text('Your cart is empty'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final it = _items[index];
                final name = (it['name'] ?? '').toString();
                final img = (it['image'] ?? '').toString();
                final qty = (it['quantity'] ?? 0) as int;
                final price = (it['price'] ?? 0).toString();
                final productId = _extractProductId(it);
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: img.isNotEmpty
                            ? Image.network(
                                img,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹$price',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _updating
                                ? null
                                : () => _setQuantity(productId, qty - 1),
                            icon: const Icon(Icons.remove),
                          ),
                          Text(
                            qty.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            onPressed: _updating
                                ? null
                                : () => _setQuantity(productId, qty + 1),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total', style: TextStyle(color: Colors.black54)),
                Text(
                  '₹${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: hasItems ? _proceedToCheckout : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerAnalyticsScreen extends StatefulWidget {
  final String sellerId;
  const _SellerAnalyticsScreen({required this.sellerId});

  @override
  State<_SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends State<_SellerAnalyticsScreen>
    with TickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _products = [];
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final productsResult = await _productService.getSellerProducts(
      widget.sellerId,
    );
    final ordersResult = await _orderService.getSellerOrders(
      widget.sellerId,
      limit: 10,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (productsResult['success'] == true) {
        _products = productsResult['products'] ?? [];
      }
      if (ordersResult['success'] == true) {
        _orders = ordersResult['orders'] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.inventory), text: 'Products'),
            Tab(icon: Icon(Icons.receipt), text: 'Orders'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _openAddProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildProductsTab(),
                _buildOrdersTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsHeader(),
        const SizedBox(height: 24),
        _buildQuickActions(),
        const SizedBox(height: 24),
        _buildRecentActivity(),
      ],
    );
  }

  Widget _buildProductsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Products',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              '${_products.length} products',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_products.isEmpty)
          const Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No products found', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('Add your first product to get started'),
              ],
            ),
          )
        else
          ..._products.map((prod) {
            final p = prod as Map<String, dynamic>;
            final price =
                (p['price']?['selling']?.toString() ??
                        p['price']?['amount']?.toString() ??
                        '0')
                    .toString();
            final status = (p['status'] ?? '').toString();
            final inventoryQty = (p['inventory']?['quantity'] ?? 0).toString();
            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p['name'] ?? 'Product'),
                  subtitle: Text(
                    '₹$price • Stock: $inventoryQty • ${status.toUpperCase()}',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'active' ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
            );
          }).toList(),
      ],
    );
  }

  Widget _buildOrdersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              '${_orders.length} orders',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_orders.isEmpty)
          const Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No orders found', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('Orders will appear here when customers place them'),
              ],
            ),
          )
        else
          ..._orders.map((ord) {
            final o = ord as Map<String, dynamic>;
            final total = _extractTotalAmount(o).toStringAsFixed(2);
            final currency = _extractCurrency(o);
            final status = (o['status'] ?? '').toString();
            final created = (o['createdAt'] ?? '').toString();
            final orderNo = (o['orderNumber'] ?? '').toString();
            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    orderNo.isNotEmpty ? orderNo : 'Order ${o['_id'] ?? ''}',
                  ),
                  subtitle: Text('$currency $total • ${status.toUpperCase()}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(created.split('T').first),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            );
          }).toList(),
      ],
    );
  }

  Widget _buildStatsHeader() {
    final totalProducts = _products.length;
    final activeProducts = _products
        .where((p) => (p as Map<String, dynamic>)['status'] == 'active')
        .length;
    final totalOrders = _orders.length;

    num revenue = 0;
    for (final ord in _orders) {
      final o = ord as Map<String, dynamic>;
      revenue += _extractTotalAmount(o);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _metric('Products', '$activeProducts/$totalProducts'),
          _metric('Orders', '$totalOrders'),
          _metric('Revenue', '₹${revenue.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _metric(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.add,
                  title: 'Add Product',
                  onTap: _openAddProduct,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.analytics,
                  title: 'View Analytics',
                  onTap: () {
                    // Switch to dashboard tab
                    _tabController.animateTo(0);
                  },
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (_orders.isEmpty && _products.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.timeline, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ..._buildActivityItems(),
        ],
      ),
    );
  }

  List<Widget> _buildActivityItems() {
    List<Widget> items = [];

    // Add recent orders
    for (int i = 0; i < _orders.take(3).length; i++) {
      final order = _orders[i] as Map<String, dynamic>;
      final status = (order['status'] ?? '').toString();
      final total = _extractTotalAmount(order).toStringAsFixed(2);
      final currency = _extractCurrency(order);

      items.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.receipt,
              color: _getStatusColor(status),
              size: 20,
            ),
          ),
          title: Text('New order received'),
          subtitle: Text('$currency $total • ${status.toUpperCase()}'),
          trailing: Text(
            (order['createdAt'] ?? '').toString().split('T').first,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    // Add recent products
    for (int i = 0; i < _products.take(2).length; i++) {
      final product = _products[i] as Map<String, dynamic>;
      final name = product['name'] ?? 'Product';
      final status = (product['status'] ?? '').toString();

      items.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: status == 'active'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory,
              color: status == 'active' ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          title: Text('Product: $name'),
          subtitle: Text('Status: ${status.toUpperCase()}'),
        ),
      );
    }

    return items;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  num _extractTotalAmount(Map<String, dynamic> order) {
    final pricing = order['pricing'];
    if (pricing is Map) {
      final total = pricing['total'];
      if (total is Map) {
        final amount = total['amount'];
        if (amount is num) return amount;
        if (amount is String) {
          final parsed = num.tryParse(amount);
          if (parsed != null) return parsed;
        }
      } else if (total is num) {
        return total;
      } else if (total is String) {
        final parsed = num.tryParse(total);
        if (parsed != null) return parsed;
      }
      final amount = pricing['amount'];
      if (amount is num) return amount;
      if (amount is String) {
        final parsed = num.tryParse(amount);
        if (parsed != null) return parsed;
      }
      // Other possible keys
      final grandTotal = pricing['grandTotal'];
      if (grandTotal is num) return grandTotal;
      if (grandTotal is String) {
        final parsed = num.tryParse(grandTotal);
        if (parsed != null) return parsed;
      }
      final payable = pricing['payable'];
      if (payable is num) return payable;
      if (payable is String) {
        final parsed = num.tryParse(payable);
        if (parsed != null) return parsed;
      }
    }
    final totalAmount = order['totalAmount'];
    if (totalAmount is Map) {
      final amount = totalAmount['amount'];
      if (amount is num) return amount;
      if (amount is String) {
        final parsed = num.tryParse(amount);
        if (parsed != null) return parsed;
      }
    } else if (totalAmount is num) {
      return totalAmount;
    } else if (totalAmount is String) {
      final parsed = num.tryParse(totalAmount);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  String _extractCurrency(Map<String, dynamic> order) {
    final pricing = order['pricing'];
    if (pricing is Map) {
      final total = pricing['total'];
      if (total is Map) {
        final currency = total['currency'];
        if (currency is String && currency.isNotEmpty) return currency;
      }
      final currency = pricing['currency'];
      if (currency is String && currency.isNotEmpty) return currency;
      final cur2 = pricing['totalCurrency'];
      if (cur2 is String && cur2.isNotEmpty) return cur2;
    }
    final totalAmount = order['totalAmount'];
    if (totalAmount is Map) {
      final currency = totalAmount['currency'];
      if (currency is String && currency.isNotEmpty) return currency;
    }
    if (order['currency'] is String &&
        (order['currency'] as String).isNotEmpty) {
      return order['currency'];
    }
    return 'INR';
  }

  void _openAddProduct() async {
    final created = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AddProductScreen(sellerId: widget.sellerId),
      ),
    );
    if (created == true) {
      _loadData();
    }
  }
}

class _AddProductScreen extends StatefulWidget {
  final String sellerId;
  const _AddProductScreen({required this.sellerId});

  @override
  State<_AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<_AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String? _selectedCategoryId;
  bool _submitting = false;
  List<dynamic> _categories = [];

  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final res = await _categoryService.getCategories();
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) _categories = res['categories'] ?? [];
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                items: _categories
                    .map<DropdownMenuItem<String>>(
                      (c) => DropdownMenuItem(
                        value: c['_id'].toString(),
                        child: Text(c['name']?.toString() ?? 'Category'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Select category' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (amount)'),
                validator: (v) {
                  final n = num.tryParse(v?.trim() ?? '');
                  if (n == null) return 'Enter a valid number';
                  if (n < 0) return 'Price cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'Enter a valid integer';
                  if (n < 0) return 'Quantity cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_submitting ? 'Adding...' : 'Add Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final product = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _selectedCategoryId,
      'price': {
        'amount': num.parse(_priceController.text.trim()),
        'currency': 'INR',
      },
      'inventory': {
        'quantity': int.parse(_quantityController.text.trim()),
        'lowStockThreshold': 10,
      },
      'images': [_imageUrlController.text.trim()],
      'tags': [],
      'status': 'active',
    };
    final res = await _productService.createProduct(product);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Failed')),
      );
    }
  }
}
