import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';
import 'package:quickboom_hrm/features/store/data/store_models.dart';

class StoreService {
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

  // Fetch Store Dashboard for Store Manager
  static Future<StoreDashboard?> fetchStoreDashboard() async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for store dashboard fetch', name: 'StoreService');
        return null;
      }

      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}/api/store/dashboard'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Store Dashboard Response: ${response.body}', name: 'StoreService');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return StoreDashboard.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching store dashboard: $e', name: 'StoreService');
      return null;
    }
  }

  // Fetch Store Employee List for Store Manager and HR
  static Future<StoreEmployeeList?> fetchStoreEmployees({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? role,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for store employees fetch', name: 'StoreService');
        return null;
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        // ignore: use_null_aware_elements
        if (search != null) 'search': search,
        // ignore: use_null_aware_elements
        if (status != null) 'status': status,
        // ignore: use_null_aware_elements
        if (role != null) 'role': role,
      };

      final uri = Uri.parse('${AppUrl.baseUrl}/api/store/employees')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Store Employees Response: ${response.body}', name: 'StoreService');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return StoreEmployeeList.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching store employees: $e', name: 'StoreService');
      return null;
    }
  }

  // Fetch Store Performance for HR Manager
  static Future<List<StorePerformance>?> fetchStorePerformance({
    String? month,
    String? year,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for store performance fetch', name: 'StoreService');
        return null;
      }

      final queryParams = <String, String>{
        // ignore: use_null_aware_elements
        if (month != null) 'month': month,
        // ignore: use_null_aware_elements
        if (year != null) 'year': year,
      };

      final uri = Uri.parse('${AppUrl.baseUrl}/api/store/performance')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Store Performance Response: ${response.body}', name: 'StoreService');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List?)
                  ?.map((e) => StorePerformance.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching store performance: $e', name: 'StoreService');
      return null;
    }
  }

  // Fetch Store Details
  static Future<Store?> fetchStoreDetails(String storeId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for store details fetch', name: 'StoreService');
        return null;
      }

      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}/api/store/$storeId'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Store Details Response: ${response.body}', name: 'StoreService');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Store.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching store details: $e', name: 'StoreService');
      return null;
    }
  }

  // Fetch Store Sales Report
  static Future<Map<String, dynamic>?> fetchStoreSalesReport({
    required String storeId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for store sales report fetch', name: 'StoreService');
        return null;
      }

      final queryParams = <String, String>{
        'storeId': storeId,
        'startDate': startDate,
        'endDate': endDate,
      };

      final uri = Uri.parse('${AppUrl.baseUrl}/api/store/reports/sales')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Store Sales Report Response: ${response.body}', name: 'StoreService');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching store sales report: $e', name: 'StoreService');
      return null;
    }
  }

  // Fetch Store Attendance Report
  static Future<Map<String, dynamic>?> fetchStoreAttendanceReport({
    required String storeId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for store attendance report fetch', name: 'StoreService');
        return null;
      }

      final queryParams = <String, String>{
        'storeId': storeId,
        'startDate': startDate,
        'endDate': endDate,
      };

      final uri = Uri.parse('${AppUrl.baseUrl}/api/store/reports/attendance')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Store Attendance Report Response: ${response.body}', name: 'StoreService');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching store attendance report: $e', name: 'StoreService');
      return null;
    }
  }
}
