import 'dart:developer' as dev;
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'dart:convert';

class MobileHolidayService {
  static Future<Map<String, dynamic>?> getHolidays({int? year}) async {
    try {
      final yearQuery = year != null ? '?year=$year' : '';
      final response = await ApiService.get('${AppUrl.mobileHolidays}$yearQuery');
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching holidays: $e', name: 'MobileHolidayService');
      return null;
    }
  }
}
