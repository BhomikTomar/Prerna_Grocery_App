import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ReviewService {
  static const String _baseUrl = 'http://localhost:5000/api';

  Future<Map<String, dynamic>> getProductReviews({
    required String productId,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$_baseUrl/reviews/product/$productId?limit=$limit&page=$page',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {
          'success': true,
          'reviews': data['data'],
          'pagination': data['pagination'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch reviews',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> addReview({
    required String productId,
    required int rating,
    String comment = '',
  }) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Not authenticated'};
    }
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product': productId,
          'rating': rating,
          'comment': comment,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        return {'success': true, 'review': data['data']};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to add review',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
