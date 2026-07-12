import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickboom_hrm/features/employees/data/models/hopkid_employee_model.dart';

/// Local data source for caching HopKid employee master data using SharedPreferences.
class EmployeeLocalDatasource {
  static const String _employeesCacheKey = 'hopkid_employees_cache';
  static const String _lastSyncedKey = 'hopkid_employees_last_sync';

  EmployeeLocalDatasource();

  /// Retrieve the locally cached list of HopKid employees.
  Future<List<HopkidEmployeeModel>> getCachedEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_employeesCacheKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List list = jsonDecode(jsonStr);
      return list.map((e) => HopkidEmployeeModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Cache the retrieved HopKid employees list and update the synced timestamp.
  Future<void> saveEmployees(List<HopkidEmployeeModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_employeesCacheKey, jsonStr);
    await prefs.setInt(_lastSyncedKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get the timestamp of the last successful sync with the upstream system.
  Future<DateTime?> getLastSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastSyncedKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
