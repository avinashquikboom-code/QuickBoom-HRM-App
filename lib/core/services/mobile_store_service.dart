import 'dart:developer' as dev;
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'dart:convert';

class MobileStoreService {
  static Future<Map<String, dynamic>?> getStoreDetails() async {
    try {
      final response = await ApiService.get(AppUrl.mobileStore);
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching store details: $e', name: 'MobileStoreService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getAllStores() async {
    try {
      final response = await ApiService.get(AppUrl.mobileStoreAll);
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching all stores: $e', name: 'MobileStoreService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStoreEmployees({String? status}) async {
    try {
      final statusQuery = status != null ? '?status=$status' : '';
      final response = await ApiService.get('${AppUrl.mobileStoreEmployees}$statusQuery');
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching store employees: $e', name: 'MobileStoreService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStoreReports({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = '?startDate=$startDate&endDate=$endDate';
      final response = await ApiService.get('${AppUrl.mobileStoreReports}$queryParams');
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching store reports: $e', name: 'MobileStoreService');
      return null;
    }
  }
}
