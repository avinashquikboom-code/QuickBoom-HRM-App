import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';
import 'package:quickboom_hrm/features/commission/data/commission_models.dart';
import 'dart:convert';

class CommissionService {
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

  // Fetch Commission Wallet Data
  static Future<CommissionWallet?> fetchCommissionWallet() async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for commission wallet fetch', name: 'CommissionService');
        return null;
      }

      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}/api/employee/commission/wallet'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Commission Wallet Response: ${response.body}', name: 'CommissionService');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CommissionWallet.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching commission wallet: $e', name: 'CommissionService');
      return null;
    }
  }

  // Fetch Commission History with pagination and filters
  static Future<CommissionHistory?> fetchCommissionHistory({
    int page = 1,
    int limit = 20,
    String? status,
    String? startDate,
    String? endDate,
    String? month,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for commission history fetch', name: 'CommissionService');
        return null;
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        // ignore: use_null_aware_elements
        if (status != null) 'status': status,
        // ignore: use_null_aware_elements
        if (startDate != null) 'startDate': startDate,
        // ignore: use_null_aware_elements
        if (endDate != null) 'endDate': endDate,
        // ignore: use_null_aware_elements
        if (month != null) 'month': month,
      };

      final uri = Uri.parse('${AppUrl.baseUrl}/api/employee/commission/history')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Commission History Response: ${response.body}', name: 'CommissionService');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CommissionHistory.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching commission history: $e', name: 'CommissionService');
      return null;
    }
  }

  // Fetch Commission Details
  static Future<CommissionDetails?> fetchCommissionDetails() async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for commission details fetch', name: 'CommissionService');
        return null;
      }

      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}/api/employee/commission/details'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Commission Details Response: ${response.body}', name: 'CommissionService');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CommissionDetails.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching commission details: $e', name: 'CommissionService');
      return null;
    }
  }

  // Fetch Commission Dashboard Widget Data
  static Future<CommissionDashboardWidget?> fetchCommissionDashboardWidget() async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for commission dashboard widget fetch', name: 'CommissionService');
        return null;
      }

      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}/api/employee/commission/dashboard-widget'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Commission Dashboard Widget Response: ${response.body}', name: 'CommissionService');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CommissionDashboardWidget.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching commission dashboard widget: $e', name: 'CommissionService');
      return null;
    }
  }

  // Fetch Salary Slip Commission Data
  static Future<SalarySlipCommission?> fetchSalarySlipCommission(String payrollId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for salary slip commission fetch', name: 'CommissionService');
        return null;
      }

      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}/api/employee/commission/salary-slip/$payrollId'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Salary Slip Commission Response: ${response.body}', name: 'CommissionService');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SalarySlipCommission.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching salary slip commission: $e', name: 'CommissionService');
      return null;
    }
  }
}
