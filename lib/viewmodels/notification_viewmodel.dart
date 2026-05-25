import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  NotificationViewModel()
      : super(NotificationState(notifications: _generateMockNotifications()));

  void markAsRead(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  void markAllAsRead() {
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    state = state.copyWith(notifications: updated);
  }

  static List<NotificationModel> _generateMockNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'N001',
        title: 'Leave Request Approved ✅',
        body:
            'Your casual leave request for ${_fmtDate(now.add(const Duration(days: 10)))} has been approved by Sarah Johnson.',
        category: NotificationCategory.leave,
        createdAt: now.subtract(const Duration(hours: 1)),
        isRead: false,
        actionId: 'L001',
        actionType: 'leave',
      ),
      NotificationModel(
        id: 'N002',
        title: 'New Task Assigned 📋',
        body:
            'You have been assigned "Update API Documentation" due in 2 days.',
        category: NotificationCategory.task,
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: false,
        actionId: 'T002',
        actionType: 'task',
      ),
      NotificationModel(
        id: 'N003',
        title: 'Expense Approved 💰',
        body:
            'Your travel expense of ₹1,850 has been approved and will be reimbursed.',
        category: NotificationCategory.expense,
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: true,
        actionId: 'EXP001',
        actionType: 'expense',
      ),
      NotificationModel(
        id: 'N004',
        title: 'Late Mark Recorded ⏰',
        body:
            'You were marked late today. Check-in at 10:15 AM (Grace: 09:15 AM).',
        category: NotificationCategory.attendance,
        createdAt: DateTime(now.year, now.month, now.day, 10, 20),
        isRead: false,
      ),
      NotificationModel(
        id: 'N005',
        title: '🎉 Company Picnic This Saturday!',
        body:
            'Annual Picnic at City Park on Saturday 10 AM. All employees are invited!',
        category: NotificationCategory.announcement,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: true,
      ),
      NotificationModel(
        id: 'N006',
        title: 'Payslip for April 2025 Ready 📄',
        body:
            'Your payslip for April 2025 has been generated. Download it from the Documents section.',
        category: NotificationCategory.payroll,
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
        actionType: 'document',
      ),
      NotificationModel(
        id: 'N007',
        title: 'Expense Rejected ❌',
        body:
            'Your travel expense of ₹3,200 was rejected. Policy limit exceeded.',
        category: NotificationCategory.expense,
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
        actionId: 'EXP004',
        actionType: 'expense',
      ),
      NotificationModel(
        id: 'N008',
        title: 'Updated WFH Policy 📋',
        body:
            'The remote work policy has been updated effective June 1st. Please review.',
        category: NotificationCategory.announcement,
        createdAt: now.subtract(const Duration(days: 5)),
        isRead: true,
      ),
    ];
  }

  static String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

// ─── Providers ────────────────────────────────────────────────────────────────

final notificationViewModelProvider =
    StateNotifierProvider<NotificationViewModel, NotificationState>((ref) {
  return NotificationViewModel();
});
