import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/attendance/data/models/hr_attendance_record_model.dart';
import 'package:quickboom_hrm/features/attendance/presentation/providers/hr_attendance_viewmodel.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';

class HrAttendanceView extends ConsumerStatefulWidget {
  const HrAttendanceView({super.key});

  @override
  ConsumerState<HrAttendanceView> createState() => _HrAttendanceViewState();
}

class _HrAttendanceViewState extends ConsumerState<HrAttendanceView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Start ticking timer to update break/work elapsed duration every second in the UI
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hrAttendanceViewModelProvider);
    final vm = ref.read(hrAttendanceViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Attendance Monitor',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _downloadAttendanceReport(context),
            icon: Icon(RemixIcons.download_line, color: AppColors.primary),
            tooltip: 'Download Attendance Report',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: vm.updateSearch,
              decoration: InputDecoration(
                hintText: 'Search by employee name or code...',
                prefixIcon: Icon(RemixIcons.search_line),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(RemixIcons.close_line),
                        onPressed: vm.clearSearch,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // ─── Tab Bar ───────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TabBar(
                tabs: [
                  Tab(
                    icon: Icon(RemixIcons.calendar_line),
                    text: 'Today',
                  ),
                  Tab(
                    icon: Icon(RemixIcons.history_line),
                    text: 'History',
                  ),
                ],
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textHint,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
              ),
            ),
            
            // ─── Tab Views ───────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  // Today's Attendance Tab
                  RefreshIndicator(
                    onRefresh: vm.fetchTodayAttendance,
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Header Stats ───────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              _HeaderStatPill(
                    label: 'Present',
                    value: '${state.presentCount}',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _HeaderStatPill(
                    label: 'On Break',
                    value: '${state.activeOnBreakCount}',
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _HeaderStatPill(
                    label: 'Total Today',
                    value: '${state.records.length}',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '${state.filteredRecords.length} record(s) found',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // ─── Attendance List ─────────────────────────────────────────
            Expanded(
              child: state.isLoading && state.records.isEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ShimmerLoading(
                            height: 80,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      },
                    )
                  : state.filteredRecords.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      RemixIcons.checkbox_circle_line,
                                      size: 48,
                                      color: AppColors.textHint,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      state.searchQuery.isNotEmpty
                                          ? 'No matching records'
                                          : 'No attendance logs today',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          itemCount: state.filteredRecords.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            return _AttendanceCard(
                              record: state.filteredRecords[index],
                            );
                          },
                        ),
            ),
                  ],
                ),
                  ),

                  // History Tab
                  _AttendanceHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Download Method ───────────────────────────────────────────────────────

  Future<void> _downloadAttendanceReport(BuildContext context) async {
    // Store context reference to avoid async gaps
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Downloading attendance report...'),
          duration: Duration(seconds: 1),
        ),
      );

      await ref.read(hrAttendanceViewModelProvider.notifier).downloadAttendanceReport();
      
      // Show success message
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Attendance report downloaded successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to download report: ${error.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _HeaderStatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final HrAttendanceRecord record;

  const _AttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name & Status Badge
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    record.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
                      record.employeeName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${record.designation} · ${record.employeeCode}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: record.status),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Details grid (Check in / out, Break statuses)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoItem(
                icon: RemixIcons.login_box_line,
                label: 'PUNCH IN',
                value: record.checkIn != null
                    ? DateFormat('hh:mm a').format(record.checkIn!)
                    : '--:--',
              ),
              _InfoItem(
                icon: RemixIcons.logout_box_line,
                label: 'PUNCH OUT',
                value: record.checkOut != null
                    ? DateFormat('hh:mm a').format(record.checkOut!)
                    : '--:--',
              ),
              _InfoItem(
                icon: RemixIcons.time_line,
                label: 'NET WORK',
                value: record.workingHoursLabel,
              ),
            ],
          ),

          // Break status row (only show if on break or break time taken)
          if (record.isOnBreak || record.totalBreakSeconds > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: record.isOnBreak
                    ? AppColors.warning.withValues(alpha: 0.05)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: record.isOnBreak
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    RemixIcons.cup_line,
                    size: 14,
                    color: record.isOnBreak ? AppColors.warning : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    record.isOnBreak ? 'Active Break' : 'Total Break',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: record.isOnBreak ? AppColors.warning : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (record.isOnBreak) ...[
                    const _PulseAmberDot(),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    record.breakDurationLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: record.isOnBreak ? AppColors.warning : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label = status;

    switch (status.toUpperCase()) {
      case 'PRESENT':
        color = AppColors.success;
        bg = AppColors.successSurface;
        label = 'Present';
        break;
      case 'LATE':
        color = AppColors.warning;
        bg = AppColors.warningSurface;
        label = 'Late';
        break;
      case 'ABSENT':
        color = AppColors.error;
        bg = AppColors.errorSurface;
        label = 'Absent';
        break;
      case 'HALF_DAY':
        color = Colors.purple;
        bg = Colors.purple.withValues(alpha: 0.08);
        label = 'Half Day';
        break;
      case 'REMOTE':
        color = AppColors.info;
        bg = AppColors.infoSurface;
        label = 'Remote';
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
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PulseAmberDot extends StatefulWidget {
  const _PulseAmberDot();

  @override
  State<_PulseAmberDot> createState() => _PulseAmberDotState();
}

class _PulseAmberDotState extends State<_PulseAmberDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.warning,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _AttendanceHistoryTab extends ConsumerStatefulWidget {
  const _AttendanceHistoryTab();

  @override
  ConsumerState<_AttendanceHistoryTab> createState() => _AttendanceHistoryTabState();
}

class _AttendanceHistoryTabState extends ConsumerState<_AttendanceHistoryTab> {
  @override
  void initState() {
    super.initState();
    // Fetch last 30 days of attendance on init (delayed to avoid modifying provider during build)
    Future(() => _fetchHistory());
  }

  Future<void> _fetchHistory() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final from = thirtyDaysAgo.toIso8601String().split('T')[0];
    final to = now.toIso8601String().split('T')[0];
    await ref.read(hrAttendanceViewModelProvider.notifier).fetchHistoryAttendance(
      from: from,
      to: to,
      limit: 100,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hrAttendanceViewModelProvider);

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // ─── Month/Year Filter ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(RemixIcons.calendar_line, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance History',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Last 30 days',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── History Stats ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${state.presentCount}',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Present',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '0',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Absent',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '0',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Late',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── History List ─────────────────────────────────────────────
          Expanded(
            child: state.records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          RemixIcons.history_line,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No attendance history available',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Attendance records will appear here as employees punch in/out',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    itemCount: state.records.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final record = state.records[index];
                      return _AttendanceCard(record: record);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}