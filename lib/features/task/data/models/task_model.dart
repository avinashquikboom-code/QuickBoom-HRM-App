enum TaskStatus { todo, inProgress, completed, overdue }

enum TaskPriority { low, medium, high }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedToId;
  final String assignedToName;
  final String assignedById;
  final String assignedByName;
  final String projectName;
  final DateTime dueDate;
  final DateTime createdAt;
  final TaskStatus status;
  final TaskPriority priority;
  final bool requiresPhoto;
  final String? photoUrl;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedToId,
    required this.assignedToName,
    required this.assignedById,
    required this.assignedByName,
    required this.projectName,
    required this.dueDate,
    required this.createdAt,
    required this.status,
    required this.priority,
    this.requiresPhoto = false,
    this.photoUrl,
  });

  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) && status != TaskStatus.completed;

  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  String get statusLabel {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.overdue:
        return 'Overdue';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  TaskModel copyWith({TaskStatus? status, String? photoUrl}) {
    return TaskModel(
      id: id,
      title: title,
      description: description,
      assignedToId: assignedToId,
      assignedToName: assignedToName,
      assignedById: assignedById,
      assignedByName: assignedByName,
      projectName: projectName,
      dueDate: dueDate,
      createdAt: createdAt,
      status: status ?? this.status,
      priority: priority,
      requiresPhoto: requiresPhoto,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
