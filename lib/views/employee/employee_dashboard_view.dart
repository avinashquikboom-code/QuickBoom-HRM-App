import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/leave_request_model.dart';
import '../../models/announcement_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/attendance_viewmodel.dart';
import '../../viewmodels/leave_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/employee_dashboard_viewmodel.dart';
import '../../core/services/biometric_service.dart';
import 'notifications_view.dart';
import 'employee_leave_view.dart';
import 'employee_expenses_view.dart';
import 'employee_tasks_view.dart';
import 'employee_shift_view.dart';

class EmployeeDashboardView extends ConsumerWidget {
  const EmployeeDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).currentUser;
    if (user == null) return const Scaffold();
    final attendanceState = ref.watch(attendanceViewModelProvider);
    final leaveState = ref.watch(leaveViewModelProvider);
    final notifState = ref.watch(notificationViewModelProvider);
    final dashboardState = ref.watch(employeeDashboardViewModelProvider);
    final now = DateTime.now();
    final greeting = _greeting();

    final announcements = dashboardState.announcements;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Premium Curved & Glowing Banner ────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                  ),
                  child: Stack(
                    children: [
                      // Ambient light circles inside the hero
                      Positioned(
                        right: -30,
                        top: -20,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -50,
                        bottom: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      // Core greeting text layout
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
                                      // Designation pill
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
                                            const Icon(Icons.badge_outlined, color: Colors.amber, size: 13),
                                            const SizedBox(width: 4),
                                            Text(
                                              user.designation,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '$greeting,',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        user.name.split(' ').first,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.7,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_month_outlined, color: Colors.white.withValues(alpha: 0.75), size: 14),
                                          const SizedBox(width: 5),
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
                                    ],
                                  ),
                                ),
                                // Glowing avatar panel
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                      ),
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
              'HRM',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 25),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsView()),
                      );
                    },
                  ),
                  if (notifState.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${notifState.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Holographic Attendance Punch Card ─────────────────────
                _TodayPunchCard(
                  isCheckedIn: attendanceState.isCheckedIn,
                  todayRecord: attendanceState.todayRecord,
                  onCheckIn: (viaFingerprint) =>
                      ref.read(attendanceViewModelProvider.notifier).checkIn(viaFingerprint: viaFingerprint),
                  onCheckOut: (viaFingerprint) =>
                      ref.read(attendanceViewModelProvider.notifier).checkOut(viaFingerprint: viaFingerprint),
                ).animate().fadeIn().slideY(begin: 0.08, end: 0),

                const SizedBox(height: 24),

                // ─── Premium Quick Action scrolling dock ───────────────────
                _SectionTitle(title: 'Quick Actions'),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _QuickActionBubble(
                        label: 'Apply Leave',
                        icon: Icons.event_outlined,
                        color: AppColors.info,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmployeeLeaveView()),
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      _QuickActionBubble(
                        label: 'Expense Claim',
                        icon: Icons.payments_outlined,
                        color: AppColors.warning,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmployeeExpensesView()),
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      _QuickActionBubble(
                        label: 'Shift Schedule',
                        icon: Icons.date_range_outlined,
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmployeeShiftView()),
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      _QuickActionBubble(
                        label: 'Tasks List',
                        icon: Icons.assignment_turned_in_outlined,
                        color: AppColors.success,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmployeeTasksView()),
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 50.ms),

                const SizedBox(height: 24),

                // ─── Task Summary ──────────────────────────────────────────
                _SectionTitle(title: 'Tasks'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryPill(
                        label: 'Pending',
                        value: '${dashboardState.stats.pendingTasks}',
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryPill(
                        label: 'Completed',
                        value: '${dashboardState.stats.completedTasks}',
                        icon: Icons.verified_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 80.ms),

                const SizedBox(height: 24),

                // ─── Double-layered Leave Balance Gauges ───────────────────
                _SectionTitle(title: 'Leave Balance'),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width < 380 ? 2 : (width > 600 ? 4 : 3);
                    final itemWidth = (width - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: _LeaveBalanceCard(
                            label: 'Casual',
                            used: leaveState.balance.casualUsed,
                            total: leaveState.balance.casualTotal,
                            color: AppColors.info,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _LeaveBalanceCard(
                            label: 'Sick',
                            used: leaveState.balance.sickUsed,
                            total: leaveState.balance.sickTotal,
                            color: AppColors.error,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _LeaveBalanceCard(
                            label: 'Earned',
                            used: leaveState.balance.earnedUsed,
                            total: leaveState.balance.earnedTotal,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    );
                  },
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 24),

                // ─── Monthly Attendance Stats ──────────────────────────────
                _SectionTitle(title: 'This Month'),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width < 380 ? 2 : (width > 600 ? 4 : 3);
                    final itemWidth = (width - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: _StatCard(
                            label: 'Present',
                            value: '${attendanceState.presentCount}',
                            icon: Icons.check_circle_outline_rounded,
                            color: AppColors.success,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _StatCard(
                            label: 'Absent',
                            value: '${attendanceState.absentCount}',
                            icon: Icons.cancel_outlined,
                            color: AppColors.error,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _StatCard(
                            label: 'Late',
                            value: '${attendanceState.lateCount}',
                            icon: Icons.schedule_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    );
                  },
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 24),

                // ─── Recent Leave Requests ─────────────────────────────────
                if (leaveState.myLeaves.isNotEmpty) ...[
                  _SectionTitle(title: 'Recent Leave Requests'),
                  const SizedBox(height: 12),
                  ...leaveState.myLeaves.take(2).map(
                        (leave) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _LeaveRequestTile(leave: leave),
                        ),
                      ),
                  const SizedBox(height: 12),
                ],

                // ─── Editorial Announcements Feed ──────────────────────────
                _SectionTitle(title: 'Announcements Feed'),
                const SizedBox(height: 12),
                ...announcements.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AnnouncementTile(announcement: a),
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

}

// ─── Sub Widgets ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _QuickActionBubble extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBubble({
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
        width: 86,
        padding: const EdgeInsets.symmetric(vertical: 14),
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
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayPunchCard extends ConsumerWidget {
  final bool isCheckedIn;
  final dynamic todayRecord;
  final void Function(bool viaFingerprint) onCheckIn;
  final void Function(bool viaFingerprint) onCheckOut;

  const _TodayPunchCard({
    required this.isCheckedIn,
    required this.todayRecord,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  Future<void> _handlePunch(BuildContext context) async {
    final hasBio = await BiometricService.isBiometricsAvailable();
    bool authenticated = false;
    if (hasBio) {
      authenticated = await BiometricService.authenticate();
      if (!authenticated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric verification failed. Please try again.'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }
    // Proceed with check-in/out
    final viaFingerprint = hasBio && authenticated;
    if (isCheckedIn) {
      onCheckOut(viaFingerprint);
    } else {
      onCheckIn(viaFingerprint);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final hasCheckIn = todayRecord?.checkIn != null;
    final hasCheckOut = todayRecord?.checkOut != null;
    final isOnBreak = todayRecord?.isOnBreak ?? false;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: hasCheckOut 
                          ? AppColors.textSecondary 
                          : (isCheckedIn 
                              ? (isOnBreak ? AppColors.warning : AppColors.success) 
                              : AppColors.warning),
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (!hasCheckOut)
                          BoxShadow(
                            color: isCheckedIn 
                                ? (isOnBreak ? AppColors.warning : AppColors.success) 
                                : AppColors.warning,
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scaleXY(begin: 0.75, end: 1.3, duration: 1100.ms)
                      .fadeIn(duration: 1100.ms),
                  const SizedBox(width: 8),
                  Text(
                    hasCheckOut 
                        ? 'Shift Completed' 
                        : (isCheckedIn 
                            ? (isOnBreak ? 'Currently on Break' : 'Currently Active') 
                            : 'Not Checked In'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('dd MMM yyyy').format(now),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _PunchTile(
                  label: 'Check In Time',
                  time: hasCheckIn ? todayRecord!.checkInLabel : '--:--',
                  icon: Icons.login_rounded,
                  color: AppColors.success,
                  isFingerprint: todayRecord?.isFingerprintCheckIn ?? false,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _PunchTile(
                  label: 'Check Out Time',
                  time: hasCheckOut ? todayRecord!.checkOutLabel : '--:--',
                  icon: Icons.logout_rounded,
                  color: hasCheckOut ? AppColors.primary : AppColors.textHint,
                  isFingerprint: todayRecord?.isFingerprintCheckOut ?? false,
                ),
              ),
            ],
          ),
          if (hasCheckIn && !hasCheckOut) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _PunchTileHorizontal(
                    label: 'Net Shift Work',
                    time: todayRecord!.workingHoursLabel,
                    icon: Icons.timelapse_rounded,
                    color: AppColors.info,
                  ),
                ),
                if (todayRecord!.totalBreakDuration != Duration.zero || isOnBreak) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PunchTileHorizontal(
                      label: 'Break Time',
                      time: todayRecord!.breakDurationLabel,
                      icon: Icons.coffee_rounded,
                      color: AppColors.warning,
                      bgColor: const Color(0xFFFFFBF0),
                    ),
                  ),
                ],
              ],
            ),
          ] else if (hasCheckIn && hasCheckOut) ...[
            const SizedBox(height: 14),
            _PunchTileHorizontal(
              label: 'Total Working Hours',
              time: todayRecord!.workingHoursLabel,
              icon: Icons.verified_rounded,
              color: AppColors.success,
            ),
          ],
          const SizedBox(height: 22),
          if (!hasCheckOut)
            Row(
              children: [
                if (isCheckedIn) ...[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          textStyle: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                        icon: Icon(isOnBreak ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 21),
                        label: Text(isOnBreak ? 'Resume Work' : 'Take Break'),
                        onPressed: () {
                          if (isOnBreak) {
                            ref.read(attendanceViewModelProvider.notifier).endBreak();
                          } else {
                            ref.read(attendanceViewModelProvider.notifier).startBreak();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isCheckedIn ? AppColors.error : AppColors.primary).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCheckedIn ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        textStyle: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      icon: const Icon(Icons.fingerprint_rounded, size: 21),
                      label: Text(isCheckedIn ? 'Check Out' : 'Check In'),
                      onPressed: () => _handlePunch(context),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 19),
                  SizedBox(width: 8),
                  Text(
                    'Perfect! Day completed.',
                    style: TextStyle(
                        color: AppColors.success,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PunchTile extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;
  final bool isFingerprint;

  const _PunchTile({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
    this.isFingerprint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (isFingerprint) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.fingerprint_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                const Text(
                  'Biometric Verified',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PunchTileHorizontal extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;
  final Color? bgColor;

  const _PunchTileHorizontal({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFF3FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  final String label;
  final int used;
  final int total;
  final Color color;

  const _LeaveBalanceCard({
    required this.label,
    required this.used,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;
    final ratio = total > 0 ? (remaining / total) : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              Icon(Icons.event_available_rounded, color: color.withValues(alpha: 0.7), size: 15),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$remaining',
                      style: TextStyle(
                          fontSize: 21, fontWeight: FontWeight.w800, color: color),
                    ),
                    Text(
                      'of $total days',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: ratio,
                      backgroundColor: color.withValues(alpha: 0.12),
                      color: color,
                      strokeWidth: 4.0,
                    ),
                  ),
                  Text(
                    '${(ratio * 100).round()}%',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _LeaveRequestTile extends StatelessWidget {
  final LeaveRequestModel leave;
  const _LeaveRequestTile({required this.leave});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(leave.status);
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.event_note_rounded, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leave.typeLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${leave.daysCount} day(s) · ${DateFormat('dd MMM yyyy').format(leave.fromDate)}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          _StatusBadge(status: leave.status),
        ],
      ),
    );
  }

  Color _statusColor(LeaveStatus s) {
    switch (s) {
      case LeaveStatus.approved:
        return AppColors.success;
      case LeaveStatus.rejected:
        return AppColors.error;
      case LeaveStatus.cancelled:
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final LeaveStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (status) {
      case LeaveStatus.approved:
        color = AppColors.success;
        bg = AppColors.successSurface;
        break;
      case LeaveStatus.rejected:
        color = AppColors.error;
        bg = AppColors.errorSurface;
        break;
      case LeaveStatus.pending:
        color = AppColors.warning;
        bg = AppColors.warningSurface;
        break;
      default:
        color = AppColors.textSecondary;
        bg = AppColors.background;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name[0].toUpperCase() + status.name.substring(1),
        style: TextStyle(
            color: color, fontSize: 10.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final AnnouncementModel announcement;
  const _AnnouncementTile({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor(announcement.category);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  announcement.categoryLabel,
                  style: TextStyle(
                      color: catColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM yyyy').format(announcement.date),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement.title,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            announcement.description,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary, height: 1.45),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.person, size: 10, color: AppColors.primary),
              ),
              const SizedBox(width: 6),
              Text(
                announcement.postedBy,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.timer_outlined, size: 11, color: AppColors.textHint),
              const SizedBox(width: 3),
              const Text(
                '2 min read',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _catColor(AnnouncementCategory c) {
    switch (c) {
      case AnnouncementCategory.holiday:
        return AppColors.success;
      case AnnouncementCategory.policy:
        return AppColors.info;
      case AnnouncementCategory.event:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
