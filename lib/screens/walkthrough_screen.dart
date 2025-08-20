import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<WalkthroughPage> _pages = [
    WalkthroughPage(
      title: "Quick Delivery",
      subtitle: "Get your groceries delivered in minutes, not hours",
      doodle: "🛒",
      color: Color(0xFF4CAF50),
    ),
    WalkthroughPage(
      title: "Fresh & Quality",
      subtitle: "Handpicked fresh products from local stores",
      doodle: "🥬",
      color: Color(0xFF8BC34A),
    ),
    WalkthroughPage(
      title: "Easy Shopping",
      subtitle: "Browse, order, and track your delivery with ease",
      doodle: "📱",
      color: Color(0xFF2E7D32),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Bottom section with indicators and buttons
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(WalkthroughPage page) {
    final height = MediaQuery.of(context).size.height;
    final bool isSmall = height < 700;
    final double doodleSize = isSmall ? 140 : 200;
    final double titleSize = isSmall ? 26 : 32;
    final double subtitleSize = isSmall ? 14 : 16;
    final double topSpacing = isSmall ? 24 : 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated doodle
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: doodleSize,
                height: doodleSize,
                decoration: BoxDecoration(
                  color: page.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    page.doodle,
                    style: TextStyle(fontSize: isSmall ? 64 : 80),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: topSpacing),

          // Title
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              page.title,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: isSmall ? 12 : 20),

          // Subtitle
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              page.subtitle,
              style: TextStyle(
                fontSize: subtitleSize,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final height = MediaQuery.of(context).size.height;
    final bool isSmall = height < 700;
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        isSmall ? 16 : 24,
        24,
        isSmall ? 16 : 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? _pages[_currentPage].color
                      : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          SizedBox(height: isSmall ? 20 : 40),

          // Next/Get Started button
          SizedBox(
            width: double.infinity,
            height: isSmall ? 52 : 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pages[_currentPage].color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WalkthroughPage {
  final String title;
  final String subtitle;
  final String doodle;
  final Color color;

  WalkthroughPage({
    required this.title,
    required this.subtitle,
    required this.doodle,
    required this.color,
  });
}
