import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String _baseUrl =
      kIsWeb
          ? 'https://quickboom-hrm-backend-gjch.onrender.com'
          : 'https://quickboom-hrm-backend-gjch.onrender.com';

  static const String tokenKey = 'auth_token';

  // Private constructor
  ApiService._();

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  static Future<Map<String, String>> _headers() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> get(String path) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final response = await http.get(url, headers: headers);
    _checkResponse(response);
    return response;
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final response = await http.post(url, headers: headers, body: jsonEncode(body));
    _checkResponse(response);
    return response;
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final response = await http.put(url, headers: headers, body: jsonEncode(body));
    _checkResponse(response);
    return response;
  }

  static Future<http.Response> delete(String path) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final response = await http.delete(url, headers: headers);
    _checkResponse(response);
    return response;
  }

  static void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      String message = 'API Request failed with status ${response.statusCode}';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('message')) {
          message = data['message'];
        }
      } catch (_) {}
      // Log the error details for visibility during debugging
      if (kDebugMode) {
        debugPrint('❌ API Error: $message');
        debugPrint('Response Body: ${response.body}');
      }
      throw Exception(message);
    }
  }
}
