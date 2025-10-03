import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PhoneVerificationService {
  static const String baseUrl = 'http://localhost:5000/api/phone';

  // Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Send phone verification SMS
  Future<Map<String, dynamic>> sendPhoneVerification(String phoneNumber) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/send-verification'),
        headers: headers,
        body: json.encode({'phoneNumber': phoneNumber}),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Verify phone with code
  Future<Map<String, dynamic>> verifyPhone(String code) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/verify'),
        headers: headers,
        body: json.encode({'code': code}),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Resend phone verification SMS
  Future<Map<String, dynamic>> resendPhoneVerification() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/resend-verification'),
        headers: headers,
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
