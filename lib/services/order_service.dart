import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class OrderService {
  static const String _baseUrl = 'http://localhost:5000/api';

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

  // Place order from cart
  Future<Map<String, dynamic>> placeOrder({
    required Map<String, dynamic> deliveryAddress,
    String paymentMethod = 'OnLine',
  }) async {
    final auth = await _authedHeaders();
    if (auth['ok'] != true) {
      return {'success': false, 'message': auth['message']};
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/orders'),
        headers: auth['headers'],
        body: jsonEncode({
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'],
          'orders': responseData['data']['orders'],
          'totalAmount': responseData['data']['totalAmount'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to place order',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get user's orders
  Future<Map<String, dynamic>> getUserOrders({
    int limit = 20,
    int page = 1,
    String? status,
  }) async {
    final auth = await _authedHeaders();
    if (auth['ok'] != true) {
      return {'success': false, 'message': auth['message']};
    }

    try {
      String url = '$_baseUrl/orders?limit=$limit&page=$page';
      if (status != null) url += '&status=$status';

      final response = await http.get(Uri.parse(url), headers: auth['headers']);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'orders': responseData['data'],
          'pagination': responseData['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch orders',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get seller orders
  Future<Map<String, dynamic>> getSellerOrders(
    String sellerId, {
    int limit = 20,
    int page = 1,
    String? status,
  }) async {
    final auth = await _authedHeaders();
    if (auth['ok'] != true) {
      return {'success': false, 'message': auth['message']};
    }

    try {
      String url =
          '$_baseUrl/orders?sellerId=$sellerId&limit=$limit&page=$page';
      if (status != null) url += '&status=$status';

      final response = await http.get(Uri.parse(url), headers: auth['headers']);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'orders': responseData['data'],
          'pagination': responseData['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch orders',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get order by ID
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final auth = await _authedHeaders();
    if (auth['ok'] != true) {
      return {'success': false, 'message': auth['message']};
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/$orderId'),
        headers: auth['headers'],
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'order': responseData['data']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch order',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update order status (for sellers)
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final auth = await _authedHeaders();
    if (auth['ok'] != true) {
      return {'success': false, 'message': auth['message']};
    }

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/orders/$orderId/status'),
        headers: auth['headers'],
        body: jsonEncode({'status': status}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'order': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update order status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
