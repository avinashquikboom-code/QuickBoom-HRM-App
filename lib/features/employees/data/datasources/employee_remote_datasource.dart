import 'dart:convert';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/features/employees/data/models/hopkid_employee_model.dart';

/// Remote data source to fetch employee master data from the local backend (merged HopKid & HRM directory).
class EmployeeRemoteDatasource {
  EmployeeRemoteDatasource();

  /// Fetch the employee list from `/api/Employee/GetEmployeeList`.
  Future<List<HopkidEmployeeModel>> getEmployees() async {
    final response = await ApiService.get('/api/Employee/GetEmployeeList');
    if (response.statusCode != 200) {
      throw Exception('Backend returned status code ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to retrieve employee list');
    }

    final List list = data['data'] ?? [];
    return list.map((e) => HopkidEmployeeModel.fromJson(e)).toList();
  }
}
