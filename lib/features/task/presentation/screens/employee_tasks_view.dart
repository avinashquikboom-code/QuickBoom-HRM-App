import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/task/data/models/task_model.dart';
import 'package:quickboom_hrm/features/task/presentation/providers/task_viewmodel.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';

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
        title: Text(
          'My Tasks',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.myTasks.length} Active',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              dividerColor: Colors.transparent,
              tabs: [
                _buildTab('All', state.myTasks.length),
                _buildTab('In Progress', state.inProgressTasks.length, color: AppColors.info),
                _buildTab('To Do', state.todoTasks.length, color: AppColors.warning),
                _buildTab('Done', state.completedTasks.length, color: AppColors.success),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ─── Overdue Banner ─────────────────────────────────────────
          if (state.overdueTasks.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(RemixIcons.error_warning_fill,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${state.overdueTasks.length} task(s) overdue — please complete them',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color?.withValues(alpha: 0.15) ?? AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: color ?? AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
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
    final state = ref.watch(taskViewModelProvider);

    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerLoading(
              height: 80,
              width: double.infinity,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(RemixIcons.checkbox_circle_line,
                size: 52, color: AppColors.textHint.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No tasks here',
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
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Priority vertical line indicator
              Container(
                width: 5,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: task.status == TaskStatus.completed
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                decoration: task.status == TaskStatus.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _PriorityBadge(priority: task.priority),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(RemixIcons.folder_open_line,
                              size: 13, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            task.projectName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(RemixIcons.user_3_line,
                              size: 13, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'by ${task.assignedByName}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.15),
                                width: 1,
                              ),
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
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          // Due Date Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: task.isOverdue
                                  ? AppColors.error.withValues(alpha: 0.08)
                                  : AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  RemixIcons.calendar_event_line,
                                  size: 12,
                                  color: task.isOverdue
                                      ? AppColors.error
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Due ${DateFormat('dd MMM').format(task.dueDate)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: task.isOverdue
                                        ? AppColors.error
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Quick Action Buttons
                      if (task.status != TaskStatus.completed) ...[
                        const SizedBox(height: 12),
                        Divider(height: 1, color: AppColors.cardBorder),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (task.status == TaskStatus.todo)
                              _QuickAction(
                                label: 'Start Task',
                                icon: RemixIcons.play_line,
                                color: AppColors.primary,
                                onTap: () => _showStatusRemarkDialog(
                                    context, ref, task.id, TaskStatus.inProgress),
                              ),
                            if (task.status == TaskStatus.inProgress) ...[
                              _QuickAction(
                                label: 'Complete',
                                icon: RemixIcons.checkbox_circle_line,
                                color: AppColors.success,
                                onTap: () => _showStatusRemarkDialog(
                                    context, ref, task.id, TaskStatus.completed),
                              ),
                              const SizedBox(width: 10),
                              _QuickAction(
                                label: 'Pause',
                                icon: RemixIcons.pause_line,
                                color: AppColors.warning,
                                onTap: () => _showStatusRemarkDialog(
                                    context, ref, task.id, TaskStatus.todo),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
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
      decoration: BoxDecoration(
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
                  style: TextStyle(
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
            style: TextStyle(
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
                  Navigator.pop(context);
                  _showStatusRemarkDialog(context, ref, task.id, TaskStatus.completed);
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
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
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

Future<void> _showStatusRemarkDialog(
    BuildContext context, WidgetRef ref, String taskId, TaskStatus status,
    {VoidCallback? onSuccess}) async {
  final noteCtrl = TextEditingController();

  String actionLabel = 'Update Task';
  if (status == TaskStatus.inProgress) {
    actionLabel = 'Start Task';
  } else if (status == TaskStatus.completed) {
    actionLabel = 'Complete Task';
  } else if (status == TaskStatus.todo) {
    actionLabel = 'Pause Task';
  }

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            status == TaskStatus.completed
                ? RemixIcons.checkbox_circle_line
                : RemixIcons.chat_4_line,
            color: status == TaskStatus.completed ? AppColors.success : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            actionLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a remark or comment (optional):',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. Started working on this, completed tasks...',
              hintStyle: TextStyle(fontSize: 12, color: AppColors.textHint),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(taskViewModelProvider.notifier).updateStatus(
                  taskId,
                  status,
                  comment: noteCtrl.text.trim(),
                );
            Navigator.pop(ctx);
            if (onSuccess != null) onSuccess();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: status == TaskStatus.completed ? AppColors.success : AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirm', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
