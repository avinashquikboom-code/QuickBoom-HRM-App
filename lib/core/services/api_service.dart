import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'storage_service.dart';

// Enhanced logging utility
class ApiLogger {
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _cyan = '\x1B[36m';

  static void logRequest(String method, String path, {Map<String, dynamic>? body}) {
    if (kDebugMode) {
      dev.log('$_cyan🚀 API Request: $method $path$_reset', name: 'API');
      if (body != null) {
        dev.log('$_cyan📤 Request Body: ${jsonEncode(body)}$_reset', name: 'API');
      }
      dev.log('$_cyan⏰ Timestamp: ${DateTime.now().toIso8601String()}$_reset', name: 'API');
    }
  }

  static void logResponse(String method, String path, int statusCode, String responseBody) {
    if (kDebugMode) {
      final color = statusCode >= 200 && statusCode < 300 ? _green : _red;
      dev.log('$color📥 API Response: $method $path - Status: $statusCode$_reset', name: 'API');
      dev.log('$color📄 Response Body: $responseBody$_reset', name: 'API');
      dev.log('$color⏰ Response Timestamp: ${DateTime.now().toIso8601String()}$_reset', name: 'API');
      
      // Special logging for punch endpoints
      if (path.contains('punch-in') || path.contains('punch-out')) {
        _logPunchResponse(method, path, statusCode, responseBody);
      }
    }
  }

  static void _logPunchResponse(String method, String path, int statusCode, String responseBody) {
    if (kDebugMode) {
      dev.log('$_yellow🕒 PUNCH OPERATION DETECTED:$_reset', name: 'API_PUNCH');
      dev.log('$_yellow   Method: $method$_reset', name: 'API_PUNCH');
      dev.log('$_yellow   Endpoint: $path$_reset', name: 'API_PUNCH');
      dev.log('$_yellow   Status Code: $statusCode$_reset', name: 'API_PUNCH');
      
      try {
        final data = jsonDecode(responseBody);
        if (data is Map) {
          if (data['success'] == true) {
            dev.log('$_green   ✅ Punch SUCCESS$_reset', name: 'API_PUNCH');
            if (data['data'] != null) {
              final punchData = data['data'];
              dev.log('$_green   📍 Punch Data: ${jsonEncode(punchData)}$_reset', name: 'API_PUNCH');
              
              // Log specific punch times
              if (punchData['checkInTime'] != null) {
                dev.log('$_green   🟢 Check-in Time: ${punchData['checkInTime']}$_reset', name: 'API_PUNCH');
              }
              if (punchData['checkOutTime'] != null) {
                dev.log('$_green   🔴 Check-out Time: ${punchData['checkOutTime']}$_reset', name: 'API_PUNCH');
              }
              if (punchData['workDuration'] != null) {
                dev.log('$_green   ⏱️ Work Duration: ${jsonEncode(punchData['workDuration'])}$_reset', name: 'API_PUNCH');
              }
            }
          } else {
            dev.log('$_red   ❌ Punch FAILED: ${data['message']}$_reset', name: 'API_PUNCH');
            if (data['errorCode'] != null) {
              dev.log('$_red   🔍 Error Code: ${data['errorCode']}$_reset', name: 'API_PUNCH');
            }
          }
        }
      } catch (e) {
        dev.log('$_red   ⚠️ Failed to parse punch response: $e$_reset', name: 'API_PUNCH');
      }
    }
  }

  static void logError(String method, String path, String error, {int? statusCode, String? responseBody}) {
    if (kDebugMode) {
      dev.log('$_red💥 API Error: $method $path$_reset', name: 'API_ERROR');
      dev.log('$_red🔥 Error: $error$_reset', name: 'API_ERROR');
      if (statusCode != null) {
        dev.log('$_red📊 Status Code: $statusCode$_reset', name: 'API_ERROR');
      }
      if (responseBody != null) {
        dev.log('$_red📄 Error Response: $responseBody$_reset', name: 'API_ERROR');
      }
      dev.log('$_red⏰ Error Timestamp: ${DateTime.now().toIso8601String()}$_reset', name: 'API_ERROR');
    }
  }
}

class ApiService {
  static final String _baseUrl = AppUrl.baseUrl;

  static const String tokenKey = StorageService.tokenKeyPublic;

  // Private constructor
  ApiService._();

  static Future<String?> getToken() => StorageService.getToken();

  static Future<void> saveToken(String token) => StorageService.saveToken(token);

  static Future<void> clearToken() => StorageService.clearToken();

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
