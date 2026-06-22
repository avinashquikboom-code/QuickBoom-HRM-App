import 'dart:convert';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';

class MobileNotificationService {
  // Fetch all notifications for the logged-in user
  static Future<Map<String, dynamic>> fetchMyNotifications() async {
    try {
      final response = await ApiService.get(AppUrl.mobileNotifications);
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Mark a specific notification as read
  static Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    try {
      final response = await ApiService.put(AppUrl.mobileMarkNotificationRead(notificationId), {});
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final response = await ApiService.put(AppUrl.mobileMarkAllNotificationsRead, {});
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }
}
