import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';
import 'package:quickboom_hrm/features/store/data/store_models.dart';
import 'package:quickboom_hrm/features/store/presentation/providers/store_dashboard_viewmodel.dart';

class StoreEmployeesView extends ConsumerStatefulWidget {
  const StoreEmployeesView({super.key});

  @override
  ConsumerState<StoreEmployeesView> createState() => _StoreEmployeesViewState();
}

class _StoreEmployeesViewState extends ConsumerState<StoreEmployeesView> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  String? _selectedStatus;
  String? _selectedRole;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadEmployees();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final state = ref.read(storeDashboardViewModelProvider);
      if (state.employees != null && _currentPage < state.employees!.totalPages) {
        _loadMore();
      }
    }
  }

  Future<void> _loadEmployees() async {
    _currentPage = 1;
    await ref.read(storeDashboardViewModelProvider.notifier).fetchEmployees(
      page: _currentPage,
      status: _selectedStatus,
      role: _selectedRole,
    );
  }

  Future<void> _loadMore() async {
    _currentPage++;
    await ref.read(storeDashboardViewModelProvider.notifier).fetchEmployees(
      page: _currentPage,
      status: _selectedStatus,
      role: _selectedRole,
    );
  }

  Future<void> _onRefresh() async {
    await _loadEmployees();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Filter Employees'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _FilterOption(
              label: 'All',
              value: null,
              selected: _selectedStatus == null,
              onTap: () {
                setState(() => _selectedStatus = null);
                Navigator.pop(ctx);
                _loadEmployees();
              },
            ),
            _FilterOption(
              label: 'Present',
              value: 'present',
              selected: _selectedStatus == 'present',
              onTap: () {
                setState(() => _selectedStatus = 'present');
                Navigator.pop(ctx);
                _loadEmployees();
              },
            ),
            _FilterOption(
              label: 'Absent',
              value: 'absent',
              selected: _selectedStatus == 'absent',
              onTap: () {
                setState(() => _selectedStatus = 'absent');
                Navigator.pop(ctx);
                _loadEmployees();
              },
            ),
            _FilterOption(
              label: 'Late',
              value: 'late',
              selected: _selectedStatus == 'late',
              onTap: () {
                setState(() => _selectedStatus = 'late');
                Navigator.pop(ctx);
                _loadEmployees();
              },
            ),
            const SizedBox(height: 16),
            const Text('Role', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _FilterOption(
              label: 'All Roles',
              value: null,
              selected: _selectedRole == null,
              onTap: () {
                setState(() => _selectedRole = null);
                Navigator.pop(ctx);
                _loadEmployees();
              },
            ),
            _FilterOption(
              label: 'Salesman',
              value: 'Salesman',
              selected: _selectedRole == 'Salesman',
              onTap: () {
                setState(() => _selectedRole = 'Salesman');
                Navigator.pop(ctx);
                _loadEmployees();
              },
            ),
            _FilterOption(
              label: 'Helper',
              value: 'Helper',
              selected: _selectedRole == 'Helper',
              onTap: () {
                setState(() => _selectedRole = 'Helper');
                Navigator.pop(ctx);
                _loadEmployees();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Store Employees',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  RemixIcons.group_line,
                  size: 64,
                  color: AppColors.primary,
                ),
              ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 32),
              Text(
                'Store Employees',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              Text(
                'This feature will be available in the next version update. Stay tuned!',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(RemixIcons.code_box_line, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Text(
                      'Feature Coming Soon',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList(StoreDashboardState state) {
    if (state.isLoadingEmployees && state.employees == null) {
      return _buildLoadingState();
    }

    if (state.errorMessage != null && state.employees == null) {
      return _buildErrorState(state.errorMessage!);
    }

    if (state.employees == null || state.employees!.employees.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.employees!.employees.length + (state.isLoadingEmployees ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.employees!.employees.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final employee = state.employees!.employees[index];
        return _EmployeeTile(employee: employee)
            .animate()
            .fadeIn(delay: (index * 50).ms)
            .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading(
          height: 80,
          width: double.infinity,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(RemixIcons.error_warning_line, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadEmployees,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(RemixIcons.team_line, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No employees found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final StoreEmployee employee;

  const _EmployeeTile({required this.employee});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(employee.attendanceStatus);
    final statusIcon = _getStatusIcon(employee.attendanceStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getInitials(employee.name),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Employee Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        employee.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _formatStatus(employee.attendanceStatus),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      employee.employeeCode,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      employee.role,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(RemixIcons.building_line, color: AppColors.textHint, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        employee.storeName,
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Timing
          if (employee.checkInTime != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  employee.checkInTime!,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Check-in',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'NA';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.error;
      case 'late':
        return AppColors.warning;
      default:
        return AppColors.textHint;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return RemixIcons.checkbox_circle_line;
      case 'absent':
        return RemixIcons.close_circle_line;
      case 'late':
        return RemixIcons.time_line;
      default:
        return RemixIcons.question_line;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'late':
        return 'Late';
      case 'not_punched':
        return 'Not Punched';
      default:
        return status;
    }
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final String? value;
  final bool selected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (selected)
              Icon(RemixIcons.checkbox_circle_fill, color: AppColors.primary, size: 20)
            else
              Icon(RemixIcons.checkbox_blank_circle_line, color: AppColors.textHint, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
