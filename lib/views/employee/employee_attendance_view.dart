import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/attendance_model.dart';
import '../../viewmodels/attendance_viewmodel.dart';

class EmployeeAttendanceView extends ConsumerWidget {
  const EmployeeAttendanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Attendance'),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Summary Cards ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Present',
                        count: state.presentCount,
                        color: AppColors.success,
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Absent',
                        count: state.absentCount,
                        color: AppColors.error,
                        icon: Icons.cancel_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Late',
                        count: state.lateCount,
                        color: AppColors.warning,
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Half Day',
                        count: state.halfDayCount,
                        color: AppColors.info,
                        icon: Icons.sunny_snowing,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ─── Today's Punch ─────────────────────────────────────────
                const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _TodayCard(state: state),

                const SizedBox(height: 20),

                // ─── History ───────────────────────────────────────────────
                const Text(
                  'Attendance History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                ...state.history
                    .where((a) => a.status != AttendanceStatus.weekend)
                    .take(20)
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AttendanceRow(record: a),
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: color),
          ),
          Text(
            label,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  final AttendanceState state;
  const _TodayCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(attendanceViewModelProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2)),
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
                  const Text(
                    'Check In',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    state.todayRecord?.checkInLabel ?? '--:--',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Check Out',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    state.todayRecord?.checkOutLabel ?? '--:--',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (state.todayRecord?.workingHoursLabel != null &&
              state.todayRecord!.workingHoursLabel != '--') ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timelapse_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Total: ${state.todayRecord!.workingHoursLabel}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (state.todayRecord?.checkOut == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(state.isCheckedIn
                    ? Icons.logout_rounded
                    : Icons.login_rounded),
                label: Text(state.isCheckedIn ? 'Check Out' : 'Check In'),
                onPressed: state.isCheckedIn ? vm.checkOut : vm.checkIn,
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Attendance Complete',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final AttendanceModel record;
  const _AttendanceRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final statusColor = _color(record.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE').format(record.date),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                Text(
                  DateFormat('dd MMM').format(record.date),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _TimeChip(label: 'IN', time: record.checkInLabel),
                const SizedBox(width: 8),
                _TimeChip(label: 'OUT', time: record.checkOutLabel),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              record.statusLabel,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _color(AttendanceStatus s) {
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

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;

  const _TimeChip({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                color: AppColors.textHint,
                fontWeight: FontWeight.w600)),
        Text(time,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
