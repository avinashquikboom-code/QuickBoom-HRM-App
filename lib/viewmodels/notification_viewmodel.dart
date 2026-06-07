import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';
import '../models/notification_model.dart';

// ─── Notification State ────────────────────────────────────────────────────────

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get todayNotifications {
    final now = DateTime.now();
    return notifications.where((n) {
      final d = n.createdAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<NotificationModel> get olderNotifications {
    final now = DateTime.now();
    return notifications.where((n) {
      final d = n.createdAt;
      return !(d.year == now.year && d.month == now.month && d.day == now.day);
    }).toList();
  }

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Notification ViewModel ────────────────────────────────────────────────────

class NotificationViewModel extends StateNotifier<NotificationState> {
  Timer? _refreshTimer;

  NotificationViewModel() : super(const NotificationState()) {
    fetchNotifications();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh notifications every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (kDebugMode) {
        debugPrint('🔄 Auto-refreshing notifications...');
      }
      fetchNotifications();
    });
  }

  NotificationModel _parseNotification(Map<String, dynamic> n) {
    NotificationCategory category;
    switch (n['category']?.toString().toLowerCase()) {
      case 'attendance':
        category = NotificationCategory.attendance;
        break;
      case 'leave':
        category = NotificationCategory.leave;
        break;
      case 'task':
        category = NotificationCategory.task;
        break;
      case 'expense':
        category = NotificationCategory.expense;
        break;
      case 'announcement':
        category = NotificationCategory.announcement;
        break;
      case 'payroll':
        category = NotificationCategory.payroll;
        break;
      default:
        category = NotificationCategory.general;
    }

    return NotificationModel(
      id: n['id']?.toString() ?? '',
      title: n['title']?.toString() ?? '',
      body: n['body']?.toString() ?? '',
      category: category,
      createdAt: n['createdAt'] != null ? DateTime.parse(n['createdAt']) : DateTime.now(),
      isRead: n['isRead'] ?? false,
      actionId: n['actionId']?.toString(),
      actionType: n['actionType']?.toString(),
    );
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.get(AppUrl.mobileNotifications);
      final data = jsonDecode(res.body);
      final List rawNotifs = data['data']['notifications'] ?? [];
      final notifications = rawNotifs.map((n) => _parseNotification(n)).toList();

      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiService.put(AppUrl.mobileMarkNotificationRead(id), {});
      final updated = state.notifications.map((n) {
        if (n.id == id) return n.copyWith(isRead: true);
        return n;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.put(AppUrl.mobileMarkAllNotificationsRead, {});
      final updated = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final notificationViewModelProvider =
    StateNotifierProvider<NotificationViewModel, NotificationState>((ref) {
  return NotificationViewModel();
});
