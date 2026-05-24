import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/leave_request_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/employee_list_viewmodel.dart';
import '../../viewmodels/hr_leave_viewmodel.dart';
import '../auth/login_view.dart';
import 'hr_reports_view.dart';
import 'hr_expenses_view.dart';
import 'hr_shifts_view.dart';

class HrDashboardView extends ConsumerWidget {
  const HrDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).currentUser;
    if (user == null) return const Scaffold();
    final employeeState = ref.watch(employeeListViewModelProvider);
    final hrLeaveState = ref.watch(hrLeaveViewModelProvider);
    final now = DateTime.now();

    final totalEmployees = employeeState.employees.length;
    final pendingLeaves = hrLeaveState.pendingLeaves.length;
    // Mock present count
    final presentToday = (totalEmployees * 0.85).round();
    final onLeave = hrLeaveState.allLeaves
        .where((l) =>
            l.status == LeaveStatus.approved &&
            !l.fromDate.isAfter(now) &&
            !l.toDate.isBefore(now))
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── HR App Bar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            floating: false,
            backgroundColor: AppColors.primaryDark,
            automaticallyImplyLeading: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 24),
                onPressed: () {},
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (v) {
                  if (v == 'logout') {
                    ref.read(authViewModelProvider.notifier).logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginView()),
                      (_) => false,
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded,
                            size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Logout',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                user.initials,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${user.name.split(' ').first}!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  DateFormat('EEEE, d MMMM').format(now),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: Text(
              'HR Dashboard',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Stats Grid ─────────────────────────────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width < 600 ? 2 : 4;
                    final itemWidth = (width - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: _StatCard(
                            label: 'Total Employees',
                            value: '$totalEmployees',
                            icon: Icons.people_rounded,
                            color: AppColors.primary,
                            bgColor: AppColors.primarySurface,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _StatCard(
                            label: 'Present Today',
                            value: '$presentToday',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                            bgColor: AppColors.successSurface,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _StatCard(
                            label: 'On Leave',
                            value: '$onLeave',
                            icon: Icons.event_busy_rounded,
                            color: AppColors.warning,
                            bgColor: AppColors.warningSurface,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _StatCard(
                            label: 'Pending Requests',
                            value: '$pendingLeaves',
                            icon: Icons.pending_actions_rounded,
                            color: AppColors.error,
                            bgColor: AppColors.errorSurface,
                          ),
                        ),
                      ],
                    );
                  },
                ).animate().fadeIn(),

                const SizedBox(height: 20),

                // ─── Quick Actions ───────────────────────────────────────────
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickActionBtn(
                      label: 'Reports',
                      icon: Icons.analytics_outlined,
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HrReportsView()));
                      },
                    ),
                    _QuickActionBtn(
                      label: 'Expenses',
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.warning,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HrExpensesView()));
                      },
                    ),
                    _QuickActionBtn(
                      label: 'Shifts',
                      icon: Icons.schedule_rounded,
                      color: AppColors.info,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HrShiftsView()));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ─── Department Summary ──────────────────────────────────────
                const Text(
                  'Department Overview',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                _DepartmentOverview(
                    employees: employeeState.employees),

                const SizedBox(height: 20),

                // ─── Pending Leave Requests ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending Leaves',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    if (pendingLeaves > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.errorSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pendingLeaves',
                          style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (hrLeaveState.pendingLeaves.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'All leaves reviewed!',
                          style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                else
                  ...hrLeaveState.pendingLeaves.take(3).map(
                        (leave) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PendingLeaveCard(leave: leave),
                        ),
                      ),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Department Overview ──────────────────────────────────────────────────────

class _DepartmentOverview extends StatelessWidget {
  final List employees;
  const _DepartmentOverview({required this.employees});

  @override
  Widget build(BuildContext context) {
    final deptMap = <String, int>{};
    for (final e in employees) {
      deptMap[e.department] = (deptMap[e.department] ?? 0) + 1;
    }
    final total = employees.length;

    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
      AppColors.success,
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: deptMap.entries.toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final dept = entry.value.key;
          final count = entry.value.value;
          final color = colors[idx % colors.length];
          final progress = total > 0 ? count / total : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dept,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      '$count employee(s)',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: color.withValues(alpha: 0.1),
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Pending Leave Card ───────────────────────────────────────────────────────

class _PendingLeaveCard extends StatelessWidget {
  final LeaveRequestModel leave;
  const _PendingLeaveCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.15), width: 1.5),
            ),
            child: Center(
              child: Text(
                leave.employeeName.substring(0, 1),
                style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                    fontSize: 17),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leave.employeeName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${leave.typeLabel} · ${leave.daysCount} day(s)',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.warningSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
