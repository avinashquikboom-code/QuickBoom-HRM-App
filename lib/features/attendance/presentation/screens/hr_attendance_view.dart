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
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch attendance for current month on init
    Future(() => _fetchMonthlyAttendance());
  }

  Future<void> _fetchMonthlyAttendance() async {
    setState(() => _isLoading = true);
    
    try {
      final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      final from = firstDayOfMonth.toIso8601String().split('T')[0];
      final to = lastDayOfMonth.toIso8601String().split('T')[0];
      
      await ref.read(hrAttendanceViewModelProvider.notifier).fetchHistoryAttendance(
        from: from,
        to: to,
        limit: 200, // Increased limit for full month data
      );
    } catch (e) {
      debugPrint('Error fetching monthly attendance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int direction) {
    setState(() {
      if (direction > 0) {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      }
    });
    _fetchMonthlyAttendance();
  }

  List<Map<String, dynamic>> _generateDayWiseData(List<HrAttendanceRecord> records) {
    final Map<String, List<HrAttendanceRecord>> dayWiseMap = {};
    
    // Group records by date
    for (final record in records) {
      final dateKey = record.date;
      if (!dayWiseMap.containsKey(dateKey)) {
        dayWiseMap[dateKey] = [];
      }
      dayWiseMap[dateKey]!.add(record);
    }
    
    // Generate all days of the month
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    final List<Map<String, dynamic>> dayWiseData = [];
    
    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final dateKey = currentDate.toIso8601String().split('T')[0];
      final dayRecords = dayWiseMap[dateKey] ?? [];
      
      // Calculate stats for the day
      int present = 0;
      int absent = 0;
      int late = 0;
      int halfDay = 0;
      int remote = 0;
      
      for (final record in dayRecords) {
        switch (record.status.toUpperCase()) {
          case 'PRESENT':
            present++;
            break;
          case 'ABSENT':
            absent++;
            break;
          case 'LATE':
            late++;
            break;
          case 'HALF_DAY':
            halfDay++;
            break;
          case 'REMOTE':
            remote++;
            break;
        }
      }
      
      dayWiseData.add({
        'day': day,
        'date': dateKey,
        'dayName': DateFormat('EEE').format(currentDate),
        'present': present,
        'absent': absent,
        'late': late,
        'halfDay': halfDay,
        'remote': remote,
        'total': dayRecords.length,
        'records': dayRecords,
      });
    }
    
    return dayWiseData;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hrAttendanceViewModelProvider);
    final dayWiseData = _generateDayWiseData(state.records);

    return RefreshIndicator(
      onRefresh: _fetchMonthlyAttendance,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // ─── Month Selector ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: Icon(RemixIcons.arrow_left_s_line, color: AppColors.primary),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedMonth),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${dayWiseData.where((d) => d['total'] > 0).length} days with records',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: Icon(RemixIcons.arrow_right_s_line, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),

          // ─── Monthly Stats ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Present',
                    value: dayWiseData.fold(0, (sum, day) => sum + (day['present'] as int)).toString(),
                    color: AppColors.success,
                    icon: RemixIcons.check_line,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Absent',
                    value: dayWiseData.fold(0, (sum, day) => sum + (day['absent'] as int)).toString(),
                    color: AppColors.error,
                    icon: RemixIcons.close_line,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Late',
                    value: dayWiseData.fold(0, (sum, day) => sum + (day['late'] as int)).toString(),
                    color: AppColors.warning,
                    icon: RemixIcons.time_line,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Half Day',
                    value: dayWiseData.fold(0, (sum, day) => sum + (day['halfDay'] as int)).toString(),
                    color: Colors.purple,
                    icon: RemixIcons.subtract_line,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── Day-wise Attendance Table ─────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              border: Border(
                                bottom: BorderSide(color: AppColors.cardBorder),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Present',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Absent',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.error,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Late',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warning,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Half',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.purple,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Table Rows
                          ...dayWiseData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final dayData = entry.value;
                            final isEven = index % 2 == 0;
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isEven ? Colors.transparent : AppColors.background,
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.cardBorder.withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${dayData['day']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          dayData['dayName'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${dayData['present']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: dayData['present'] > 0 ? AppColors.success : AppColors.textHint,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${dayData['absent']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: dayData['absent'] > 0 ? AppColors.error : AppColors.textHint,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${dayData['late']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: dayData['late'] > 0 ? AppColors.warning : AppColors.textHint,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${dayData['halfDay']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: dayData['halfDay'] > 0 ? Colors.purple : AppColors.textHint,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (dayData['records'].isNotEmpty) {
                                          _showDayDetails(context, dayData);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: dayData['total'] > 0 
                                              ? AppColors.primary.withValues(alpha: 0.1)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${dayData['total']}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: dayData['total'] > 0 ? AppColors.primary : AppColors.textHint,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showDayDetails(BuildContext context, Map<String, dynamic> dayData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(RemixIcons.calendar_line, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance for ${dayData['day']} ${dayData['dayName']}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(RemixIcons.close_line),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: (dayData['records'] as List<HrAttendanceRecord>).length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final record = (dayData['records'] as List<HrAttendanceRecord>)[index];
                    return _AttendanceCard(record: record);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}