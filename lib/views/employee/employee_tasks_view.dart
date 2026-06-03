import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/task_model.dart';
import '../../viewmodels/task_viewmodel.dart';

class EmployeeTasksView extends ConsumerStatefulWidget {
  const EmployeeTasksView({super.key});

  @override
  ConsumerState<EmployeeTasksView> createState() => _EmployeeTasksViewState();
}

class _EmployeeTasksViewState extends ConsumerState<EmployeeTasksView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'My Tasks',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.myTasks.length} Tasks',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            _buildTab('All', state.myTasks.length),
            _buildTab('In Progress', state.inProgressTasks.length,
                color: AppColors.info),
            _buildTab('To Do', state.todoTasks.length,
                color: AppColors.warning),
            _buildTab('Done', state.completedTasks.length,
                color: AppColors.success),
          ],
        ),
      ),
      body: Column(
        children: [
          // ─── Overdue Banner ─────────────────────────────────────────
          if (state.overdueTasks.isNotEmpty)
            Container(
              width: double.infinity,
              color: AppColors.errorSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(RemixIcons.error_warning_line,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${state.overdueTasks.length} task(s) overdue — please complete them',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TaskList(tasks: state.myTasks),
                _TaskList(tasks: state.inProgressTasks),
                _TaskList(tasks: state.todoTasks),
                _TaskList(tasks: state.completedTasks),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Tab _buildTab(String label, int count, {Color? color}) {
    return Tab(
      child: Row(
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (color ?? AppColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: color ?? AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Task List ────────────────────────────────────────────────────────────────

class _TaskList extends ConsumerWidget {
  final List<TaskModel> tasks;
  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(RemixIcons.checkbox_circle_line,
                size: 52, color: AppColors.textHint.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('No tasks here',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        return _TaskCard(task: tasks[i])
            .animate()
            .fadeIn(delay: Duration(milliseconds: i * 60));
      },
    );
  }
}

// ─── Task Card ────────────────────────────────────────────────────────────────

class _TaskCard extends ConsumerWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityColor = _priorityColor(task.priority);
    final statusColor = _statusColor(task.status);

    return GestureDetector(
      onTap: () => _showDetail(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Priority Bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: task.isOverdue ? AppColors.error : priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: task.status == TaskStatus.completed
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                decoration: task.status == TaskStatus.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PriorityBadge(priority: task.priority),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(RemixIcons.folder_open_line,
                              size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            task.projectName,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Icon(RemixIcons.user_3_line,
                              size: 12, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'by ${task.assignedByName}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              task.isOverdue &&
                                      task.status != TaskStatus.completed
                                  ? 'Overdue'
                                  : task.statusLabel,
                              style: TextStyle(
                                  color: task.isOverdue &&
                                          task.status != TaskStatus.completed
                                      ? AppColors.error
                                      : statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Spacer(),
                          // Due Date
                          Icon(
                           RemixIcons.calendar_event_line,
                            size: 12,
                            color: task.isOverdue
                                ? AppColors.error
                                : AppColors.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${DateFormat('dd MMM').format(task.dueDate)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: task.isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                                fontWeight: task.isOverdue
                                    ? FontWeight.w600
                                    : FontWeight.normal),
                          ),
                        ],
                      ),

                      // Quick Action Buttons
                      if (task.status != TaskStatus.completed) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (task.status == TaskStatus.todo)
                              _QuickAction(
                                label: 'Start',
                                 icon: RemixIcons.play_line,
                                color: AppColors.info,
                                onTap: () => ref
                                    .read(taskViewModelProvider.notifier)
                                    .updateStatus(
                                        task.id, TaskStatus.inProgress),
                              ),
                            if (task.status == TaskStatus.inProgress) ...[
                              _QuickAction(
                                label: 'Done',
                                 icon: RemixIcons.check_line,
                                color: AppColors.success,
                                onTap: () => ref
                                    .read(taskViewModelProvider.notifier)
                                    .updateStatus(
                                        task.id, TaskStatus.completed),
                              ),
                              const SizedBox(width: 8),
                              _QuickAction(
                                label: 'Pause',
                                 icon: RemixIcons.pause_line,
                                color: AppColors.warning,
                                onTap: () => ref
                                    .read(taskViewModelProvider.notifier)
                                    .updateStatus(task.id, TaskStatus.todo),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskDetailSheet(task: task, ref: ref),
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return AppColors.success;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.high:
        return AppColors.error;
    }
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return AppColors.warning;
      case TaskStatus.inProgress:
        return AppColors.info;
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.overdue:
        return AppColors.error;
    }
  }
}

// ─── Priority Badge ───────────────────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case TaskPriority.low:
        color = AppColors.success;
        break;
      case TaskPriority.medium:
        color = AppColors.warning;
        break;
      case TaskPriority.high:
        color = AppColors.error;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── Quick Action Button ──────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Task Detail Sheet ────────────────────────────────────────────────────────

class _TaskDetailSheet extends StatelessWidget {
  final TaskModel task;
  final WidgetRef ref;

  const _TaskDetailSheet({required this.task, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
              ),
              _PriorityBadge(priority: task.priority),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.description,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _DetailRow(
              icon: RemixIcons.folder_open_line,
              label: 'Project',
              value: task.projectName),
          _DetailRow(
              icon: RemixIcons.user_3_line,
              label: 'Assigned by',
              value: task.assignedByName),
          _DetailRow(
              icon: RemixIcons.calendar_event_line,
              label: 'Due Date',
              value: DateFormat('dd MMM yyyy').format(task.dueDate)),
          _DetailRow(
              icon: RemixIcons.time_line,
              label: 'Created',
              value: DateFormat('dd MMM yyyy').format(task.createdAt)),
          const SizedBox(height: 16),
          if (task.status != TaskStatus.completed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(RemixIcons.checkbox_circle_line,
                    color: Colors.white),
                label: const Text('Mark as Complete'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success),
                onPressed: () {
                  ref
                      .read(taskViewModelProvider.notifier)
                      .updateStatus(task.id, TaskStatus.completed);
                  Navigator.pop(context);
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textHint),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
