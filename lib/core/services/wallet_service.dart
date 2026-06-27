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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      dev.log('Error requesting salary advance: $e', name: 'WalletService');
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
          return data['bankDetails'];
        }
      }
      return null;
    } catch (e) {
      dev.log('Error fetching bank details: $e', name: 'WalletService');
      return null;
    }
  }
}
