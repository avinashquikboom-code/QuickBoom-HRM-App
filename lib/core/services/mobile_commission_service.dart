import 'dart:developer' as dev;
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/features/commission/data/models/commission_models.dart';
import 'dart:convert';

class MobileCommissionService {
  static Future<CommissionSummary> fetchSummary() async {
    try {
      final response = await ApiService.get(AppUrl.mobileCommissionSummary);
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return CommissionSummary.fromJson(data['data']['summary'] ?? data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to load summary');
    } catch (e) {
      dev.log('Error fetching summary: $e', name: 'MobileCommissionService');
      rethrow;
    }
  }

  static Future<CommissionResponse> fetchBills({
    String period = 'current_month',
    String? billId,
    String? from,
    String? to,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var url = '${AppUrl.mobileCommissionBills}?period=$period&limit=$limit&offset=$offset';
      if (billId != null && billId.isNotEmpty) {
        url += '&billId=${Uri.encodeComponent(billId)}';
      }
      if (from != null && from.isNotEmpty) {
        url += '&from=${Uri.encodeComponent(from)}';
      }
      if (to != null && to.isNotEmpty) {
        url += '&to=${Uri.encodeComponent(to)}';
      }

      final response = await ApiService.get(url);
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return CommissionResponse.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to load bills');
    } catch (e) {
      dev.log('Error fetching bills: $e', name: 'MobileCommissionService');
      rethrow;
    }
  }

  static Future<CommissionDetail> fetchBillDetail(String billId) async {
    try {
      final response = await ApiService.get(AppUrl.mobileCommissionBillDetail(billId));
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return CommissionDetail.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Bill not found');
    } catch (e) {
      dev.log('Error fetching bill detail: $e', name: 'MobileCommissionService');
      rethrow;
    }
  }

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

  static Future<Map<String, dynamic>?> getDailyBills({String? date}) async {
    try {
      final queryParam = date != null ? '?date=$date' : '';
      final response = await ApiService.get('${AppUrl.mobileCommissionDaily}$queryParam');
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching daily bills: $e', name: 'MobileCommissionService');
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

typedef CommissionService = MobileCommissionService;
