import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../models/leave_request_model.dart';
import '../../models/announcement_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/attendance_viewmodel.dart';
import '../../viewmodels/leave_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/employee_dashboard_viewmodel.dart';
import '../../viewmodels/holiday_viewmodel.dart';
import '../../widgets/shimmer_loading.dart';
import 'notifications_view.dart';
import 'employee_expenses_view.dart';
import 'employee_shift_view.dart';
import 'package:remixicon/remixicon.dart';
import '../../viewmodels/geofence_viewmodel.dart';


final geofenceProvider = FutureProvider<bool>((ref) async {
  await Future.delayed(Duration.zero);
  return ref.read(geofenceViewModelProvider.notifier).checkGeofenceStatus();
});


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
    final holidayState = ref.watch(holidayViewModelProvider);
    final announcements = dashboardState.announcements;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(attendanceViewModelProvider.notifier).fetchAttendanceData(),
            ref.read(leaveViewModelProvider.notifier).fetchLeaves(),
            ref.read(notificationViewModelProvider.notifier).fetchNotifications(),
            ref.read(employeeDashboardViewModelProvider.notifier).fetchDashboard(),
            ref.read(holidayViewModelProvider.notifier).fetchHolidays(),
          ]);
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                holidayState.isLoading
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            ShimmerLoading(
                              height: 60,
                              width: double.infinity,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            const SizedBox(height: 12),
                            ShimmerLoading(
                              height: 60,
                              width: double.infinity,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ],
                        ),
                      )
                    : holidayState.holidays.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Center(
                              child: Text(
                                'No upcoming holidays',
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 96,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: holidayState.holidays.length,
                              itemBuilder: (context, index) {
                                final item = holidayState.holidays[index];
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
                                          color: (item.isPublic ? AppColors.info : AppColors.primary)
                                              .withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          item.isPublic
                                              ? RemixIcons.global_line
                                              : RemixIcons.building_4_line,
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
                          ),

                const SizedBox(height: 24),

                // ─── Monthly Attendance Stats ──────────────────────────────
                _SectionTitle(title: 'This Month'),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final totalPresent = attendanceState.presentCount;
                    final totalAbsent = attendanceState.absentCount;
                    final totalLate = attendanceState.lateCount;
                    final totalDays = totalPresent + totalAbsent + totalLate;
                    final attendanceRate = totalDays > 0 ? (totalPresent / totalDays * 100).round() : 100;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.cardBorder, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMMM yyyy').format(DateTime.now()),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Monthly Health',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (attendanceRate >= 90 ? AppColors.success : (attendanceRate >= 75 ? AppColors.warning : AppColors.error)).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (attendanceRate >= 90 ? AppColors.success : (attendanceRate >= 75 ? AppColors.warning : AppColors.error)).withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      attendanceRate >= 90 
                                          ? RemixIcons.checkbox_circle_line 
                                          : (attendanceRate >= 75 ? RemixIcons.error_warning_line : RemixIcons.close_circle_line),
                                      size: 14,
                                      color: attendanceRate >= 90 ? AppColors.success : (attendanceRate >= 75 ? AppColors.warning : AppColors.error),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$attendanceRate% Attendance',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: attendanceRate >= 90 ? AppColors.success : (attendanceRate >= 75 ? AppColors.warning : AppColors.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (totalDays > 0) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 10,
                                width: double.infinity,
                                color: AppColors.background,
                                child: Row(
                                  children: [
                                    if (totalPresent > 0)
                                      Expanded(
                                        flex: totalPresent,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: AppColors.success,
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF4ADE80), AppColors.success],
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (totalLate > 0)
                                      Expanded(
                                        flex: totalLate,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: AppColors.warning,
                                            gradient: LinearGradient(
                                              colors: [Color(0xFFFBBF24), AppColors.warning],
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (totalAbsent > 0)
                                      Expanded(
                                        flex: totalAbsent,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: AppColors.error,
                                            gradient: LinearGradient(
                                              colors: [Color(0xFFF87171), AppColors.error],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 10,
                                width: double.infinity,
                                color: AppColors.divider,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _MonthlyDetailChip(
                                  label: 'Present',
                                  count: totalPresent,
                                  color: AppColors.success,
                                  icon: RemixIcons.checkbox_circle_line,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MonthlyDetailChip(
                                  label: 'Late',
                                  count: totalLate,
                                  color: AppColors.warning,
                                  icon: RemixIcons.time_line,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MonthlyDetailChip(
                                  label: 'Absent',
                                  count: totalAbsent,
                                  color: AppColors.error,
                                  icon: RemixIcons.close_circle_line,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _TodayPunchCard extends ConsumerStatefulWidget {
  final bool isCheckedIn;
  final dynamic todayRecord;

  const _TodayPunchCard({
    required this.isCheckedIn,
    required this.todayRecord,
  });

  @override
  ConsumerState<_TodayPunchCard> createState() => _TodayPunchCardState();
}

class _TodayPunchCardState extends ConsumerState<_TodayPunchCard> {
  Timer? _timer;
  bool _isPunching = false;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _TodayPunchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimerIfNeeded();
  }

  void _startTimerIfNeeded() {
    final needsTimer = widget.isCheckedIn || (widget.todayRecord?.isOnBreak ?? false);
    if (needsTimer) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handlePunch(BuildContext context) async {
    if (_isPunching) return;

    setState(() {
      _isPunching = true;
    });

    debugPrint('[PUNCH] Button click: ${widget.isCheckedIn ? "Punch Out" : "Punch In"}');

    try {
      Position? position;
      bool isWithinGeofence = false;

      // 1. Check and request location permission if needed
      debugPrint('[PUNCH] Checking location services and permissions');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in settings.');
      }

      debugPrint('[PUNCH] Location fetch start');
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      debugPrint('[PUNCH] Location fetch end: lat=${position.latitude}, lon=${position.longitude}');

      // 2. Validate geofence if punching in
      if (!widget.isCheckedIn) {
        debugPrint('[PUNCH] Geofence validation start');
        isWithinGeofence = await ref.read(geofenceViewModelProvider.notifier).checkGeofenceStatus(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        debugPrint('[PUNCH] Geofence validation end: isWithinGeofence = $isWithinGeofence');

        if (!isWithinGeofence) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(RemixIcons.error_warning_line, color: Colors.white),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Punch blocked: You are outside the office geofence.')),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          setState(() {
            _isPunching = false;
          });
          return;
        }
      }

      // 3. Trigger API call
      debugPrint('[PUNCH] API request start: ${widget.isCheckedIn ? "checkOut" : "checkIn"}');
      final success = widget.isCheckedIn
          ? await ref.read(attendanceViewModelProvider.notifier).checkOut(
              viaFingerprint: false,
              latitude: position.latitude,
              longitude: position.longitude,
            )
          : await ref.read(attendanceViewModelProvider.notifier).checkIn(
              viaFingerprint: false,
              latitude: position.latitude,
              longitude: position.longitude,
            );

      debugPrint('[PUNCH] API response: success = $success');

      if (success) {
        debugPrint('[PUNCH] Attendance state refresh');
        await ref.read(attendanceViewModelProvider.notifier).fetchAttendanceData();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(RemixIcons.checkbox_circle_line, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(widget.isCheckedIn ? 'Checked out successfully!' : 'Checked in successfully!')),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (error) {
      debugPrint('[PUNCH] Error during punch flow: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(RemixIcons.error_warning_line, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPunching = false;
        });
      }
    }
  }

  void _showDistanceCalculationSheet(BuildContext context, GeofenceState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final double? userLat = state.currentPosition?.latitude;
        final double? userLon = state.currentPosition?.longitude;
        final double? officeLat = state.officeLatitude;
        final double? officeLon = state.officeLongitude;
        final double? distance = state.distance;
        final int? maxRadius = state.maxRadius;
        final double? excessDistance = (distance != null && maxRadius != null) ? (distance - maxRadius) : null;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(RemixIcons.navigation_line, color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Distance Calculation Detail',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'HAVERSINE FORMULA USED',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'd = 2R × arcsin(√[sin²(Δlat/2) + cos(lat₁) × cos(lat₂) × sin²(Δlon/2)])',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This formula calculates the shortest great-circle distance between two GPS coordinates on the Earth\'s surface (modeled as a sphere of radius R = 6,371 km).',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'COORDINATES COMPARISON',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(RemixIcons.user_location_line, color: AppColors.primary, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'You',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('Lat: ${userLat?.toStringAsFixed(6) ?? "N/A"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Lon: ${userLon?.toStringAsFixed(6) ?? "N/A"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(RemixIcons.building_4_line, color: AppColors.success, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  state.nearestOffice ?? 'Office',
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('Lat: ${officeLat?.toStringAsFixed(6) ?? "N/A"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Lon: ${officeLon?.toStringAsFixed(6) ?? "N/A"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: excessDistance != null && excessDistance > 0 
                      ? Colors.orange.withValues(alpha: 0.08) 
                      : AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: excessDistance != null && excessDistance > 0 
                        ? Colors.orange.withValues(alpha: 0.2) 
                        : AppColors.success.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Calculated Distance:',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          distance != null ? '${distance.toStringAsFixed(1)} meters' : 'N/A',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Allowed Geofence Radius:',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12.5),
                        ),
                        Text(
                          maxRadius != null ? '$maxRadius meters' : 'N/A',
                          style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          excessDistance != null && excessDistance > 0 ? 'Outside Range by:' : 'Inside Geofence:',
                          style: TextStyle(
                            color: excessDistance != null && excessDistance > 0 ? Colors.orange[800] : AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          excessDistance != null
                              ? '${excessDistance.abs().toStringAsFixed(1)} meters'
                              : 'N/A',
                          style: TextStyle(
                            color: excessDistance != null && excessDistance > 0 ? Colors.orange[800] : AppColors.success,
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hasCheckIn = widget.todayRecord?.checkIn != null;
    final hasCheckOut = widget.todayRecord?.checkOut != null;
    final isOnBreak = widget.todayRecord?.isOnBreak ?? false;
    final geofenceState = ref.watch(geofenceViewModelProvider);
    ref.watch(geofenceProvider);
    final isInRadius = geofenceState.isWithinGeofence || !geofenceState.enableGeofence;

    bool isInteractive = !hasCheckOut && !_isPunching;

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
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: hasCheckOut 
                            ? AppColors.textSecondary 
                            : (widget.isCheckedIn 
                                ? (isOnBreak ? AppColors.warning : AppColors.success) 
                                : AppColors.warning),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!hasCheckOut)
                            BoxShadow(
                              color: widget.isCheckedIn 
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
                    Expanded(
                      child: Text(
                        hasCheckOut 
                            ? 'Shift Completed' 
                            : (widget.isCheckedIn 
                                ? (isOnBreak ? 'Currently on Break' : 'Currently Active') 
                                : 'Not Checked In'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!hasCheckOut && !widget.isCheckedIn) ...[
                      Flexible(
                        child: GestureDetector(
                          onTap: () => _showDistanceCalculationSheet(context, geofenceState),
                          child: Text(
                            isInRadius 
                                ? 'Location Verified' 
                                : (geofenceState.distance != null 
                                    ? 'Outside Area (${geofenceState.distance!.toStringAsFixed(0)}m / ${(geofenceState.distance! / 1000).toStringAsFixed(2)} km)'
                                    : 'Location Required'),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isInRadius ? AppColors.success : Colors.orange,
                              decoration: isInRadius ? null : TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: geofenceState.isLoading ? null : () => ref.invalidate(geofenceProvider),
                        onLongPress: () => _showDistanceCalculationSheet(context, geofenceState),
                        child: geofenceState.isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                ),
                              )
                            : Icon(
                                isInRadius ? RemixIcons.map_pin_user_fill : RemixIcons.refresh_line, 
                                size: 16, 
                                color: isInRadius ? AppColors.success : Colors.orange,
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
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _PunchTile(
                  label: 'Check In Time',
                  time: hasCheckIn ? widget.todayRecord!.checkInLabel : '--:--',
                  icon: RemixIcons.login_box_line,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _PunchTile(
                  label: 'Check Out Time',
                  time: hasCheckOut ? widget.todayRecord!.checkOutLabel : '--:--',
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
                    time: widget.todayRecord!.workingHoursLabel,
                    icon: RemixIcons.time_line,
                    color: AppColors.info,
                  ),
                ),
                if (widget.todayRecord!.totalBreakDuration != Duration.zero || isOnBreak) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PunchTileHorizontal(
                      label: 'Break Time',
                      time: widget.todayRecord!.breakDurationLabel,
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
              time: widget.todayRecord!.workingHoursLabel,
              icon: RemixIcons.checkbox_circle_line,
              color: AppColors.success,
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: _SimplifiedPunchButton(
              isInteractive: isInteractive,
              isCheckedIn: widget.isCheckedIn,
              isInRadius: isInRadius,
              distance: geofenceState.distance,
              isLoading: _isPunching,
              onPunchTriggered: () {
                _handlePunch(context);
              },
            ),
          ),
          if (widget.isCheckedIn && !hasCheckOut) ...[
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

class _PremiumPunchButton extends StatefulWidget {
  final bool isInteractive;
  final bool isCheckedIn;
  final bool isInRadius;
  final Color scannerColor;
  final String statusText;
  final VoidCallback onPunchTriggered;

  const _PremiumPunchButton({
    required this.isInteractive,
    required this.isCheckedIn,
    required this.isInRadius,
    required this.scannerColor,
    required this.statusText,
    required this.onPunchTriggered,
  });

  @override
  State<_PremiumPunchButton> createState() => _PremiumPunchButtonState();
}

class _PremiumPunchButtonState extends State<_PremiumPunchButton> with TickerProviderStateMixin {
  late AnimationController _holdController;
  late AnimationController _laserController;
  late AnimationController _rippleController;
  bool _isPressing = false;
  DateTime? _lastHapticTime;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _holdController.addListener(() {
      if (_holdController.value > 0.0) {
        final now = DateTime.now();
        if (_lastHapticTime == null || now.difference(_lastHapticTime!) > const Duration(milliseconds: 120)) {
          _lastHapticTime = now;
          HapticFeedback.selectionClick();
        }
      }
    });

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onHoldComplete();
      }
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    _laserController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onHoldComplete() {
    _holdController.reset();
    setState(() {
      _isPressing = false;
    });
    HapticFeedback.heavyImpact();
    widget.onPunchTriggered();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isInteractive) return;
    setState(() {
      _isPressing = true;
    });
    _holdController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _cancelHold();
  }

  void _handleTapCancel() {
    _cancelHold();
  }

  void _cancelHold() {
    if (_isPressing) {
      setState(() {
        _isPressing = false;
      });
      if (_holdController.value < 1.0) {
        _holdController.reverse(from: _holdController.value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerColor = widget.scannerColor;
    final isInteractive = widget.isInteractive;
    final rippleColor = scannerColor.withValues(alpha: _isPressing ? 0.15 : 0.08);

    return Column(
      children: [
        GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: (!isInteractive && !widget.isCheckedIn && !widget.isInRadius)
              ? widget.onPunchTriggered
              : null,
          child: AnimatedScale(
            scale: _isPressing ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Concentric Ripples (Breathe animation)
                  ...List.generate(3, (index) {
                    final delay = index * 0.33;
                    return AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        double progress = (_rippleController.value + delay) % 1.0;
                        double size = 120 + (progress * 50);
                        double opacity = (1.0 - progress) * (isInteractive ? 0.6 : 0.2);
                        return Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(
                              color: rippleColor.withValues(alpha: opacity),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  // 2. Main Outer Container
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: scannerColor.withValues(alpha: _isPressing ? 0.3 : 0.12),
                          blurRadius: _isPressing ? 25 : 16,
                          spreadRadius: _isPressing ? 4 : 0,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 10,
                          spreadRadius: -4,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                  ),

                  // 3. Inner Metallic / Gradient surface
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.surface,
                          scannerColor.withValues(alpha: 0.05),
                          scannerColor.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: scannerColor.withValues(alpha: isInteractive ? 0.3 : 0.15),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // 4. Circular Progress Indicator (holds the tap duration)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child: AnimatedBuilder(
                          animation: _holdController,
                          builder: (context, child) {
                            return CircularProgressIndicator(
                              value: _holdController.value,
                              strokeWidth: 4.5,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _holdController.value > 0.0 ? scannerColor : Colors.transparent,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // 5. Biometric scanner area (Icon, Beam, Scanner Glow)
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: ClipOval(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Holographic Glow inside
                          AnimatedBuilder(
                            animation: _holdController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scannerColor.withValues(
                                    alpha: 0.02 + (_holdController.value * 0.12),
                                  ),
                                ),
                              );
                            },
                          ),

                          // The central Icon
                          AnimatedBuilder(
                            animation: _holdController,
                            builder: (context, child) {
                              double scale = 1.0 + (_holdController.value * 0.1);
                              return Transform.scale(
                                scale: scale,
                                child: Icon(
                                  widget.isCheckedIn ? RemixIcons.fingerprint_line : RemixIcons.fingerprint_fill,
                                  color: scannerColor.withValues(
                                    alpha: isInteractive ? 0.95 : 0.45,
                                  ),
                                  size: 52,
                                ),
                              );
                            },
                          ),

                          // Laser sweep beam (only active when pressing/interactive)
                          if (isInteractive && _isPressing)
                            AnimatedBuilder(
                              animation: _laserController,
                              builder: (context, child) {
                                double topPosition = 15 + (_laserController.value * 70); // Sweeps 15 to 85 px
                                return Positioned(
                                  top: topPosition,
                                  left: 15,
                                  right: 15,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: scannerColor,
                                      borderRadius: BorderRadius.circular(1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: scannerColor.withValues(alpha: 0.8),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.statusText,
          style: TextStyle(
            color: scannerColor.withValues(alpha: isInteractive ? 1.0 : 0.6),
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _SimplifiedPunchButton extends StatelessWidget {
  final bool isInteractive;
  final bool isCheckedIn;
  final bool isInRadius;
  final double? distance;
  final bool isLoading;
  final VoidCallback onPunchTriggered;

  const _SimplifiedPunchButton({
    required this.isInteractive,
    required this.isCheckedIn,
    required this.isInRadius,
    this.distance,
    required this.isLoading,
    required this.onPunchTriggered,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = isCheckedIn 
        ? Colors.red 
        : (isInteractive ? AppColors.primary : Colors.grey[400]);

    return Column(
      children: [
        // Main Punch Button
        GestureDetector(
          onTap: (isInteractive && !isLoading) ? onPunchTriggered : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: buttonColor,
              boxShadow: [
                BoxShadow(
                  color: buttonColor!.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow effect
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: buttonColor.withValues(alpha: 0.1),
                  ),
                ),
                // Inner circle with icon or loading indicator
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : Icon(
                          isCheckedIn ? RemixIcons.logout_box_line : RemixIcons.login_box_line,
                          color: Colors.white,
                          size: 40,
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Button Label
        Text(
          isLoading
              ? 'PROCESSING...'
              : (isCheckedIn ? 'PUNCH OUT' : 'PUNCH IN'),
          style: TextStyle(
            color: buttonColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        // Status message
        if (!isInteractive && !isCheckedIn && !isInRadius && !isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              distance != null
                  ? 'Outside office area (${distance!.toStringAsFixed(0)}m / ${(distance! / 1000).toStringAsFixed(2)} km)'
                  : 'Outside office area',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
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


class _MonthlyDetailChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _MonthlyDetailChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
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
