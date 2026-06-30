import 'dart:developer' as dev;
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'dart:convert';

class MobileCommissionService {
  static Future<Map<String, dynamic>?> getCommissionDashboard() async {
    try {
      final response = await ApiService.get(AppUrl.mobileCommissionDashboard);
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching commission dashboard: $e', name: 'MobileCommissionService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCommissionTransactions({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = '?limit=$limit&offset=$offset';
      final statusQuery = status != null ? '&status=$status' : '';
      final response = await ApiService.get('${AppUrl.mobileCommissionTransactions}$queryParams$statusQuery');
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching commission transactions: $e', name: 'MobileCommissionService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCommissionTargets({String? status}) async {
    try {
      final statusQuery = status != null ? '?status=$status' : '';
      final response = await ApiService.get('${AppUrl.mobileCommissionTargets}$statusQuery');
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching commission targets: $e', name: 'MobileCommissionService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCommissionSettlements({String? status}) async {
    try {
      final statusQuery = status != null ? '?status=$status' : '';
      final response = await ApiService.get('${AppUrl.mobileCommissionSettlements}$statusQuery');
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching commission settlements: $e', name: 'MobileCommissionService');
      return null;
    }
  }
}
