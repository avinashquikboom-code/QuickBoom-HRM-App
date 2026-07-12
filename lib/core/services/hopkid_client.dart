import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quickboom_hrm/core/constants/app_url.dart';

/// HTTP Client wrapper for all requests to the HopKid upstream system.
/// Injects required API key, enforces timeout, and performs retries on failure.
class HopkidClient {
  static final http.Client _client = http.Client();
  static const Duration _timeoutDuration = Duration(seconds: 15);

  HopkidClient._(); // Private constructor

  static Future<http.Response> get(String path) async {
    return _requestWithRetry('GET', path);
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    return _requestWithRetry('POST', path, body: body);
  }

  static Future<http.Response> _requestWithRetry(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('${AppUrl.hopkidBaseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-api-key': AppUrl.hopkidApiKey,
    };

    int attempts = 0;
    const int maxAttempts = 2; // 1 initial attempt + 1 retry

    while (attempts < maxAttempts) {
      attempts++;
      try {
        if (kDebugMode) {
          dev.log('🚀 [HopKid Request] Attempt $attempts: $method $path', name: 'HopkidClient');
          if (body != null) {
            dev.log('📤 Body: ${jsonEncode(body)}', name: 'HopkidClient');
          }
        }

        late http.Response response;
        if (method == 'GET') {
          response = await _client.get(url, headers: headers).timeout(_timeoutDuration);
        } else if (method == 'POST') {
          response = await _client
              .post(url, headers: headers, body: jsonEncode(body))
              .timeout(_timeoutDuration);
        } else {
          throw UnsupportedError('HTTP method $method not supported by HopkidClient');
        }

        if (kDebugMode) {
          dev.log('📥 [HopKid Response] Status: ${response.statusCode}', name: 'HopkidClient');
          dev.log('📄 Body: ${response.body}', name: 'HopkidClient');
        }

        // Retry on 5xx errors
        if (response.statusCode >= 500 && attempts < maxAttempts) {
          dev.log('⚠️ [HopKid] 5xx Server Error (${response.statusCode}). Retrying...', name: 'HopkidClient');
          continue;
        }

        return response;
      } catch (e) {
        dev.log('💥 [HopKid] Network/Timeout error on attempt $attempts: $e', name: 'HopkidClient');
        if (attempts >= maxAttempts) {
          rethrow;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    throw Exception('Failed to perform HopKid API request');
  }
}
