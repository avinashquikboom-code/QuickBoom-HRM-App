import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:remixicon/remixicon.dart';
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
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  String? _selectedStatus;
  String _searchQuery = '';

  // Filter chips for quick filtering
  static const _statusFilters = [
    {'label': 'All', 'value': null},
    {'label': 'Present', 'value': 'present'},
    {'label': 'Absent', 'value': 'absent'},
    {'label': 'Late', 'value': 'late'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadEmployees();
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(storeDashboardViewModelProvider);
      if (state.employees != null &&
          _currentPage < state.employees!.totalPages &&
          !state.isLoadingEmployees) {
        _loadMore();
      }
    }
  }

  Future<void> _loadEmployees() async {
    _currentPage = 1;
    await ref.read(storeDashboardViewModelProvider.notifier).fetchEmployees(
          page: _currentPage,
          status: _selectedStatus,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
        );
  }

  Future<void> _loadMore() async {
    _currentPage++;
    await ref.read(storeDashboardViewModelProvider.notifier).fetchEmployees(
          page: _currentPage,
          status: _selectedStatus,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
        );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    // Debounce search
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_searchQuery == value) {
        _loadEmployees();
      }
    });
  }

  void _selectStatus(String? status) {
    setState(() => _selectedStatus = status);
    _loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeDashboardViewModelProvider);

    // Attendance summary counts
    final employees = state.employees?.employees ?? [];
    final presentCount = employees.where((e) => e.attendanceStatus == 'present').length;
    final absentCount = employees.where((e) => e.attendanceStatus == 'absent').length;
    final lateCount = employees.where((e) => e.attendanceStatus == 'late').length;
    final notPunchedCount = employees.where((e) => e.attendanceStatus == 'not_punched').length;

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
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(RemixIcons.refresh_line, color: AppColors.textSecondary),
            onPressed: _loadEmployees,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(RemixIcons.search_line, color: AppColors.textHint, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by name or employee code...',
                      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    child: Icon(RemixIcons.close_circle_fill, color: AppColors.textHint, size: 18),
                  ),
              ],
            ),
          ),

          // ── Status Filter Chips ───────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final isSelected = _selectedStatus == filter['value'];
                final color = _filterColor(filter['value'] as String?);
                return GestureDetector(
                  onTap: () => _selectStatus(filter['value'] as String?),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : AppColors.cardBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      filter['label'] as String,
                      style: TextStyle(
                        color: isSelected ? color : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Stats Summary Strip ───────────────────────────────────
          if (state.employees != null && employees.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(label: 'Present', value: presentCount, color: const Color(0xFF22C55E)),
                  _MiniStat(label: 'Late', value: lateCount, color: const Color(0xFFF59E0B)),
                  _MiniStat(label: 'Absent', value: absentCount, color: const Color(0xFFEF4444)),
                  _MiniStat(label: 'Not Punched', value: notPunchedCount, color: AppColors.textHint),
                ],
              ),
            ),

          // ── Employee List ─────────────────────────────────────────
          const SizedBox(height: 12),
          Expanded(
            child: _buildList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildList(StoreDashboardState state) {
    if (state.isLoadingEmployees && state.employees == null) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerLoading(
            height: 90,
            width: double.infinity,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
    }

    if (state.errorMessage != null && state.employees == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(RemixIcons.error_warning_line, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text('Failed to load employees', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 16)),
            const SizedBox(height: 8),
            Text(state.errorMessage!, style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadEmployees,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(RemixIcons.refresh_line, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final employees = state.employees?.employees ?? [];

    if (employees.isEmpty && !state.isLoadingEmployees) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(RemixIcons.team_line, size: 48, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),
            Text('No Employees Found', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              _selectedStatus != null || _searchQuery.isNotEmpty
                  ? 'Try adjusting your filters or search query.'
                  : 'No employees are assigned to this store yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEmployees,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: employees.length + (state.isLoadingEmployees ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == employees.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _EmployeeCard(employee: employees[index])
              .animate()
              .fadeIn(delay: (index * 40).ms, duration: 300.ms)
              .slideY(begin: 0.06, end: 0, duration: 300.ms);
        },
      ),
    );
  }

  Color _filterColor(String? status) {
    switch (status) {
      case 'present': return const Color(0xFF22C55E);
      case 'absent': return const Color(0xFFEF4444);
      case 'late': return const Color(0xFFF59E0B);
      default: return AppColors.primary;
    }
  }
}

// ─── Mini Stat Widget ─────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textHint),
        ),
      ],
    );
  }
}

// ─── Employee Card ────────────────────────────────────────────────────────────

class _EmployeeCard extends StatelessWidget {
  final StoreEmployee employee;

  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(employee.attendanceStatus);
    final statusBg = statusColor.withValues(alpha: 0.08);
    final statusLabel = _statusLabel(employee.attendanceStatus);
    final statusIcon = _statusIcon(employee.attendanceStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with status dot
          Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _initials(employee.name),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Info
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withValues(alpha: 0.15), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        employee.employeeCode,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${employee.designation} • ${employee.department}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Check-in / Check-out times
                if (employee.checkInTime != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(RemixIcons.login_circle_line, size: 11, color: const Color(0xFF22C55E)),
                        const SizedBox(width: 5),
                        Text(
                          'In: ${_formatTime(employee.checkInTime!)}',
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (employee.checkOutTime != null) ...[
                          const SizedBox(width: 10),
                          Icon(RemixIcons.logout_circle_line, size: 11, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            'Out: ${_formatTime(employee.checkOutTime!)}',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name.substring(0, name.length.clamp(0, 2)).toUpperCase() : 'NA';
  }

  String _formatTime(String raw) {
    // raw might be 'HH:mm:ss' or ISO
    if (raw.contains('T')) {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final h = dt.toLocal().hour;
        final m = dt.toLocal().minute.toString().padLeft(2, '0');
        final period = h >= 12 ? 'PM' : 'AM';
        final hr = (h > 12 ? h - 12 : h == 0 ? 12 : h).toString();
        return '$hr:$m $period';
      }
    }
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present': return const Color(0xFF22C55E);
      case 'absent': return const Color(0xFFEF4444);
      case 'late': return const Color(0xFFF59E0B);
      default: return AppColors.textHint;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present': return RemixIcons.checkbox_circle_fill;
      case 'absent': return RemixIcons.close_circle_fill;
      case 'late': return RemixIcons.time_fill;
      default: return RemixIcons.question_fill;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'present': return 'PRESENT';
      case 'absent': return 'ABSENT';
      case 'late': return 'LATE';
      case 'not_punched': return 'NOT PUNCHED';
      default: return status.toUpperCase();
    }
  }
}
