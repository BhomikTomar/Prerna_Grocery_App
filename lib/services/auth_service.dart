import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:5000/api';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Get current user token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save user token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Save user data
  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Store JWT token from backend response
  Future<void> _storeTokenFromResponse(Map<String, dynamic> response) async {
    if (response.containsKey('token')) {
      await saveToken(response['token']);
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
    String? phone,
    String userType = 'consumer',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password, // Send plain password, backend will hash it
          'name': name,
          'userType': userType,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        await _storeTokenFromResponse(responseData);
        await saveUser(responseData['user']);

        return {
          'success': true,
          'message': responseData['message'],
          'user': responseData['user'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }), // Send plain password
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        await _storeTokenFromResponse(responseData);
        await saveUser(responseData['user']);

        return {
          'success': true,
          'message': responseData['message'],
          'user': responseData['user'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Google Sign In (you'll need to implement this with your backend)
  Future<Map<String, dynamic>> googleSignIn({
    required String googleToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/google-signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'googleToken': googleToken}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        await _storeTokenFromResponse(responseData);
        await saveUser(responseData['user']);

        return {
          'success': true,
          'message': responseData['message'],
          'user': responseData['user'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Google sign in failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> updates,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        await saveUser(userData);

        return {
          'success': true,
          'message': 'Profile updated successfully',
          'user': userData,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Profile update failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
