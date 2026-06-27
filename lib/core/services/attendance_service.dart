import 'dart:convert';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';

class AttendanceService {
  // Fetch all employees' attendance (HR/Admin only)
  static Future<Map<String, dynamic>> fetchAllEmployeesAttendance({
    String? from,
    String? to,
    int? employeeId,
    int? departmentId,
    int? officeId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;
      if (employeeId != null) queryParams['employeeId'] = employeeId.toString();
      if (departmentId != null) queryParams['departmentId'] = departmentId.toString();
      if (officeId != null) queryParams['officeId'] = officeId.toString();

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      
      final response = await ApiService.get('${AppUrl.mobileAllAttendance}?$queryString');
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Failed to fetch all employees attendance: $e');
    }
  }
}
