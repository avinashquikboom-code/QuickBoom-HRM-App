import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';

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
  HrTaskViewModel() : super(HrTaskState(allTasks: _generateAllTasks()));

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
  }) async {
    state = state.copyWith(isCreating: true, clearMessage: true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final task = TaskModel(
      id: 'T${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      assignedToId: assignedToId,
      assignedToName: assignedToName,
      assignedById: creatorId,
      assignedByName: creatorName,
      projectName: projectName,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      status: TaskStatus.todo,
      priority: priority,
    );

    state = state.copyWith(
      allTasks: [task, ...state.allTasks],
      isCreating: false,
      successMessage: 'Task assigned to $assignedToName successfully!',
    );
  }

  void clearMessage() => state = state.copyWith(clearMessage: true);

  static List<TaskModel> _generateAllTasks() {
    final now = DateTime.now();
    return [
      TaskModel(
        id: 'T001',
        title: 'Complete Q2 Performance Review',
        description: 'Review and finalize performance metrics.',
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
        description: 'Document all new REST endpoints.',
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
        description: 'Resolve the OTP input field bug on iOS.',
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
        title: 'Design Onboarding Flow',
        description: 'Create wireframes for the new employee onboarding.',
        assignedToId: 'QB002',
        assignedToName: 'Priya Patel',
        assignedById: 'HR001',
        assignedByName: 'Sarah Johnson',
        projectName: 'Design',
        dueDate: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 3)),
        status: TaskStatus.inProgress,
        priority: TaskPriority.medium,
      ),
      TaskModel(
        id: 'T005',
        title: 'Monthly Marketing Report',
        description: 'Compile and present the marketing analytics for May.',
        assignedToId: 'QB004',
        assignedToName: 'Sneha Verma',
        assignedById: 'HR001',
        assignedByName: 'Sarah Johnson',
        projectName: 'Marketing',
        dueDate: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 1)),
        status: TaskStatus.todo,
        priority: TaskPriority.high,
      ),
      TaskModel(
        id: 'T006',
        title: 'Audit Financial Statements',
        description: 'Review Q1 financial data and flag discrepancies.',
        assignedToId: 'QB005',
        assignedToName: 'Deepak Nair',
        assignedById: 'HR001',
        assignedByName: 'Sarah Johnson',
        projectName: 'Finance',
        dueDate: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 8)),
        status: TaskStatus.completed,
        priority: TaskPriority.high,
      ),
    ];
  }
}

final hrTaskViewModelProvider =
    StateNotifierProvider<HrTaskViewModel, HrTaskState>((ref) {
  return HrTaskViewModel();
});
