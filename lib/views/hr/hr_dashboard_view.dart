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

    // Calculate dynamic attendance rate percentage
    final attendanceRate = totalEmployees > 0 
        ? ((presentToday / totalEmployees) * 100).round() 
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Executive Analytics Curved Bar ─────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            floating: false,
            backgroundColor: AppColors.primaryDark,
            automaticallyImplyLeading: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 25),
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
                            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                  ),
                  child: Stack(
                    children: [
                      // Ambient design elements
                      Positioned(
                        right: -10,
                        top: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -40,
                        bottom: -30,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 85, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Weather/Status capsule paring
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              '📈 $attendanceRate% Active Today',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Hello, ${user.name.split(' ').first}!',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.6,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('EEEE, d MMMM').format(now),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.75),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Glowing executive initials badge
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.35),
                                        width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
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
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: Text(
              'HR Administrative Console',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Executive Stats Grid (Calculated & Responsive) ───────────
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
                            ratio: 1.0,
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
                            ratio: totalEmployees > 0 ? (presentToday / totalEmployees) : 0.0,
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
                            ratio: totalEmployees > 0 ? (onLeave / totalEmployees) : 0.0,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _StatCard(
                            label: 'Pending Leaves',
                            value: '$pendingLeaves',
                            icon: Icons.pending_actions_rounded,
                            color: AppColors.error,
                            bgColor: AppColors.errorSurface,
                            ratio: totalEmployees > 0 ? (pendingLeaves / totalEmployees).clamp(0.0, 1.0) : 0.0,
                          ),
                        ),
                      ],
                    );
                  },
                ).animate().fadeIn(),

                const SizedBox(height: 24),

                // ─── Interactive Quick Actions ───────────────────────────────
                const Text(
                  'Quick Action Panel',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _QuickActionBtn(
                        label: 'Reports Feed',
                        icon: Icons.analytics_outlined,
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HrReportsView()));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionBtn(
                        label: 'Expense Claims',
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HrExpensesView()));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionBtn(
                        label: 'Shift Rosters',
                        icon: Icons.schedule_rounded,
                        color: AppColors.info,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HrShiftsView()));
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Department Summary Bars ─────────────────────────────────
                const Text(
                  'Department Breakdown',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                _DepartmentOverview(employees: employeeState.employees),

                const SizedBox(height: 24),

                // ─── Interactive Pending Leave Requests ─────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending Leave Approvals',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                    if (pendingLeaves > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.errorSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pendingLeaves Actionable',
                          style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
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
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Brilliant! All leaves reviewed.',
                          style: TextStyle(
                              color: AppColors.success,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  )
                else
                  ...hrLeaveState.pendingLeaves.take(3).map(
                        (leave) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PendingLeaveCard(leave: leave),
                        ),
                      ),

                const SizedBox(height: 24),
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
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
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
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      '$count Staff (${(progress * 100).round()}%)',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
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
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.15), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    leave.employeeName.substring(0, 1),
                    style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w900,
                        fontSize: 18),
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
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${leave.typeLabel} · ${leave.daysCount} day(s)',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              // Category tag status pill
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
                      fontWeight: FontWeight.w800),
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
                style: const TextStyle(
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
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  onPressed: () => ref.read(hrLeaveViewModelProvider.notifier).rejectLeave(leave.id, reviewerName, 'Rejected'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  onPressed: () => ref.read(hrLeaveViewModelProvider.notifier).approveLeave(leave.id, reviewerName),
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
              style: const TextStyle(
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
