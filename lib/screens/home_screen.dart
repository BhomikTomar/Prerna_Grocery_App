import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

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

  final List<_ProductItem> _chocolates = const [
    _ProductItem(
      name: 'Dairy Milk',
      price: 2.49,
      color: Color(0xFFFFEBEE),
      emoji: '🍫',
    ),
    _ProductItem(
      name: 'KitKat',
      price: 1.99,
      color: Color(0xFFEDE7F6),
      emoji: '🍫',
    ),
    _ProductItem(
      name: 'Ferrero',
      price: 4.99,
      color: Color(0xFFE8F5E9),
      emoji: '🍫',
    ),
    _ProductItem(
      name: 'Bounty',
      price: 2.19,
      color: Color(0xFFFFF3E0),
      emoji: '🥥',
    ),
  ];

  final List<_ProductItem> _chips = const [
    _ProductItem(
      name: 'Lays',
      price: 1.49,
      color: Color(0xFFF3E5F5),
      emoji: '🥔',
    ),
    _ProductItem(
      name: 'Pringles',
      price: 2.99,
      color: Color(0xFFE0F7FA),
      emoji: '🥔',
    ),
    _ProductItem(
      name: 'Doritos',
      price: 2.49,
      color: Color(0xFFFFF8E1),
      emoji: '🔺',
    ),
    _ProductItem(
      name: 'Cheetos',
      price: 1.89,
      color: Color(0xFFE8F5E9),
      emoji: '🧀',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentCarouselIndex + 1) % _banners.length;
      _carouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  void _addToCart(_ProductItem item) {
    setState(() {
      _cart.update(item, (value) => value + 1, ifAbsent: () => 1);
    });
  }

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
                if (_cartCount > 0)
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
                        _cartCount.toString(),
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCarousel(),
          const SizedBox(height: 24),
          _buildCategoryHeader('Chocolates'),
          const SizedBox(height: 12),
          _buildHorizontalProducts(_chocolates),
          const SizedBox(height: 24),
          _buildCategoryHeader('Chips'),
          const SizedBox(height: 12),
          _buildHorizontalProducts(_chips),
        ],
      ),
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
            onPageChanged: (index) => setState(() {
              _currentCarouselIndex = index;
            }),
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

  Widget _buildCategoryHeader(String title) {
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
        TextButton(onPressed: () {}, child: const Text('See all')),
      ],
    );
  }

  Widget _buildHorizontalProducts(List<_ProductItem> items) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final qty = _cart[item] ?? 0;
          return Container(
            width: 140,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                Text(
                  item.name,
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
                      '₹${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    qty == 0
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => _addToCart(item),
                            child: const Text('Add'),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => _decrementItem(item),
                                  icon: const Icon(
                                    Icons.remove,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                Text(
                                  qty.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _incrementItem(item),
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CartScreen(
          items: _cart,
          onIncrement: _incrementItem,
          onDecrement: _decrementItem,
          total: _cartTotal,
        ),
      ),
    );
  }

  void _showUserMenu() {
    final user = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(user?.displayName ?? 'User'),
              subtitle: Text(user?.email ?? ''),
            ),
            const Divider(),
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
      await FirebaseAuth.instance.signOut();
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
