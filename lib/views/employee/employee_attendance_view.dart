import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/distance_service.dart';
import '../../models/attendance_model.dart';
import '../../viewmodels/attendance_viewmodel.dart';
import '../../widgets/shimmer_loading.dart';

class EmployeeAttendanceView extends ConsumerWidget {
  const EmployeeAttendanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceViewModelProvider);

    // Calculate dynamic attendance rate
    final totalDays = state.presentCount + state.absentCount + state.lateCount + state.halfDayCount;
    final attendanceRate = totalDays > 0 ? (((state.presentCount + state.halfDayCount + state.lateCount * 0.8) / totalDays) * 100).round() : 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'My Attendance',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _downloadAttendanceReport(ref, context),
            icon: Icon(RemixIcons.download_line, color: AppColors.primary),
            tooltip: 'Download Attendance Report',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Analytics Stats Header Dashboard ──────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('MMMM yyyy').format(DateTime.now()),
                                style: TextStyle(
                                  color: AppColors.primaryLight.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Attendance Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  RemixIcons.award_line,
                                  size: 14,
                                  color: AppColors.primaryLight,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$attendanceRate% Rating',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
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
                            child: _DashboardStatChip(
                              label: 'Present',
                              count: state.presentCount,
                              color: AppColors.success,
                              icon: RemixIcons.checkbox_circle_line,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DashboardStatChip(
                              label: 'Absent',
                              count: state.absentCount,
                              color: AppColors.error,
                              icon: RemixIcons.close_circle_line,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DashboardStatChip(
                              label: 'Late',
                              count: state.lateCount,
                              color: AppColors.warning,
                              icon: RemixIcons.time_line,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DashboardStatChip(
                              label: 'Half Day',
                              count: state.halfDayCount,
                              color: AppColors.info,
                              icon: RemixIcons.sun_line,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Today's Session Card ──────────────────────────────────
                const Text(
                  'Today\'s Session',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                _TodayCard(state: state),

                const SizedBox(height: 28),

                // ─── Timeline History ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Attendance History Feed',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (state.isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: ShimmerLoading(
                          width: 16,
                          height: 16,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () => ref.read(attendanceViewModelProvider.notifier).fetchAttendanceData(),
                        icon: Icon(RemixIcons.refresh_line, color: AppColors.primary),
                        tooltip: 'Refresh Attendance',
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                if (state.history.isEmpty && !state.isLoading)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(RemixIcons.calendar_line, size: 48, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text(
                          'No attendance records found',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start punching in to see your attendance history',
                          style: TextStyle(
                            color: AppColors.textHint.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...state.history
                      .where((a) => a.status != AttendanceStatus.weekend)
                      .take(20)
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (entry) {
                          final index = entry.key;
                          final record = entry.value;
                          final isLast = index == state.history.where((a) => a.status != AttendanceStatus.weekend).take(20).length - 1;
                          return _TimelineAttendanceRow(record: record, isLast: isLast);
                        },
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

class _DashboardStatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _DashboardStatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends ConsumerStatefulWidget {
  final AttendanceState state;
  const _TodayCard({required this.state});

  @override
  ConsumerState<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends ConsumerState<_TodayCard> {
  Timer? _timer;
  Map<String, dynamic>? _distanceData;
  bool _isLoadingDistance = false;
  bool _isPunching = false;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
    _loadDistance();
  }

  @override
  void didUpdateWidget(covariant _TodayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimerIfNeeded();
  }

  void _startTimerIfNeeded() {
    final hasCheckIn = widget.state.todayRecord?.checkIn != null;
    final hasCheckOut = widget.state.todayRecord?.checkOut != null;
    if (hasCheckIn && !hasCheckOut) {
      _timer ??= Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _loadDistance() async {
    setState(() => _isLoadingDistance = true);
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final result = await DistanceService.getCurrentDistance(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() => _distanceData = result);
    } catch (e) {
      // Silently fail if location is not available
    }
    setState(() => _isLoadingDistance = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCheckIn = widget.state.todayRecord?.checkIn != null;
    final hasCheckOut = widget.state.todayRecord?.checkOut != null;
    final isOnBreak = widget.state.todayRecord?.isOnBreak ?? false;

    // Pulse colors for active session
    final pulseColor = isOnBreak ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row of logs (Check In & Check Out)
          Row(
            children: [
              Expanded(
                child: _LiveTimeDisplay(
                  label: 'Check In',
                  time: widget.state.todayRecord?.checkInLabel ?? '--:--',
                  icon: RemixIcons.login_box_line,
                  color: AppColors.success,
                ),
              ),
              Container(
                width: 1.5,
                height: 44,
                color: AppColors.divider,
              ),
              Expanded(
                child: _LiveTimeDisplay(
                  label: 'Check Out',
                  time: widget.state.todayRecord?.checkOutLabel ?? '--:--',
                  icon: RemixIcons.logout_box_line,
                  color: hasCheckOut ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ],
          ),

          if (hasCheckIn) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Pulse Live dot for Active Session
                if (!hasCheckOut)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: pulseColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: pulseColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                Icon(
                  RemixIcons.time_line,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  hasCheckOut
                      ? 'Total Working Time: ${widget.state.todayRecord!.workingHoursLabel}'
                      : 'Active Session: ${widget.state.todayRecord!.workingHoursLabel}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Action Buttons
          if (!hasCheckOut)
            Column(
              children: [
                Row(
                  children: [
                    if (hasCheckIn) ...[
                      Expanded(
                        child: _AttendanceActionButton(
                          label: isOnBreak ? 'End Break' : 'Take Break',
                          icon: isOnBreak ? RemixIcons.play_line : RemixIcons.cup_line,
                          color: AppColors.warning,
                          onTap: () {
                            if (isOnBreak) {
                              ref.read(attendanceViewModelProvider.notifier).endBreak();
                            } else {
                              ref.read(attendanceViewModelProvider.notifier).startBreak();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _SimplifiedAttendancePunchButton(
                        isCheckedIn: hasCheckIn,
                        isLoading: _isPunching,
                        onTap: () async {
                          setState(() => _isPunching = true);
                          try {
                            if (hasCheckIn) {
                              await ref.read(attendanceViewModelProvider.notifier).checkOut();
                            } else {
                              await ref.read(attendanceViewModelProvider.notifier).checkIn();
                            }
                          } catch (error) {
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
                              setState(() => _isPunching = false);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Distance Display
                if (_distanceData != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_distanceData!['isWithinRadius'] == true
                          ? AppColors.success
                          : AppColors.warning).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_distanceData!['isWithinRadius'] == true
                            ? AppColors.success
                            : AppColors.warning).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _distanceData!['isWithinRadius'] == true
                              ? RemixIcons.checkbox_circle_line
                              : RemixIcons.map_pin_line,
                          size: 14,
                          color: _distanceData!['isWithinRadius'] == true
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_distanceData!['distance']?.toStringAsFixed(2) ?? '0.0'} km from office',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _distanceData!['isWithinRadius'] == true
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_isLoadingDistance)
                  const SizedBox(
                    height: 24,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.textHint),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(RemixIcons.checkbox_circle_fill, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Shift Completed Successfully',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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

class _LiveTimeDisplay extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;

  const _LiveTimeDisplay({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: time == '--:--' ? AppColors.textHint : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _AttendanceActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AttendanceActionButton({
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimplifiedAttendancePunchButton extends StatelessWidget {
  final bool isCheckedIn;
  final bool isLoading;
  final VoidCallback onTap;

  const _SimplifiedAttendancePunchButton({
    required this.isCheckedIn,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isCheckedIn 
              ? Colors.red 
              : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isCheckedIn 
                  ? Colors.red 
                  : AppColors.primary).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else
              Icon(
                isCheckedIn ? RemixIcons.logout_box_line : RemixIcons.login_box_line,
                color: Colors.white,
                size: 18,
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isLoading ? 'Processing...' : (isCheckedIn ? 'PUNCH OUT' : 'PUNCH IN'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineAttendanceRow extends StatelessWidget {
  final AttendanceModel record;
  final bool isLast;

  const _TimelineAttendanceRow({
    required this.record,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(record.status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical Timeline Dot & Line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Main timeline row card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Date indicator block
                    SizedBox(
                      width: 54,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEE').format(record.date),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM').format(record.date),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Punch IN/OUT times
                    Expanded(
                      child: Row(
                        children: [
                          _TimelineTimeChip(label: 'IN', time: record.checkInLabel),
                          const SizedBox(width: 16),
                          _TimelineTimeChip(label: 'OUT', time: record.checkOutLabel),
                        ],
                      ),
                    ),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            record.statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (record.status == AttendanceStatus.late && record.isLateMarkedAsHalfDay) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '½ Day',
                                style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.halfDay:
        return AppColors.info;
      case AttendanceStatus.holiday:
        return AppColors.primary;
      default:
        return AppColors.textHint;
    }
  }
}

class _TimelineTimeChip extends StatelessWidget {
  final String label;
  final String time;

  const _TimelineTimeChip({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textHint,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: time == '--:--' ? AppColors.textHint : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Download Method ───────────────────────────────────────────────────────

Future<void> _downloadAttendanceReport(WidgetRef ref, BuildContext context) async {
  try {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading attendance report...'),
        duration: Duration(seconds: 1),
      ),
    );

    await ref.read(attendanceViewModelProvider.notifier).downloadMyAttendanceReport();
    
    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance report downloaded successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download report: ${error.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
