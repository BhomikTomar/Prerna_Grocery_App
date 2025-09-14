import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  static const String _baseUrl = 'http://localhost:5000/api';

  // Get all products
  Future<Map<String, dynamic>> getProducts({
    String? category,
    String? status,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      String url = '$_baseUrl/products?limit=$limit&page=$page';
      if (category != null) url += '&category=$category';
      if (status != null) url += '&status=$status';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'products': responseData['data'],
          'pagination': responseData['pagination'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch products',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get products by category
  Future<Map<String, dynamic>> getProductsByCategory(
    String categoryId, {
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/products/category/$categoryId?limit=$limit&page=$page',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'products': responseData['data'],
          'category': responseData['category'],
          'pagination': responseData['pagination'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch products by category',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get single product
  Future<Map<String, dynamic>> getProduct(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'product': responseData['data']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch product',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
