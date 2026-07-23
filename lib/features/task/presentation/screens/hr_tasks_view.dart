import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/task/data/models/task_model.dart';
import 'package:quickboom_hrm/features/task/presentation/providers/hr_task_viewmodel.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';
import 'package:quickboom_hrm/features/employees/presentation/providers/employee_list_viewmodel.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';


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
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Task Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.background,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const _AssignTaskSheet(),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(RemixIcons.add_line, color: Colors.white),
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

            Text(
              'All Tasks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            if (state.isLoading && state.allTasks.isEmpty)
              Column(
                children: [
                  ShimmerLoading(
                    height: 80,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 12),
                  ShimmerLoading(
                    height: 80,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 12),
                  ShimmerLoading(
                    height: 80,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              )
            else if (state.allTasks.isEmpty)
              Center(
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
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
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
              Icon(RemixIcons.user_3_line, size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text(task.assignedToName, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              Icon(RemixIcons.calendar_event_line, size: 14, color: AppColors.textHint),
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

class _AssignTaskSheet extends ConsumerStatefulWidget {
  const _AssignTaskSheet();

  @override
  ConsumerState<_AssignTaskSheet> createState() => _AssignTaskSheetState();
}

class _AssignTaskSheetState extends ConsumerState<_AssignTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();
  
  UserModel? _selectedEmployee;
  TaskPriority _priority = TaskPriority.medium;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String _employeeSearchQuery = '';
  bool _requiresPhoto = false;

  final List<Map<String, dynamic>> _fixedTemplates = [
    {
      'title': 'Daily Store Opening & Sanitization',
      'desc': 'Verify store cleanliness, turn on lights, inspect counter setup, and upload photo proof.',
      'priority': TaskPriority.high,
      'requiresPhoto': true,
    },
    {
      'title': 'Store Closing Cash & Security Lockup',
      'desc': 'Count cash register, balance ledger slip, capture photo of cash drawer, and lock entrance.',
      'priority': TaskPriority.high,
      'requiresPhoto': true,
    },
    {
      'title': 'Inventory & Display Stock Audit',
      'desc': 'Inspect shelf stock, arrange front store display, and upload photo proof.',
      'priority': TaskPriority.medium,
      'requiresPhoto': true,
    },
    {
      'title': 'Staff Uniform & Hygiene Check',
      'desc': 'Inspect staff uniform compliance, clean counter area, and verify customer feedback log.',
      'priority': TaskPriority.medium,
      'requiresPhoto': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(employeeListViewModelProvider.notifier).fetchEmployees(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesState = ref.watch(employeeListViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final tasksState = ref.watch(hrTaskViewModelProvider);

    final filteredEmployees = employeesState.filteredEmployees.where((e) {
      final name = e.name.toLowerCase();
      final code = e.employeeId.toLowerCase();
      final query = _employeeSearchQuery.toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle Indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(RemixIcons.task_line, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign New Task',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Assign tasks and set completion proof rules',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(RemixIcons.close_line, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fixed Presets Section
              Row(
                children: [
                  Icon(RemixIcons.flashlight_fill, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text(
                    'Quick Task Presets:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fixedTemplates.length,
                  itemBuilder: (context, index) {
                    final tmpl = _fixedTemplates[index];
                    final isPhotoReq = tmpl['requiresPhoto'] == true;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _titleController.text = tmpl['title'].toString();
                            _descController.text = tmpl['desc'].toString();
                            _priority = tmpl['priority'] as TaskPriority;
                            _requiresPhoto = isPhotoReq;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isPhotoReq
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPhotoReq
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : AppColors.cardBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPhotoReq ? RemixIcons.camera_line : RemixIcons.checkbox_circle_line,
                                size: 14,
                                color: isPhotoReq ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tmpl['title'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isPhotoReq ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Task Title
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Task Title *',
                  labelStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                  prefixIcon: Icon(RemixIcons.edit_2_line, color: AppColors.primary, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a task title' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Description / Instructions',
                  labelStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                  prefixIcon: Icon(RemixIcons.file_text_line, color: AppColors.textHint, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Employee Selection Card
              Text(
                'Assign To Employee *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              if (_selectedEmployee != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _selectedEmployee!.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedEmployee!.name,
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                            ),
                            Text(
                              'Code: ${_selectedEmployee!.employeeId}',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _selectedEmployee = null),
                        icon: Icon(RemixIcons.close_circle_fill, color: AppColors.error, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                )
              else ...[
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  onChanged: (val) => setState(() => _employeeSearchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search employee by name or code...',
                    hintStyle: TextStyle(color: AppColors.textHint, fontSize: 12),
                    prefixIcon: Icon(RemixIcons.search_2_line, size: 18, color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: employeesState.isLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                      : filteredEmployees.isEmpty
                          ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('No employees found', style: TextStyle(color: AppColors.textHint, fontSize: 12))))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredEmployees.length,
                              separatorBuilder: (_, index) => Divider(height: 1, color: AppColors.cardBorder),
                              itemBuilder: (context, index) {
                                final emp = filteredEmployees[index];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      emp.name.isNotEmpty ? emp.name.substring(0, 1).toUpperCase() : 'E',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  title: Text(
                                    emp.name,
                                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    'Code: ${emp.employeeId}',
                                    style: TextStyle(color: AppColors.textHint, fontSize: 11),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedEmployee = emp;
                                      _employeeSearchQuery = '';
                                      _searchController.clear();
                                    });
                                  },
                                );
                              },
                            ),
                ),
              ],
              const SizedBox(height: 16),

              // Priority Segmented Selector
              Text(
                'Priority *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _PrioritySegment(
                    label: 'Low',
                    color: AppColors.success,
                    isSelected: _priority == TaskPriority.low,
                    onTap: () => setState(() => _priority = TaskPriority.low),
                  ),
                  const SizedBox(width: 8),
                  _PrioritySegment(
                    label: 'Medium',
                    color: AppColors.warning,
                    isSelected: _priority == TaskPriority.medium,
                    onTap: () => setState(() => _priority = TaskPriority.medium),
                  ),
                  const SizedBox(width: 8),
                  _PrioritySegment(
                    label: 'High',
                    color: AppColors.error,
                    isSelected: _priority == TaskPriority.high,
                    onTap: () => setState(() => _priority = TaskPriority.high),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Due Date Picker & Shortcuts
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.cardBorder),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd MMM yyyy').format(_dueDate),
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Icon(RemixIcons.calendar_event_line, size: 18, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quick Date Shortcut Chips
              Row(
                children: [
                  _DateShortcutChip(
                    label: 'Tomorrow',
                    onTap: () => setState(() => _dueDate = DateTime.now().add(const Duration(days: 1))),
                  ),
                  const SizedBox(width: 6),
                  _DateShortcutChip(
                    label: 'In 3 Days',
                    onTap: () => setState(() => _dueDate = DateTime.now().add(const Duration(days: 3))),
                  ),
                  const SizedBox(width: 6),
                  _DateShortcutChip(
                    label: 'Next Week',
                    onTap: () => setState(() => _dueDate = DateTime.now().add(const Duration(days: 7))),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Photo Proof Requirement Switch Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _requiresPhoto
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _requiresPhoto
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _requiresPhoto
                            ? AppColors.primary
                            : AppColors.textHint.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        RemixIcons.camera_lens_line,
                        color: _requiresPhoto ? Colors.white : AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requires Photo Proof',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Employee must click & upload photo to complete',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _requiresPhoto,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) => setState(() => _requiresPhoto = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Assign Task Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: tasksState.isCreating
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          if (_selectedEmployee == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select an employee.')),
                            );
                            return;
                          }

                          final creatorId = authState.currentUser?.id ?? '';
                          final creatorName = authState.currentUser?.name ?? '';

                          await ref.read(hrTaskViewModelProvider.notifier).createTask(
                                title: _titleController.text.trim(),
                                description: _descController.text.trim(),
                                assignedToId: _selectedEmployee!.id,
                                assignedToName: _selectedEmployee!.name,
                                projectName: 'General',
                                dueDate: _dueDate,
                                priority: _priority,
                                creatorId: creatorId,
                                creatorName: creatorName,
                                requiresPhoto: _requiresPhoto,
                              );

                          final updatedState = ref.read(hrTaskViewModelProvider);
                          final currentContext = context;
                          if (updatedState.successMessage != null) {
                            if (currentContext.mounted) {
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                SnackBar(content: Text(updatedState.successMessage!)),
                              );
                            }
                            ref.read(hrTaskViewModelProvider.notifier).clearMessage();
                            if (currentContext.mounted) {
                              Navigator.pop(currentContext);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: tasksState.isCreating
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(RemixIcons.send_plane_fill, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Assign Task',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
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
}

// ─── Priority Segment Widget ──────────────────────────────────────────────────

class _PrioritySegment extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PrioritySegment({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Date Shortcut Chip ───────────────────────────────────────────────────────

class _DateShortcutChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateShortcutChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
      ),
    );
  }
}
