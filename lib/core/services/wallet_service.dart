// ignore_for_file: use_null_aware_elements, use_build_context_synchronously

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';

class WalletService {
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

  static Future<Map<String, dynamic>?> fetchEmployeeWallet() async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for wallet fetch', name: 'WalletService');
        return null;
      }

      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}/api/employee/wallet'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      dev.log('Wallet Status: ${response.statusCode}', name: 'WalletService');
      dev.log('Wallet Response: ${response.body}', name: 'WalletService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['wallet'];
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching wallet: $e', name: 'WalletService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> requestSalaryAdvance({
    required double amount,
    required int months,
    required String reason,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for salary advance request', name: 'WalletService');
        return null;
      }

      final response = await http
          .post(
            Uri.parse('${AppUrl.baseUrl}/api/employee/wallet/advance'),
            headers: _getHeaders(token),
            body: json.encode({
              'amount': amount,
              'months': months,
              'reason': reason,
            }),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Salary Advance Response: ${response.body}', name: 'WalletService');
      }

      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      dev.log('Error requesting salary advance: $e', name: 'WalletService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> repaySalaryAdvance({
    required int advanceId,
    required double amount,
    String paymentMethod = 'UPI',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for salary advance repayment', name: 'WalletService');
        return null;
      }

      final response = await http
          .post(
            Uri.parse('${AppUrl.baseUrl}/api/employee/wallet/advance/$advanceId/repay'),
            headers: _getHeaders(token),
            body: json.encode({
              'amount': amount,
              'paymentMethod': paymentMethod,
            }),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Salary Advance Repayment Response: ${response.body}', name: 'WalletService');
      }

      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      dev.log('Error repaying salary advance: $e', name: 'WalletService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchBankDetails() async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for bank details fetch', name: 'WalletService');
        return null;
      }

      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}/api/employee/wallet/bank-details'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Bank Details Response: ${response.body}', name: 'WalletService');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching bank details: $e', name: 'WalletService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> requestBankDetailsEdit({
    String? reason,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? accountType,
    String? branchName,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http
          .post(
            Uri.parse('${AppUrl.baseUrl}/api/employee/wallet/bank-details/request'),
            headers: _getHeaders(token),
            body: json.encode({
              'reason': reason ?? 'Requested permission to edit bank details',
              'bankName': bankName,
              'accountNumber': accountNumber,
              'ifscCode': ifscCode,
              'accountType': accountType,
              'branchName': branchName,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 400) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      dev.log('Error requesting bank details edit: $e', name: 'WalletService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateBankDetails({
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    required String accountType,
    required String branchName,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        dev.log('No token found for bank details update', name: 'WalletService');
        return null;
      }

      final response = await http
          .post(
            Uri.parse('${AppUrl.baseUrl}/api/employee/wallet/bank-details'),
            headers: _getHeaders(token),
            body: json.encode({
              'bankName': bankName,
              'accountNumber': accountNumber,
              'ifscCode': ifscCode,
              'accountType': accountType,
              'branchName': branchName,
            }),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        dev.log('Update Bank Details Response: ${response.body}', name: 'WalletService');
      }

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      dev.log('Error updating bank details: $e', name: 'WalletService');
      return null;
    }
  }

  static Future<List<dynamic>?> fetchAdminSalaryAdvances({
    String status = 'ALL',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final url = status == 'ALL'
          ? '${AppUrl.baseUrl}/api/payroll/admin/advances'
          : '${AppUrl.baseUrl}/api/payroll/admin/advances?status=$status';

      final response = await http
          .get(
            Uri.parse(url),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['advances'] as List<dynamic>?;
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching admin salary advances: $e', name: 'WalletService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> reviewSalaryAdvance({
    required int advanceId,
    required String action,
    int? months,
    String? reviewNote,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http
          .put(
            Uri.parse('${AppUrl.baseUrl}/api/payroll/admin/advances/$advanceId/review'),
            headers: _getHeaders(token),
            body: json.encode({
              'action': action,
              if (months != null) 'months': months,
              if (reviewNote != null) 'reviewNote': reviewNote,
            }),
          )
          .timeout(_timeout);

      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Review salary advance error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchSalarySlip({
    int? employeeId,
    int? month,
    int? year,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final queryParams = <String>[];
      if (employeeId != null) queryParams.add('employeeId=$employeeId');
      if (month != null) queryParams.add('month=$month');
      if (year != null) queryParams.add('year=$year');

      final queryStr = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}/api/salary/slip$queryStr'),
            headers: _getHeaders(token),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return (data['salarySlip'] ?? data['data'] ?? data) as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching salary slip: $e');
      return null;
    }
  }
}
