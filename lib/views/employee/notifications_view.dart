import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../viewmodels/notification_viewmodel.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(notificationViewModelProvider.notifier).markAllAsRead();
              },
              child: const Text('Mark all read', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
      body: state.notifications.isEmpty
          ? const Center(
              child: Text('No notifications', style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (state.todayNotifications.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Today', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  ...state.todayNotifications.map((n) => _NotificationTile(notification: n)),
                ],
                if (state.olderNotifications.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text('Earlier', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  ...state.olderNotifications.map((n) => _NotificationTile(notification: n)),
                ],
              ],
            ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationViewModelProvider.notifier).markAsRead(notification.id);
        }
      },
      child: Container(
        color: notification.isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _categoryColor(notification.category).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _categoryIcon(notification.category),
                size: 18,
                color: _categoryColor(notification.category),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: notification.isRead ? AppColors.textHint : AppColors.primary,
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(NotificationCategory c) {
    switch (c) {
      case NotificationCategory.leave: return AppColors.info;
      case NotificationCategory.task: return AppColors.primary;
      case NotificationCategory.expense: return AppColors.warning;
      case NotificationCategory.attendance: return AppColors.error;
      case NotificationCategory.announcement: return AppColors.success;
      case NotificationCategory.payroll: return const Color(0xFF8B5CF6);
      case NotificationCategory.general: return AppColors.textSecondary;
    }
  }

  IconData _categoryIcon(NotificationCategory c) {
    switch (c) {
      case NotificationCategory.leave: return Icons.event_note_rounded;
      case NotificationCategory.task: return Icons.assignment_rounded;
      case NotificationCategory.expense: return Icons.account_balance_wallet_rounded;
      case NotificationCategory.attendance: return Icons.access_time_rounded;
      case NotificationCategory.announcement: return Icons.campaign_rounded;
      case NotificationCategory.payroll: return Icons.payments_rounded;
      case NotificationCategory.general: return Icons.notifications_rounded;
    }
  }
}
