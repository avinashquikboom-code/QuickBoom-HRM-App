enum NotificationCategory {
  attendance,
  leave,
  task,
  expense,
  announcement,
  payroll,
  general,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final DateTime createdAt;
  final bool isRead;
  final String? actionId;
  final String? actionType;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.isRead = false,
    this.actionId,
    this.actionType,
  });

  String get categoryLabel {
    switch (category) {
      case NotificationCategory.attendance:
        return 'Attendance';
      case NotificationCategory.leave:
        return 'Leave';
      case NotificationCategory.task:
        return 'Task';
      case NotificationCategory.expense:
        return 'Expense';
      case NotificationCategory.announcement:
        return 'Announcement';
      case NotificationCategory.payroll:
        return 'Payroll';
      case NotificationCategory.general:
        return 'General';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      category: category,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      actionId: actionId,
      actionType: actionType,
    );
  }
}
