import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';

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

/// Thrown for non-2xx API responses with a user-presentable message.
/// `toString()` returns only the message so existing
/// `e.toString().replaceFirst('Exception: ', '')` call sites stay clean.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static final String _baseUrl = AppUrl.baseUrl;

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration loginTimeout = Duration(seconds: 30);

  static const String tokenKey = StorageService.tokenKeyPublic;

  // Single shared persistent HTTP Client instance for TCP connection reuse
  static final http.Client _client = http.Client();

  // Private constructor
  ApiService._();

  static Future<String?> getToken() => StorageService.getToken();

  static Future<void> saveToken(String token, String role) => StorageService.saveToken(token, role);

  static Future<void> saveTokens(String token, String refreshToken, String role) =>
      StorageService.saveTokens(token, refreshToken, role);

  static Future<void> clearToken() => StorageService.clearToken();

  // Expose baseUrl for WebSocket service
  static String get baseUrl => _baseUrl;

  // Get storage instance for WebSocket service
  static Future<SharedPreferences> getStorage() async {
    return await StorageService.getPrefs();
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

  static Future<http.Response> get(String path, {Duration? timeout}) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final requestTimeout = timeout ?? defaultTimeout;
    
    ApiLogger.logRequest('GET', path);
    
    try {
      final response = await _client.get(url, headers: headers).timeout(requestTimeout);
      ApiLogger.logResponse('GET', path, response.statusCode, response.body);
      
      // Handle 401 - try token refresh (skip for auth paths)
      if (response.statusCode == 401 && !_isAuthPath(path)) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          // Retry with new token
          final newHeaders = await _headers();
          final retryResponse = await _client.get(url, headers: newHeaders).timeout(requestTimeout);
          ApiLogger.logResponse('GET (retry)', path, retryResponse.statusCode, retryResponse.body);
          _checkResponse(retryResponse);
          return retryResponse;
        }
      }
      
      _checkResponse(response);
      return response;
    } on TimeoutException {
      ApiLogger.logError('GET', path, 'Request timed out after ${requestTimeout.inSeconds}s');
      throw ApiException(0, 'Request timed out. Please check your connection and try again.');
    } on SocketException catch (e) {
      ApiLogger.logError('GET', path, e.toString());
      throw ApiException(0, 'No internet connection. Please check your network and try again.');
    } on http.ClientException catch (e) {
      ApiLogger.logError('GET', path, e.toString());
      throw ApiException(0, 'Could not reach the server. Please check your connection and try again.');
    } catch (e) {
      ApiLogger.logError('GET', path, e.toString());
      rethrow;
    }
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final requestTimeout = timeout ?? defaultTimeout;
    
    ApiLogger.logRequest('POST', path, body: body);
    
    try {
      final response = await _client
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(requestTimeout);
      ApiLogger.logResponse('POST', path, response.statusCode, response.body);
      
      // Handle 401 - try token refresh (skip for auth paths)
      if (response.statusCode == 401 && !_isAuthPath(path)) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          // Retry with new token
          final newHeaders = await _headers();
          final retryResponse = await _client
              .post(url, headers: newHeaders, body: jsonEncode(body))
              .timeout(requestTimeout);
          ApiLogger.logResponse('POST (retry)', path, retryResponse.statusCode, retryResponse.body);
          _checkResponse(retryResponse);
          return retryResponse;
        }
      }
      
      _checkResponse(response);
      return response;
    } on TimeoutException {
      ApiLogger.logError('POST', path, 'Request timed out after ${requestTimeout.inSeconds}s');
      throw ApiException(0, 'Request timed out. Please check your connection and try again.');
    } on SocketException catch (e) {
      ApiLogger.logError('POST', path, e.toString());
      throw ApiException(0, 'No internet connection. Please check your network and try again.');
    } on http.ClientException catch (e) {
      ApiLogger.logError('POST', path, e.toString());
      throw ApiException(0, 'Could not reach the server. Please check your connection and try again.');
    } catch (e) {
      ApiLogger.logError('POST', path, e.toString(), statusCode: null, responseBody: jsonEncode(body));
      rethrow;
    }
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body, {Duration? timeout}) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final requestTimeout = timeout ?? defaultTimeout;
    
    ApiLogger.logRequest('PUT', path, body: body);
    
    try {
      final response = await _client
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(requestTimeout);
      ApiLogger.logResponse('PUT', path, response.statusCode, response.body);
      
      // Handle 401 - try token refresh (skip for auth paths)
      if (response.statusCode == 401 && !_isAuthPath(path)) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          // Retry with new token
          final newHeaders = await _headers();
          final retryResponse = await _client
              .put(url, headers: newHeaders, body: jsonEncode(body))
              .timeout(requestTimeout);
          ApiLogger.logResponse('PUT (retry)', path, retryResponse.statusCode, retryResponse.body);
          _checkResponse(retryResponse);
          return retryResponse;
        }
      }
      
      _checkResponse(response);
      return response;
    } on TimeoutException {
      ApiLogger.logError('PUT', path, 'Request timed out after ${requestTimeout.inSeconds}s');
      throw ApiException(0, 'Request timed out. Please check your connection and try again.');
    } on SocketException catch (e) {
      ApiLogger.logError('PUT', path, e.toString());
      throw ApiException(0, 'No internet connection. Please check your network and try again.');
    } on http.ClientException catch (e) {
      ApiLogger.logError('PUT', path, e.toString());
      throw ApiException(0, 'Could not reach the server. Please check your connection and try again.');
    } catch (e) {
      ApiLogger.logError('PUT', path, e.toString(), statusCode: null, responseBody: jsonEncode(body));
      rethrow;
    }
  }

  static Future<http.Response> delete(String path, {Duration? timeout}) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final requestTimeout = timeout ?? defaultTimeout;
    
    ApiLogger.logRequest('DELETE', path);
    
    try {
      final response = await _client.delete(url, headers: headers).timeout(requestTimeout);
      ApiLogger.logResponse('DELETE', path, response.statusCode, response.body);
      
      // Handle 401 - try token refresh (skip for auth paths)
      if (response.statusCode == 401 && !_isAuthPath(path)) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          // Retry with new token
          final newHeaders = await _headers();
          final retryResponse = await _client.delete(url, headers: newHeaders).timeout(requestTimeout);
          ApiLogger.logResponse('DELETE (retry)', path, retryResponse.statusCode, retryResponse.body);
          _checkResponse(retryResponse);
          return retryResponse;
        }
      }
      
      _checkResponse(response);
      return response;
    } on TimeoutException {
      ApiLogger.logError('DELETE', path, 'Request timed out after ${requestTimeout.inSeconds}s');
      throw ApiException(0, 'Request timed out. Please check your connection and try again.');
    } on SocketException catch (e) {
      ApiLogger.logError('DELETE', path, e.toString());
      throw ApiException(0, 'No internet connection. Please check your network and try again.');
    } on http.ClientException catch (e) {
      ApiLogger.logError('DELETE', path, e.toString());
      throw ApiException(0, 'Could not reach the server. Please check your connection and try again.');
    } catch (e) {
      ApiLogger.logError('DELETE', path, e.toString());
      rethrow;
    }
  }

  static bool _isAuthPath(String path) {
    return path.contains('/login') ||
        path.contains('/register') ||
        path.contains('/refresh') ||
        path.contains('/logout');
  }

  static void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      String message = 'Something went wrong. Please try again.';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] is String) {
          message = (data['message'] as String).trim();
        }
      } catch (_) {}

      // Never surface raw server internals (stack traces, DB errors) to the UI.
      // 5xx bodies and multi-line/technical messages get a generic message instead.
      if (response.statusCode >= 500 ||
          message.isEmpty ||
          message.contains('\n') ||
          message.length > 200 ||
          RegExp(r'prisma|sql|stack|Error:', caseSensitive: false).hasMatch(message)) {
        message = response.statusCode >= 500
            ? 'Server error. Please try again in a few minutes.'
            : 'Something went wrong. Please try again.';
      }

      // Enhanced error logging
      if (kDebugMode) {
        debugPrint('❌ API Error: $message');
        debugPrint('Response Body: ${response.body}');
        debugPrint('Status Code: ${response.statusCode}');
      }

      throw ApiException(response.statusCode, message);
    }
  }

  static Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final path = AppUrl.refreshToken;
      final url = Uri.parse('$_baseUrl$path');
      final body = {'refreshToken': refreshToken};

      ApiLogger.logRequest('POST', path, body: body);

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      ApiLogger.logResponse('POST', path, response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          final newToken = data['token'];
          final newRefreshToken = data['refreshToken'] ?? refreshToken;
          final role = await StorageService.getUserRole() ?? 'EMPLOYEE';
          await saveTokens(newToken, newRefreshToken, role);
          debugPrint('✅ Token refreshed successfully');
          return true;
        }
      }
    } catch (e) {
      ApiLogger.logError('POST', AppUrl.refreshToken, e.toString());
    }
    return false;
  }
}
