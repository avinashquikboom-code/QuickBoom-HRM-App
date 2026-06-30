import 'dart:developer' as dev;
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'dart:convert';

class MobileDocumentService {
  static Future<Map<String, dynamic>?> getDocuments({String? type, String? isPublic}) async {
    try {
      final queryParams = '?type=$type&isPublic=$isPublic';
      final response = await ApiService.get('${AppUrl.mobileDocuments}$queryParams');
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching documents: $e', name: 'MobileDocumentService');
      return null;
    }
  }
}
