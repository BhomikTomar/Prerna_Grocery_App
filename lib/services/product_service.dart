import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

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

  // Get products for a specific seller
  Future<Map<String, dynamic>> getSellerProducts(
    String sellerId, {
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/products?sellerId=$sellerId&limit=$limit&page=$page',
        ),
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
          'message': error['message'] ?? 'Failed to fetch seller products',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Create a new product (seller)
  Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> product,
  ) async {
    try {
      final auth = AuthService();
      final token = await auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(product),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'product': data['data']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to create product',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update a product (seller)
  Future<Map<String, dynamic>> updateProduct(
    String productId,
    Map<String, dynamic> product,
  ) async {
    try {
      final auth = AuthService();
      final token = await auth.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }
      final response = await http.put(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(product),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'product': data['data']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
