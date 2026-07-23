import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/features/task/data/models/task_model.dart';

// ─── HR Task State ─────────────────────────────────────────────────────────────

class HrTaskState {
  final List<TaskModel> allTasks;
  final bool isLoading;
  final bool isCreating;
  final String? successMessage;

  const HrTaskState({
    this.allTasks = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.successMessage,
  });

  int get totalCount => allTasks.length;
  int get completedCount =>
      allTasks.where((t) => t.status == TaskStatus.completed).length;
  int get inProgressCount =>
      allTasks.where((t) => t.status == TaskStatus.inProgress).length;
  int get overdueCount =>
      allTasks.where((t) => t.isOverdue && t.status != TaskStatus.completed).length;

  List<TaskModel> get pendingTasks => allTasks
      .where((t) => t.status != TaskStatus.completed)
      .toList();

  HrTaskState copyWith({
    List<TaskModel>? allTasks,
    bool? isLoading,
    bool? isCreating,
    String? successMessage,
    bool clearMessage = false,
  }) {
    return HrTaskState(
      allTasks: allTasks ?? this.allTasks,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      successMessage: clearMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─── HR Task ViewModel ─────────────────────────────────────────────────────────

class HrTaskViewModel extends StateNotifier<HrTaskState> {
  HrTaskViewModel() : super(const HrTaskState()) {
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.get(AppUrl.hrTasks);
      final data = jsonDecode(res.body);
      final List rawTasks = data['tasks'] ?? [];
      final tasks = rawTasks.map((t) => _parseTask(t)).toList();

      state = state.copyWith(allTasks: tasks, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> createTask({
    required String title,
    required String description,
    required String assignedToId,
    required String assignedToName,
    required String projectName,
    required DateTime dueDate,
    required TaskPriority priority,
    required String creatorName,
    required String creatorId,
    bool requiresPhoto = false,
  }) async {
    state = state.copyWith(isCreating: true, clearMessage: true);
    try {
      String priorityStr = 'medium';
      if (priority == TaskPriority.high) {
        priorityStr = 'high';
      } else if (priority == TaskPriority.low) {
        priorityStr = 'low';
      }

      await ApiService.post(AppUrl.hrTasks, {
        'title': title,
        'description': description,
        'assignedToId': assignedToId,
        'assignedToName': assignedToName,
        'assignedById': creatorId,
        'assignedByName': creatorName,
        'projectName': projectName,
        'dueDate': dueDate.toIso8601String(),
        'priority': priorityStr,
        'requiresPhoto': requiresPhoto,
      });

      await fetchTasks();
      state = state.copyWith(
        isCreating: false,
        successMessage: 'Task assigned to $assignedToName successfully!',
      );
    } catch (error) {
      state = state.copyWith(
        isCreating: false,
        successMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearMessage() => state = state.copyWith(clearMessage: true);

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
      requiresPhoto: t['requiresPhoto'] == true,
      photoUrl: t['photoUrl']?.toString(),
    );
  }
}

final hrTaskViewModelProvider =
    StateNotifierProvider<HrTaskViewModel, HrTaskState>((ref) {
  return HrTaskViewModel();
});
