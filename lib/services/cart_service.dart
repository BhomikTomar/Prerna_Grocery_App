import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class CartService {
  // Use same base URL as ProductService for consistency in this project
  final String _baseUrl = 'http://localhost:5000/api';

  Future<Map<String, dynamic>> _authedHeaders() async {
    final token = await AuthService().getToken();
    if (token == null) return {'ok': false, 'message': 'Not authenticated'};
    return {
      'ok': true,
      'headers': {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    };
  }

  Future<Map<String, dynamic>> _handleAuthError(http.Response response) async {
    if (response.statusCode == 401) {
      // Token expired - logout user
      await AuthService().logout();
      return {
        'success': false,
        'message': 'Session expired. Please log in again.',
        'logout': true,
      };
    }
    return {'success': false, 'message': 'Authentication failed'};
  }

  Future<Map<String, dynamic>> getCart() async {
    final auth = await _authedHeaders();
    if (auth['ok'] != true)
      return {'success': false, 'message': auth['message']};
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/cart'),
        headers: auth['headers'],
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return {'success': true, 'cart': data['data']};

      // Handle authentication errors
      if (res.statusCode == 401) {
        return await _handleAuthError(res);
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch cart',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> addToCart({
    required String productId,
    int quantity = 1,
  }) async {
    final auth = await _authedHeaders();
    if (auth['ok'] != true)
      return {'success': false, 'message': auth['message']};
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/cart/add'),
        headers: auth['headers'],
        body: jsonEncode({'productId': productId, 'quantity': quantity}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) return {'success': true, 'cart': data['data']};
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to add to cart',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateItem({
    required String productId,
    required int quantity,
  }) async {
    final auth = await _authedHeaders();
    if (auth['ok'] != true)
      return {'success': false, 'message': auth['message']};
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/cart/item/$productId'),
        headers: auth['headers'],
        body: jsonEncode({'quantity': quantity}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return {'success': true, 'cart': data['data']};
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update item',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> removeItem({required String productId}) async {
    final auth = await _authedHeaders();
    if (auth['ok'] != true)
      return {'success': false, 'message': auth['message']};
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/cart/item/$productId'),
        headers: auth['headers'],
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return {'success': true, 'cart': data['data']};
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to remove item',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> clearCart() async {
    final auth = await _authedHeaders();
    if (auth['ok'] != true)
      return {'success': false, 'message': auth['message']};
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/cart/clear'),
        headers: auth['headers'],
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return {'success': true, 'cart': data['data']};
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to clear cart',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
