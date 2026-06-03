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
import 'notifications_view.dart';
import 'employee_expenses_view.dart';
import 'employee_shift_view.dart';
import '../../core/services/biometric_service.dart';
import 'package:remixicon/remixicon.dart';

final geofenceSimulatedProvider = StateProvider<bool>((ref) => true);

class _HolidayItem {
  final String name;
  final String date;
  final bool isPublic;

  const _HolidayItem({required this.name, required this.date, required this.isPublic});
}

final _upcomingHolidays = const [
  _HolidayItem(name: 'Republic Day', date: '26 Jan 2026', isPublic: true),
  _HolidayItem(name: 'Mahashivratri', date: '15 Feb 2026', isPublic: true),
  _HolidayItem(name: 'Holi Festival', date: '03 Mar 2026', isPublic: true),
  _HolidayItem(name: 'Company Foundation Day', date: '12 Apr 2026', isPublic: false),
  _HolidayItem(name: 'Good Friday', date: '17 Apr 2026', isPublic: true),
  _HolidayItem(name: 'Annual Company Picnic', date: '22 Nov 2026', isPublic: false),
  _HolidayItem(name: 'Diwali Break', date: '12 Nov 2026', isPublic: true),
  _HolidayItem(name: 'Christmas Eve', date: '24 Dec 2026', isPublic: false),
  _HolidayItem(name: 'Christmas Day', date: '25 Dec 2026', isPublic: true),
];

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
    final announcements = dashboardState.announcements;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Premium Curved & Glowing Banner ────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: AppColors.background,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 76,
            titleSpacing: 16,
            title: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
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
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 1.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.designation,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(RemixIcons.calendar_2_line, color: AppColors.textSecondary, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('EEE, d MMM').format(now),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16, top: 14, bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(RemixIcons.notification_3_line, color: AppColors.textPrimary, size: 20),
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
                        top: 8,
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
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: 80, // Reduced padding since no FAB
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Holographic Attendance Punch Card ─────────────────────
                _TodayPunchCard(
                  isCheckedIn: attendanceState.isCheckedIn,
                  todayRecord: attendanceState.todayRecord,
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
                        label: 'Expense Claim',
                        icon: RemixIcons.money_dollar_box_line,
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
                        icon: RemixIcons.calendar_todo_line,
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmployeeShiftView()),
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 50.ms),

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

                // ─── Upcoming Holidays Calendar ──────────────────────────────
                _SectionTitle(title: 'Holidays Calendar'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _upcomingHolidays.length,
                    itemBuilder: (context, index) {
                      final item = _upcomingHolidays[index];
                      return Container(
                        width: 190,
                        margin: const EdgeInsets.only(right: 14),
                        padding: const EdgeInsets.all(12),
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
                                color: (item.isPublic ? AppColors.info : AppColors.primary).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                item.isPublic ? RemixIcons.global_line : RemixIcons.building_4_line,
                                color: item.isPublic ? AppColors.info : AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.date,
                                    style: const TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.isPublic ? 'Public Holiday' : 'Company Holiday',
                                    style: TextStyle(
                                      color: item.isPublic ? AppColors.info : AppColors.primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 120.ms),

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
                            icon: RemixIcons.checkbox_circle_line,
                            color: AppColors.success,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _StatCard(
                            label: 'Absent',
                            value: '${attendanceState.absentCount}',
                            icon: RemixIcons.close_circle_line,
                            color: AppColors.error,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _StatCard(
                            label: 'Late',
                            value: '${attendanceState.lateCount}',
                            icon: RemixIcons.time_line,
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
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1.2,
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

  const _TodayPunchCard({
    required this.isCheckedIn,
    required this.todayRecord,
  });

  Future<void> _handlePunch(BuildContext context, WidgetRef ref, {required bool isInRadius}) async {
    if (!isCheckedIn && !isInRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(RemixIcons.error_warning_line, color: Colors.white),
              const SizedBox(width: 10),
              const Text('Punch blocked: You are outside the office geofence.'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final isAvailable = await BiometricService.isBiometricsAvailable();
    if (!isAvailable) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(RemixIcons.close_circle_line, color: Colors.white),
                const SizedBox(width: 10),
                const Text('Biometric authentication not enrolled or available.'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }
    
    final authenticated = await BiometricService.authenticate();
    if (!authenticated) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(RemixIcons.error_warning_line, color: Colors.white),
                const SizedBox(width: 10),
                const Text('Biometric verification failed.'),
              ],
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    final success = isCheckedIn
        ? await ref.read(attendanceViewModelProvider.notifier).checkOut(viaFingerprint: true)
        : await ref.read(attendanceViewModelProvider.notifier).checkIn(viaFingerprint: true);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(RemixIcons.checkbox_circle_line, color: Colors.white),
              const SizedBox(width: 10),
              Text(isCheckedIn ? 'Checked out successfully!' : 'Checked in successfully!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final hasCheckIn = todayRecord?.checkIn != null;
    final hasCheckOut = todayRecord?.checkOut != null;
    final isOnBreak = todayRecord?.isOnBreak ?? false;
    final isInRadius = ref.watch(geofenceSimulatedProvider);

    Color scannerColor;
    String statusText;
    bool isInteractive = false;
    bool showScanBeam = false;

    if (hasCheckOut) {
      scannerColor = Colors.grey;
      statusText = 'Shift Completed';
      isInteractive = false;
      showScanBeam = false;
    } else if (isCheckedIn) {
      scannerColor = AppColors.error;
      statusText = 'Scan Fingerprint to Punch Out';
      isInteractive = true;
      showScanBeam = true;
    } else {
      if (isInRadius) {
        scannerColor = AppColors.success;
        statusText = 'Scan Fingerprint to Punch In';
        isInteractive = true;
        showScanBeam = true;
      } else {
        scannerColor = Colors.orange;
        statusText = 'Outside Geofence';
        isInteractive = false;
        showScanBeam = false;
      }
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
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
                    width: 10,
                    height: 10,
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
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scaleXY(begin: 0.75, end: 1.25, duration: 1100.ms)
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (!hasCheckOut && !isCheckedIn) ...[
                    Text(
                      isInRadius ? 'In Radius' : 'Outside',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isInRadius ? AppColors.success : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 20,
                      width: 32,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Switch(
                          value: isInRadius,
                          activeThumbColor: AppColors.success,
                          activeTrackColor: AppColors.success.withValues(alpha: 0.2),
                          inactiveThumbColor: Colors.orange,
                          inactiveTrackColor: Colors.orange.withValues(alpha: 0.2),
                          onChanged: (val) {
                            ref.read(geofenceSimulatedProvider.notifier).state = val;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(now),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
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
                  icon: RemixIcons.login_box_line,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _PunchTile(
                  label: 'Check Out Time',
                  time: hasCheckOut ? todayRecord!.checkOutLabel : '--:--',
                  icon: RemixIcons.logout_box_line,
                  color: hasCheckOut ? AppColors.primary : AppColors.textHint,
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
                    icon: RemixIcons.time_line,
                    color: AppColors.info,
                  ),
                ),
                if (todayRecord!.totalBreakDuration != Duration.zero || isOnBreak) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PunchTileHorizontal(
                      label: 'Break Time',
                      time: todayRecord!.breakDurationLabel,
                      icon: RemixIcons.cup_line,
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
              icon: RemixIcons.checkbox_circle_line,
              color: AppColors.success,
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: isInteractive 
                      ? () => _handlePunch(context, ref, isInRadius: isInRadius)
                      : (!isCheckedIn && !isInRadius)
                          ? () => _handlePunch(context, ref, isInRadius: false)
                          : null,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: scannerColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scannerColor.withValues(alpha: isInteractive ? 1.0 : 0.4),
                        width: 2.5,
                      ),
                      boxShadow: [
                        if (isInteractive)
                          BoxShadow(
                            color: scannerColor.withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isInteractive)
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scannerColor.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                          )
                              .animate(onPlay: (controller) => controller.repeat(reverse: true))
                              .scaleXY(begin: 1.0, end: 1.25, duration: 1200.ms)
                              .fadeIn(duration: 600.ms)
                              .fadeOut(delay: 600.ms, duration: 600.ms),
                        Icon(
                          RemixIcons.fingerprint_line,
                          color: scannerColor.withValues(alpha: isInteractive ? 1.0 : 0.4),
                          size: 70,
                        ),
                        if (showScanBeam)
                          Positioned(
                            top: 25,
                            child: Container(
                              width: 80,
                              height: 3,
                              decoration: BoxDecoration(
                                color: scannerColor.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: scannerColor,
                                    blurRadius: 8,
                                    spreadRadius: 1.5,
                                  ),
                                ],
                              ),
                            )
                                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                .moveY(begin: 0, end: 68, duration: 1500.ms, curve: Curves.easeInOut),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  statusText,
                  style: TextStyle(
                    color: scannerColor.withValues(alpha: isInteractive ? 1.0 : 0.6),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          if (isCheckedIn && !hasCheckOut) ...[
            const SizedBox(height: 18),
            Center(
              child: SizedBox(
                width: 160,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isOnBreak ? AppColors.success : AppColors.warning).withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOnBreak ? AppColors.success : AppColors.warning,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    icon: Icon(
                      isOnBreak ? RemixIcons.play_line : RemixIcons.cup_line,
                      size: 19,
                    ),
                    label: Text(isOnBreak ? 'End Break' : 'Take Break'),
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
            ),
          ],
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

  const _PunchTile({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            time,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
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
        color: bgColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
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
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(RemixIcons.calendar_event_line, color: color, size: 14),
              ),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'of $total days',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: ratio,
                      backgroundColor: color.withValues(alpha: 0.12),
                      color: color,
                      strokeWidth: 4.5,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '${(ratio * 100).round()}%',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
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
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
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
        borderRadius: BorderRadius.circular(22),
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
            child: Icon(RemixIcons.calendar_todo_line, color: statusColor, size: 22),
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
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${leave.daysCount} day(s) · ${DateFormat('dd MMM yyyy').format(leave.fromDate)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
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
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  announcement.categoryLabel,
                  style: TextStyle(
                    color: catColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM yyyy').format(announcement.date),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            announcement.description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(RemixIcons.user_line, size: 11, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                announcement.postedBy,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(RemixIcons.time_line, size: 11, color: AppColors.textHint),
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
