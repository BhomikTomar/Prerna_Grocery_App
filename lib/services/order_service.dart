import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderService {
  static const String _baseUrl = 'http://localhost:5000/api';

  Future<Map<String, dynamic>> getSellerOrders(
    String sellerId, {
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/orders?sellerId=$sellerId&limit=$limit&page=$page',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'orders': responseData['data'],
          'pagination': responseData['pagination'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch orders',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
