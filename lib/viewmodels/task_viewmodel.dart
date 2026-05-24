import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';

// ─── Task State ────────────────────────────────────────────────────────────────

class TaskState {
  final List<TaskModel> myTasks;
  final bool isLoading;
  final bool isUpdating;

  const TaskState({
    this.myTasks = const [],
    this.isLoading = false,
    this.isUpdating = false,
  });

  List<TaskModel> get todoTasks =>
      myTasks.where((t) => t.status == TaskStatus.todo).toList();
  List<TaskModel> get inProgressTasks =>
      myTasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<TaskModel> get completedTasks =>
      myTasks.where((t) => t.status == TaskStatus.completed).toList();
  List<TaskModel> get overdueTasks =>
      myTasks.where((t) => t.isOverdue && t.status != TaskStatus.completed).toList();

  TaskState copyWith({
    List<TaskModel>? myTasks,
    bool? isLoading,
    bool? isUpdating,
  }) {
    return TaskState(
      myTasks: myTasks ?? this.myTasks,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

// ─── Task ViewModel (Employee) ─────────────────────────────────────────────────

class TaskViewModel extends StateNotifier<TaskState> {
  TaskViewModel() : super(TaskState(myTasks: _generateMockTasks()));

  Future<void> updateStatus(String taskId, TaskStatus newStatus) async {
    state = state.copyWith(isUpdating: true);
    await Future.delayed(const Duration(milliseconds: 600));
    final updated = state.myTasks.map((t) {
      if (t.id == taskId) return t.copyWith(status: newStatus);
      return t;
    }).toList();
    state = state.copyWith(myTasks: updated, isUpdating: false);
  }

  static List<TaskModel> _generateMockTasks() {
    final now = DateTime.now();
    return [
      TaskModel(
        id: 'T001',
        title: 'Complete Q2 Performance Review',
        description:
            'Review and finalize performance metrics for all team members in Q2.',
        assignedToId: 'QB001',
        assignedToName: 'Rahul Sharma',
        assignedById: 'HR001',
        assignedByName: 'Sarah Johnson',
        projectName: 'HR Operations',
        dueDate: now.add(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 5)),
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
      ),
      TaskModel(
        id: 'T002',
        title: 'Update API Documentation',
        description:
            'Document all new REST endpoints added in the latest sprint.',
        assignedToId: 'QB001',
        assignedToName: 'Rahul Sharma',
        assignedById: 'QB003',
        assignedByName: 'Amit Kumar',
        projectName: 'Backend Platform',
        dueDate: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
      ),
      TaskModel(
        id: 'T003',
        title: 'Fix Login Screen Bug',
        description: 'Resolve the OTP input field validation bug on iOS.',
        assignedToId: 'QB001',
        assignedToName: 'Rahul Sharma',
        assignedById: 'QB003',
        assignedByName: 'Amit Kumar',
        projectName: 'Mobile App',
        dueDate: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 4)),
        status: TaskStatus.todo,
        priority: TaskPriority.high,
      ),
      TaskModel(
        id: 'T004',
        title: 'Setup CI/CD Pipeline',
        description: 'Configure GitHub Actions for automated testing and deployment.',
        assignedToId: 'QB001',
        assignedToName: 'Rahul Sharma',
        assignedById: 'QB003',
        assignedByName: 'Amit Kumar',
        projectName: 'DevOps',
        dueDate: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 10)),
        status: TaskStatus.completed,
        priority: TaskPriority.medium,
      ),
      TaskModel(
        id: 'T005',
        title: 'Prepare Sprint Demo Slides',
        description: 'Create presentation slides for the upcoming sprint demo.',
        assignedToId: 'QB001',
        assignedToName: 'Rahul Sharma',
        assignedById: 'HR001',
        assignedByName: 'Sarah Johnson',
        projectName: 'General',
        dueDate: now.add(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 1)),
        status: TaskStatus.todo,
        priority: TaskPriority.low,
      ),
      TaskModel(
        id: 'T006',
        title: 'Code Review — Auth Module',
        description: 'Review the authentication module PR submitted by Priya.',
        assignedToId: 'QB001',
        assignedToName: 'Rahul Sharma',
        assignedById: 'QB003',
        assignedByName: 'Amit Kumar',
        projectName: 'Mobile App',
        dueDate: now.add(const Duration(days: 2)),
        createdAt: now,
        status: TaskStatus.inProgress,
        priority: TaskPriority.medium,
      ),
    ];
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final taskViewModelProvider =
    StateNotifierProvider<TaskViewModel, TaskState>((ref) {
  return TaskViewModel();
});
