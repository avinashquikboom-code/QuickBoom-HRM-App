import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/leave/data/models/leave_request_model.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';
import 'package:quickboom_hrm/features/employees/presentation/providers/employee_list_viewmodel.dart';
import 'package:quickboom_hrm/features/leave/presentation/providers/hr_leave_viewmodel.dart';
import 'package:quickboom_hrm/features/dashboard/presentation/providers/hr_dashboard_viewmodel.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';
import 'package:quickboom_hrm/features/auth/presentation/screens/login_view.dart';
import 'package:quickboom_hrm/features/reports/presentation/screens/hr_reports_view.dart';
import 'package:quickboom_hrm/features/wallet/presentation/screens/hr_wallet_view.dart';
import 'package:quickboom_hrm/features/expense/presentation/screens/hr_expenses_view.dart';
import 'package:quickboom_hrm/features/shift/presentation/screens/hr_shifts_view.dart';
import 'package:quickboom_hrm/features/attendance/presentation/screens/hr_attendance_view.dart';
import 'package:quickboom_hrm/features/notification/presentation/screens/hr_notifications_view.dart';
import 'package:quickboom_hrm/features/store/presentation/screens/store_dashboard_view.dart';
import 'package:quickboom_hrm/features/store/presentation/screens/store_employees_view.dart';
import 'package:quickboom_hrm/core/services/permission_service.dart';

class HrDashboardView extends ConsumerWidget {
  const HrDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).currentUser;
    if (user == null) return const Scaffold();
    final dashboardState = ref.watch(hrDashboardViewModelProvider);
    final employeeState = ref.watch(employeeListViewModelProvider);
    final hrLeaveState = ref.watch(hrLeaveViewModelProvider);
    final now = DateTime.now();

    final stats = dashboardState.stats;
    final totalEmployees = stats.totalEmployees;
    final presentToday = stats.presentToday;
    final pendingLeaves = stats.pendingLeaves;
    final onLeave = hrLeaveState.allLeaves
        .where(
          (l) =>
              l.status == LeaveStatus.approved &&
              !l.fromDate.isAfter(now) &&
              !l.toDate.isBefore(now),
        )
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Compact Redesigned Executive App Bar ──────────────────────────
          SliverAppBar(
            expandedHeight: 76,
            pinned: true,
            floating: false,
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(
                  RemixIcons.notification_3_line,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HrNotificationsView(),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(RemixIcons.more_2_fill, color: AppColors.textPrimary),
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
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          RemixIcons.logout_box_line,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Logout',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user.name.split(' ').first}!',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, d MMMM').format(now),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ─── Executive Stats Grid (Calculated & Responsive) ───────────
                if (dashboardState.isLoading)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ShimmerLoading(
                        height: 100,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      ShimmerLoading(
                        height: 100,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ],
                  )
                else
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
                              icon: RemixIcons.group_line,
                              color: AppColors.primary,
                              bgColor: AppColors.primarySurface,
                              ratio: 1.0,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              label: 'Present Today',
                              value: '$presentToday',
                              icon: RemixIcons.checkbox_circle_line,
                              color: AppColors.success,
                              bgColor: AppColors.successSurface,
                              ratio: totalEmployees > 0
                                  ? (presentToday / totalEmployees)
                                  : 0.0,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              label: 'On Leave',
                              value: '$onLeave',
                              icon: RemixIcons.calendar_close_line,
                              color: AppColors.warning,
                              bgColor: AppColors.warningSurface,
                              ratio: totalEmployees > 0
                                  ? (onLeave / totalEmployees)
                                  : 0.0,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _StatCard(
                              label: 'Pending Leaves',
                              value: '$pendingLeaves',
                              icon: RemixIcons.time_line,
                              color: AppColors.error,
                              bgColor: AppColors.errorSurface,
                              ratio: totalEmployees > 0
                                  ? (pendingLeaves / totalEmployees).clamp(
                                      0.0,
                                      1.0,
                                    )
                                  : 0.0,
                            ),
                          ),
                        ],
                      );
                    },
                  ).animate().fadeIn(),

                const SizedBox(height: 24),

                // ─── Interactive Quick Actions ───────────────────────────────
                Text(
                  'Quick Action Panel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _QuickActionBtn(
                      label: 'Reports Feed',
                      icon: RemixIcons.bar_chart_2_line,
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HrReportsView(),
                          ),
                        );
                      },
                    ),
                    _QuickActionBtn(
                      label: 'Attendance Logs',
                      icon: RemixIcons.checkbox_circle_line,
                      color: AppColors.success,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HrAttendanceView(),
                          ),
                        );
                      },
                    ),
                    _QuickActionBtn(
                      label: 'Expense Claims',
                      icon: RemixIcons.bill_line,
                      color: AppColors.warning,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HrExpensesView(),
                          ),
                        );
                      },
                    ),
                    _QuickActionBtn(
                      label: 'Shift Rosters',
                      icon: RemixIcons.time_line,
                      color: AppColors.info,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HrShiftsView(),
                          ),
                        );
                      },
                    ),
                    _QuickActionBtn(
                      label: 'Wallets & Comm.',
                      icon: RemixIcons.wallet_line,
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HrWalletView(),
                          ),
                        );
                      },
                    ),
                    if (PermissionService.canAccessStoreDashboard(user))
                      _QuickActionBtn(
                        label: 'Store Dashboard',
                        icon: RemixIcons.store_2_line,
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StoreDashboardView(),
                            ),
                          );
                        },
                      ),
                    if (PermissionService.canManageStoreEmployees(user))
                      _QuickActionBtn(
                        label: 'Store Employees',
                        icon: RemixIcons.team_line,
                        color: AppColors.success,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StoreEmployeesView(),
                            ),
                          );
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Department Summary Bars ─────────────────────────────────
                Text(
                  'Department Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _DepartmentOverview(employees: employeeState.employees),

                const SizedBox(height: 24),

                // ─── Interactive Pending Leave Requests ─────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending Leave Approvals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (pendingLeaves > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pendingLeaves Actionable',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (hrLeaveState.pendingLeaves.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          RemixIcons.checkbox_circle_line,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Brilliant! All leaves reviewed.',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...hrLeaveState.pendingLeaves
                      .take(3)
                      .map(
                        (leave) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PendingLeaveCard(leave: leave),
                        ),
                      ),

                const SizedBox(height: 110),
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
  final double ratio;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.ratio,
  });

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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              // Tiny radial status rings
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: ratio,
                  backgroundColor: color.withValues(alpha: 0.08),
                  color: color,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Department Summary Overview ─────────────────────────────────────────────

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$count Staff (${(progress * 100).round()}%)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: color.withValues(alpha: 0.08),
                    color: color,
                    minHeight: 7,
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

// ─── Pending Leave Card with inline actions ──────────────────────────────────

class _PendingLeaveCard extends ConsumerWidget {
  final LeaveRequestModel leave;
  const _PendingLeaveCard({required this.leave});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authViewModelProvider).currentUser;
    final reviewerName = user?.name ?? 'Sarah Johnson';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Circular initials avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    leave.employeeName.substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${leave.typeLabel} · ${leave.daysCount} day(s)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Category tag status pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (leave.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                '"${leave.reason}"',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Inline functional action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.35),
                    ),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(RemixIcons.close_circle_line, size: 16),
                  label: const Text(
                    'Reject',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () => ref
                      .read(hrLeaveViewModelProvider.notifier)
                      .rejectLeave(leave.id, reviewerName, 'Rejected'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(
                    RemixIcons.checkbox_circle_line,
                    size: 16,
                  ),
                  label: const Text(
                    'Approve',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () => ref
                      .read(hrLeaveViewModelProvider.notifier)
                      .approveLeave(leave.id, reviewerName),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action Button ──────────────────────────────────────────────────────

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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
