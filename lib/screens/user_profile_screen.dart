import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'personal_details_screen.dart';
import 'manage_addresses_screen.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _currentUser;

  final List<Widget> _screens = [
    const PersonalDetailsScreen(),
    const ManageAddressesScreen(),
    const OrderHistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService().getOrFetchCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  String _getFullName(Map<String, dynamic> user) {
    final firstName = user['profile']?['firstName']?.toString() ?? '';
    final lastName = user['profile']?['lastName']?.toString() ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    } else {
      return user['email']?.toString() ?? 'User';
    }
  }

  String _getInitial(Map<String, dynamic> user) {
    final firstName = user['profile']?['firstName']?.toString() ?? '';
    final lastName = user['profile']?['lastName']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';

    // Try to get initial from firstName first
    if (firstName.isNotEmpty) {
      return firstName.substring(0, 1).toUpperCase();
    }

    // Try to get initial from lastName
    if (lastName.isNotEmpty) {
      return lastName.substring(0, 1).toUpperCase();
    }

    // Fallback to email initial
    if (email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }

    // Final fallback
    return 'U';
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 200,
            color: Colors.grey[100],
            child: Column(
              children: [
                const SizedBox(height: 20),
                // User Info Header
                if (_currentUser != null) ...[
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green,
                    child: Text(
                      _getInitial(_currentUser!),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _getFullName(_currentUser!),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _currentUser!['email']?.toString() ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                ],
                // Navigation Items
                _buildNavItem(
                  icon: Icons.person,
                  title: 'Personal Details',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.location_on,
                  title: 'Manage Addresses',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.shopping_bag,
                  title: 'My Orders',
                  index: 2,
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.green : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.green : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Colors.green.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
