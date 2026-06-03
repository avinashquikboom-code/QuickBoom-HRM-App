import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Enhanced logging utility
class ApiLogger {
  static void logRequest(String method, String path, {Map<String, dynamic>? body}) {
    if (kDebugMode) {
      debugPrint('🚀 API Request: $method $path');
      if (body != null) {
        debugPrint('📤 Request Body: ${jsonEncode(body)}');
      }
      debugPrint('⏰ Timestamp: ${DateTime.now().toIso8601String()}');
    }
  }

  static void logResponse(String method, String path, int statusCode, String responseBody) {
    if (kDebugMode) {
      debugPrint('📥 API Response: $method $path - Status: $statusCode');
      debugPrint('📄 Response Body: $responseBody');
      debugPrint('⏰ Response Timestamp: ${DateTime.now().toIso8601String()}');
      
      // Special logging for punch endpoints
      if (path.contains('punch-in') || path.contains('punch-out')) {
        _logPunchResponse(method, path, statusCode, responseBody);
      }
    }
  }

  static void _logPunchResponse(String method, String path, int statusCode, String responseBody) {
    if (kDebugMode) {
      debugPrint('🕒 PUNCH OPERATION DETECTED:');
      debugPrint('   Method: $method');
      debugPrint('   Endpoint: $path');
      debugPrint('   Status Code: $statusCode');
      
      try {
        final data = jsonDecode(responseBody);
        if (data is Map) {
          if (data['success'] == true) {
            debugPrint('   ✅ Punch SUCCESS');
            if (data['data'] != null) {
              final punchData = data['data'];
              debugPrint('   📍 Punch Data: ${jsonEncode(punchData)}');
              
              // Log specific punch times
              if (punchData['checkInTime'] != null) {
                debugPrint('   🟢 Check-in Time: ${punchData['checkInTime']}');
              }
              if (punchData['checkOutTime'] != null) {
                debugPrint('   🔴 Check-out Time: ${punchData['checkOutTime']}');
              }
              if (punchData['workDuration'] != null) {
                debugPrint('   ⏱️ Work Duration: ${jsonEncode(punchData['workDuration'])}');
              }
            }
          } else {
            debugPrint('   ❌ Punch FAILED: ${data['message']}');
            if (data['errorCode'] != null) {
              debugPrint('   🔍 Error Code: ${data['errorCode']}');
            }
          }
        }
      } catch (e) {
        debugPrint('   ⚠️ Failed to parse punch response: $e');
      }
    }
  }

  static void logError(String method, String path, String error, {int? statusCode, String? responseBody}) {
    if (kDebugMode) {
      debugPrint('💥 API Error: $method $path');
      debugPrint('🔥 Error: $error');
      if (statusCode != null) {
        debugPrint('📊 Status Code: $statusCode');
      }
      if (responseBody != null) {
        debugPrint('📄 Error Response: $responseBody');
      }
      debugPrint('⏰ Error Timestamp: ${DateTime.now().toIso8601String()}');
    }
  }
}

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
    
    ApiLogger.logRequest('GET', path);
    
    try {
      final response = await http.get(url, headers: headers);
      ApiLogger.logResponse('GET', path, response.statusCode, response.body);
      _checkResponse(response);
      return response;
    } catch (e) {
      ApiLogger.logError('GET', path, e.toString());
      rethrow;
    }
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    
    ApiLogger.logRequest('POST', path, body: body);
    
    try {
      final response = await http.post(url, headers: headers, body: jsonEncode(body));
      ApiLogger.logResponse('POST', path, response.statusCode, response.body);
      _checkResponse(response);
      return response;
    } catch (e) {
      ApiLogger.logError('POST', path, e.toString(), statusCode: null, responseBody: jsonEncode(body));
      rethrow;
    }
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    
    ApiLogger.logRequest('PUT', path, body: body);
    
    try {
      final response = await http.put(url, headers: headers, body: jsonEncode(body));
      ApiLogger.logResponse('PUT', path, response.statusCode, response.body);
      _checkResponse(response);
      return response;
    } catch (e) {
      ApiLogger.logError('PUT', path, e.toString(), statusCode: null, responseBody: jsonEncode(body));
      rethrow;
    }
  }

  static Future<http.Response> delete(String path) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    
    ApiLogger.logRequest('DELETE', path);
    
    try {
      final response = await http.delete(url, headers: headers);
      ApiLogger.logResponse('DELETE', path, response.statusCode, response.body);
      _checkResponse(response);
      return response;
    } catch (e) {
      ApiLogger.logError('DELETE', path, e.toString());
      rethrow;
    }
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
      
      // Enhanced error logging
      if (kDebugMode) {
        debugPrint('❌ API Error: $message');
        debugPrint('Response Body: ${response.body}');
        debugPrint('Status Code: ${response.statusCode}');
      }
      
      throw Exception(message);
    }
  }
}
