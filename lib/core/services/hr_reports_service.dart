import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/foundation.dart' as foundation show debugPrint;
import 'package:http/http.dart' as http;
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';

class HRReportsService {
  static final Duration _timeout = const Duration(seconds: 30);

  static Future<String?> _getToken() async {
    return await StorageService.getToken();
  }

  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Fetch attendance trend data (7 days)
  static Future<List<Map<String, dynamic>>?> fetchAttendanceTrend() async {
    try {
      final token = await _getToken();
      if (token == null) {
        foundation.debugPrint('No token found for attendance trend fetch');
        return null;
      }

      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}${AppUrl.hrAttendanceTrend}'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        foundation.debugPrint('Attendance Trend Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return null;
    } catch (e) {
      foundation.debugPrint('Error fetching attendance trend: $e');
      return null;
    }
  }

  // Fetch expense data for reports
  static Future<List<Map<String, dynamic>>?> fetchExpenses() async {
    try {
      final token = await _getToken();
      if (token == null) {
        foundation.debugPrint('No token found for expenses fetch');
        return null;
      }

      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}${AppUrl.hrExpenses}'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        foundation.debugPrint('Expenses Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['expenses']);
        }
      }
      return null;
    } catch (e) {
      foundation.debugPrint('Error fetching expenses: $e');
      return null;
    }
  }
}
