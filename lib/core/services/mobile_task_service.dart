import 'dart:developer' as dev;
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'dart:convert';

class MobileTaskService {
  static Future<Map<String, dynamic>?> getTasks({String? status, String? priority}) async {
    try {
      final queryParams = '?status=$status&priority=$priority';
      final response = await ApiService.get('${AppUrl.mobileTasks}$queryParams');
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching tasks: $e', name: 'MobileTaskService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTaskById(String id) async {
    try {
      final response = await ApiService.get(AppUrl.mobileTaskById(id));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error fetching task by ID: $e', name: 'MobileTaskService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createTask(Map<String, dynamic> body) async {
    try {
      final response = await ApiService.post(AppUrl.mobileTasks, body);
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error creating task: $e', name: 'MobileTaskService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateTask(String id, Map<String, dynamic> body) async {
    try {
      final response = await ApiService.put(AppUrl.mobileTaskById(id), body);
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error updating task: $e', name: 'MobileTaskService');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> deleteTask(String id) async {
    try {
      final response = await ApiService.delete(AppUrl.mobileTaskById(id));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      return null;
    } catch (e) {
      dev.log('Error deleting task: $e', name: 'MobileTaskService');
      return null;
    }
  }
}
