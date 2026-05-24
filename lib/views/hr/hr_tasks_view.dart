import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/task_model.dart';
import '../../viewmodels/hr_task_viewmodel.dart';

class HrTasksView extends ConsumerStatefulWidget {
  const HrTasksView({super.key});

  @override
  ConsumerState<HrTasksView> createState() => _HrTasksViewState();
}

class _HrTasksViewState extends ConsumerState<HrTasksView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hrTaskViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task Management'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Assign Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Cards
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Active', count: state.inProgressCount + state.todoTasksCount(), color: AppColors.info)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Completed', count: state.completedCount, color: AppColors.success)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Overdue', count: state.overdueCount, color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'All Tasks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            if (state.allTasks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No tasks created yet.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ...state.allTasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HrTaskCard(task: task),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension on HrTaskState {
  int todoTasksCount() {
    return allTasks.where((t) => t.status == TaskStatus.todo).length;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatCard({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _HrTaskCard extends StatelessWidget {
  final TaskModel task;
  const _HrTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(task.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(task.assignedToName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              const Icon(Icons.event_rounded, size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd MMM').format(task.dueDate),
                style: TextStyle(
                  fontSize: 12,
                  color: task.isOverdue ? AppColors.error : AppColors.textSecondary,
                  fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo: return AppColors.warning;
      case TaskStatus.inProgress: return AppColors.info;
      case TaskStatus.completed: return AppColors.success;
      case TaskStatus.overdue: return AppColors.error;
    }
  }
}
