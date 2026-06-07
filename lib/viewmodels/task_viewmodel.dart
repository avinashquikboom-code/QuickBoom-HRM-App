import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../core/constants/app_url.dart';
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
  Timer? _refreshTimer;

  TaskViewModel() : super(const TaskState()) {
    fetchTasks();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh tasks every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      // Check if user is still authenticated before refreshing
      final hasToken = await StorageService.hasToken();
      if (!hasToken) {
        _refreshTimer?.cancel();
        return;
      }
      if (kDebugMode) {
        debugPrint('🔄 Auto-refreshing tasks...');
      }
      fetchTasks();
    });
  }

  TaskModel _parseTask(Map<String, dynamic> t) {
    TaskStatus status;
    switch (t['status']?.toString().toLowerCase()) {
      case 'todo':
        status = TaskStatus.todo;
        break;
      case 'inprogress':
        status = TaskStatus.inProgress;
        break;
      case 'completed':
        status = TaskStatus.completed;
        break;
      case 'overdue':
        status = TaskStatus.overdue;
        break;
      default:
        status = TaskStatus.todo;
    }

    TaskPriority priority;
    switch (t['priority']?.toString().toLowerCase()) {
      case 'low':
        priority = TaskPriority.low;
        break;
      case 'medium':
        priority = TaskPriority.medium;
        break;
      case 'high':
        priority = TaskPriority.high;
        break;
      default:
        priority = TaskPriority.medium;
    }

    return TaskModel(
      id: t['id']?.toString() ?? '',
      title: t['title']?.toString() ?? '',
      description: t['description']?.toString() ?? '',
      assignedToId: t['assignedToId']?.toString() ?? '',
      assignedToName: t['assignedToName']?.toString() ?? '',
      assignedById: t['assignedById']?.toString() ?? '',
      assignedByName: t['assignedByName']?.toString() ?? 'Manager',
      projectName: t['projectName']?.toString() ?? 'General',
      dueDate: t['dueDate'] != null ? DateTime.parse(t['dueDate']) : DateTime.now(),
      createdAt: t['createdAt'] != null ? DateTime.parse(t['createdAt']) : DateTime.now(),
      status: status,
      priority: priority,
    );
  }

  Future<void> fetchTasks() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.get(AppUrl.employeeTasks);
      final data = jsonDecode(res.body);
      final List rawTasks = data['tasks'] ?? [];
      final tasks = rawTasks.map((t) => _parseTask(t)).toList();
      state = state.copyWith(
        myTasks: tasks,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateStatus(String taskId, TaskStatus newStatus) async {
    state = state.copyWith(isUpdating: true);
    try {
      String statusStr = 'todo';
      if (newStatus == TaskStatus.inProgress) {
        statusStr = 'inProgress';
      } else if (newStatus == TaskStatus.completed) {
        statusStr = 'completed';
      } else if (newStatus == TaskStatus.overdue) {
        statusStr = 'overdue';
      }

      await ApiService.put(AppUrl.employeeTaskById(taskId), {'status': statusStr});

      final updated = state.myTasks.map((t) {
        if (t.id == taskId) return t.copyWith(status: newStatus);
        return t;
      }).toList();
      state = state.copyWith(myTasks: updated, isUpdating: false);
    } catch (_) {
      state = state.copyWith(isUpdating: false);
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final taskViewModelProvider =
    StateNotifierProvider<TaskViewModel, TaskState>((ref) {
  return TaskViewModel();
});
