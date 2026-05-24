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
import '../../core/services/biometric_service.dart';
import 'notifications_view.dart';

class EmployeeDashboardView extends ConsumerWidget {
  const EmployeeDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).currentUser;
    if (user == null) return const Scaffold();
    final attendanceState = ref.watch(attendanceViewModelProvider);
    final leaveState = ref.watch(leaveViewModelProvider);
    final notifState = ref.watch(notificationViewModelProvider);
    final now = DateTime.now();
    final greeting = _greeting();

    final announcements = _mockAnnouncements();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Hero Header ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
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
                                Text(
                                  '$greeting,',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  user.name.split(' ').first,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy').format(now),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Avatar with glowing aura
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 2.5),
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
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
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
              'QuickBoom HRM',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
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
                      top: 12,
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
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Today Punch Card ─────────────────────────────────────
                _TodayPunchCard(
                  isCheckedIn: attendanceState.isCheckedIn,
                  todayRecord: attendanceState.todayRecord,
                  onCheckIn: (viaFingerprint) =>
                      ref.read(attendanceViewModelProvider.notifier).checkIn(viaFingerprint: viaFingerprint),
                  onCheckOut: (viaFingerprint) =>
                      ref.read(attendanceViewModelProvider.notifier).checkOut(viaFingerprint: viaFingerprint),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // ─── Leave Balance ────────────────────────────────────────
                _SectionTitle(title: 'Leave Balance'),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width < 380 ? 2 : (width > 600 ? 4 : 3);
                    final itemWidth = (width - (columns - 1) * 10) / columns;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
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

                const SizedBox(height: 20),

                // ─── This Month Attendance ─────────────────────────────────
                _SectionTitle(title: 'This Month'),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width < 380 ? 2 : (width > 600 ? 4 : 3);
                    final itemWidth = (width - (columns - 1) * 10) / columns;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
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

                const SizedBox(height: 20),

                // ─── Recent Leave Requests ─────────────────────────────────
                if (leaveState.myLeaves.isNotEmpty) ...[
                  _SectionTitle(title: 'Recent Leave Requests'),
                  const SizedBox(height: 10),
                  ...leaveState.myLeaves.take(2).map(
                        (leave) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LeaveRequestTile(leave: leave),
                        ),
                      ),
                ],

                const SizedBox(height: 20),

                // ─── Announcements ─────────────────────────────────────────
                _SectionTitle(title: 'Announcements'),
                const SizedBox(height: 10),
                ...announcements.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AnnouncementTile(announcement: a),
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  List<AnnouncementModel> _mockAnnouncements() {
    final now = DateTime.now();
    return [
      AnnouncementModel(
        id: 'A1',
        title: '🎉 Company Picnic Next Week',
        description:
            'Join us for the annual company picnic on Saturday. Venue: City Park, 10 AM onwards.',
        date: now.subtract(const Duration(days: 1)),
        postedBy: 'Sarah Johnson',
        category: AnnouncementCategory.event,
      ),
      AnnouncementModel(
        id: 'A2',
        title: '📅 Public Holiday Notice',
        description:
            'Office will remain closed on account of Eid al-Adha. Enjoy the long weekend!',
        date: now.subtract(const Duration(days: 3)),
        postedBy: 'Sarah Johnson',
        category: AnnouncementCategory.holiday,
      ),
      AnnouncementModel(
        id: 'A3',
        title: '📋 Updated WFH Policy',
        description:
            'New work-from-home policy effective June 1st. Please review the updated guidelines.',
        date: now.subtract(const Duration(days: 5)),
        postedBy: 'Sarah Johnson',
        category: AnnouncementCategory.policy,
      ),
    ];
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
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _TodayPunchCard extends StatelessWidget {
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
              backgroundColor: AppColors.error,
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
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hasCheckIn = todayRecord?.checkIn != null;
    final hasCheckOut = todayRecord?.checkOut != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: hasCheckOut 
                          ? AppColors.textSecondary 
                          : (isCheckedIn ? AppColors.success : AppColors.warning),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scaleXY(begin: 0.7, end: 1.3, duration: 1000.ms)
                      .fadeIn(duration: 1000.ms),
                  const SizedBox(width: 8),
                  Text(
                    hasCheckOut 
                        ? 'Shift Completed' 
                        : (isCheckedIn ? 'Currently Active' : 'Not Checked In'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
                  DateFormat('dd MMM').format(now),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _PunchTile(
                  label: 'Check In',
                  time: hasCheckIn ? todayRecord!.checkInLabel : '--:--',
                  icon: Icons.login_rounded,
                  color: AppColors.success,
                  isFingerprint: todayRecord?.isFingerprintCheckIn ?? false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PunchTile(
                  label: 'Check Out',
                  time: hasCheckOut ? todayRecord!.checkOutLabel : '--:--',
                  icon: Icons.logout_rounded,
                  color: hasCheckOut ? AppColors.primary : AppColors.textHint,
                  isFingerprint: todayRecord?.isFingerprintCheckOut ?? false,
                ),
              ),
            ],
          ),
          if (hasCheckIn && !hasCheckOut) ...[
            const SizedBox(height: 12),
            _PunchTileHorizontal(
              label: 'Working Hours',
              time: todayRecord!.workingHoursLabel,
              icon: Icons.timelapse_rounded,
              color: AppColors.info,
            ),
          ] else if (hasCheckIn && hasCheckOut) ...[
            const SizedBox(height: 12),
            _PunchTileHorizontal(
              label: 'Total Working Hours',
              time: todayRecord!.workingHoursLabel,
              icon: Icons.verified_rounded,
              color: AppColors.success,
            ),
          ],
          const SizedBox(height: 20),
          if (!hasCheckOut)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCheckedIn ? AppColors.error : AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                icon: const Icon(Icons.fingerprint_rounded, size: 20),
                label: Text(isCheckedIn ? 'Check Out (Fingerprint)' : 'Check In (Fingerprint)'),
                onPressed: () => _handlePunch(context),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Perfect! Day completed.',
                    style: TextStyle(
                        color: AppColors.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
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
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
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

  const _PunchTileHorizontal({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            time,
            style: TextStyle(
              color: color,
              fontSize: 15,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 3)),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              Icon(Icons.event_available_rounded, color: color.withValues(alpha: 0.7), size: 14),
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
                          fontSize: 20, fontWeight: FontWeight.w800, color: color),
                    ),
                    Text(
                      'of $total days',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: CircularProgressIndicator(
                      value: ratio,
                      backgroundColor: color.withValues(alpha: 0.12),
                      color: color,
                      strokeWidth: 3.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.event_note_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leave.typeLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${leave.daysCount} day(s) · ${DateFormat('dd MMM yyyy').format(leave.fromDate)}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
            color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  announcement.categoryLabel,
                  style: TextStyle(
                      color: catColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM').format(announcement.date),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            announcement.title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            announcement.description,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
