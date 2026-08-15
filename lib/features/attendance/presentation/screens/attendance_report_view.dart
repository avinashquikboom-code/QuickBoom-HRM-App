import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';
import 'package:quickboom_hrm/features/attendance/data/models/hr_attendance_record_model.dart';
import 'package:quickboom_hrm/features/attendance/presentation/providers/hr_attendance_viewmodel.dart';

enum AttendanceReportPeriod { today, week, month, custom }

class AttendanceReportView extends ConsumerStatefulWidget {
  const AttendanceReportView({super.key});

  @override
  ConsumerState<AttendanceReportView> createState() => _AttendanceReportViewState();
}

class _AttendanceReportViewState extends ConsumerState<AttendanceReportView> {
  AttendanceReportPeriod _selectedPeriod = AttendanceReportPeriod.month;
  DateTimeRange? _customDateRange;
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final vm = ref.read(hrAttendanceViewModelProvider.notifier);
    
    String? from;
    String? to;

    switch (_selectedPeriod) {
      case AttendanceReportPeriod.today:
        final today = DateTime.now().toIso8601String().split('T')[0];
        from = today;
        to = today;
        break;
      case AttendanceReportPeriod.week:
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        from = startOfWeek.toIso8601String().split('T')[0];
        to = now.toIso8601String().split('T')[0];
        break;
      case AttendanceReportPeriod.month:
        final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
        from = firstDay.toIso8601String().split('T')[0];
        to = lastDay.toIso8601String().split('T')[0];
        break;
      case AttendanceReportPeriod.custom:
        if (_customDateRange != null) {
          from = _customDateRange!.start.toIso8601String().split('T')[0];
          to = _customDateRange!.end.toIso8601String().split('T')[0];
        }
        break;
    }

    await vm.fetchHistoryAttendance(
      from: from,
      to: to,
      limit: 500,
    );
  }

  List<HrAttendanceRecord> _filterRecords(List<HrAttendanceRecord> records) {
    return records.where((r) {
      // Status filter
      if (_selectedStatus != 'ALL') {
        if (r.status.toUpperCase() != _selectedStatus.toUpperCase()) {
          return false;
        }
      }

      // Search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchName = r.employeeName.toLowerCase().contains(q);
        final matchCode = r.employeeCode.toLowerCase().contains(q);
        final matchStore = (r.officeName ?? '').toLowerCase().contains(q);
        final matchDept = (r.department ?? '').toLowerCase().contains(q);
        if (!matchName && !matchCode && !matchStore && !matchDept) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = AttendanceReportPeriod.custom;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hrAttendanceViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppColors.updateTheme(isDark);

    final filteredRecords = _filterRecords(state.records);

    // Calculate Summary KPI Stats
    final totalCount = filteredRecords.length;
    final presentCount = filteredRecords.where((r) => r.status.toUpperCase() == 'PRESENT' || r.status.toUpperCase() == 'HOLIDAY_WORKED' || r.status.toUpperCase() == 'WEEKLY_OFF_WORKED').length;
    final lateCount = filteredRecords.where((r) => r.status.toUpperCase() == 'LATE').length;
    final halfDayCount = filteredRecords.where((r) => r.status.toUpperCase() == 'HALF_DAY').length;
    final absentCount = filteredRecords.where((r) => r.status.toUpperCase() == 'ABSENT').length;
    final leaveCount = filteredRecords.where((r) => r.status.toUpperCase() == 'LEAVE' || r.status.toUpperCase() == 'PAID_LEAVE' || r.status.toUpperCase() == 'UNPAID_LEAVE').length;
    final holidayCount = filteredRecords.where((r) => r.status.toUpperCase() == 'HOLIDAY' || r.status.toUpperCase() == 'WEEKLY_OFF' || r.status.toUpperCase() == 'WEEKEND' || r.status.toUpperCase() == 'SUNDAY').length;

    // Calculate Average Working Hours
    double totalWorkSec = 0;
    int checkedOutRecords = 0;
    for (final r in filteredRecords) {
      if (r.checkIn != null && r.checkOut != null) {
        final diff = r.checkOut!.difference(r.checkIn!).inSeconds - r.totalBreakSeconds;
        if (diff > 0) {
          totalWorkSec += diff;
          checkedOutRecords++;
        }
      }
    }
    final avgWorkHoursStr = checkedOutRecords > 0
        ? '${(totalWorkSec / checkedOutRecords / 3600).toStringAsFixed(1)}h'
        : '0h';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Report',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Comprehensive Mobile Log & Summary',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Downloading Attendance Report PDF...')),
                );
                await ref
                    .read(hrAttendanceViewModelProvider.notifier)
                    .downloadAttendanceReport(
                      month: DateFormat('yyyy-MM').format(_selectedMonth),
                    );
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to download PDF: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            icon: Icon(RemixIcons.download_2_line, color: AppColors.primary),
            tooltip: 'Export PDF Report',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── SEARCH & FILTER SECTION ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by Name, Employee Code, or Store...',
                        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                        prefixIcon: Icon(RemixIcons.search_2_line, color: AppColors.textHint, size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(RemixIcons.close_circle_fill, color: AppColors.textHint, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Period Selector Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Today',
                            isSelected: _selectedPeriod == AttendanceReportPeriod.today,
                            onTap: () {
                              setState(() => _selectedPeriod = AttendanceReportPeriod.today);
                              _fetchData();
                            },
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'This Week',
                            isSelected: _selectedPeriod == AttendanceReportPeriod.week,
                            onTap: () {
                              setState(() => _selectedPeriod = AttendanceReportPeriod.week);
                              _fetchData();
                            },
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'Month (${DateFormat('MMM').format(_selectedMonth)})',
                            isSelected: _selectedPeriod == AttendanceReportPeriod.month,
                            onTap: () {
                              setState(() => _selectedPeriod = AttendanceReportPeriod.month);
                              _fetchData();
                            },
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: _selectedPeriod == AttendanceReportPeriod.custom && _customDateRange != null
                                ? '${DateFormat('dd/MM').format(_customDateRange!.start)} - ${DateFormat('dd/MM').format(_customDateRange!.end)}'
                                : 'Custom Date',
                            icon: RemixIcons.calendar_event_line,
                            isSelected: _selectedPeriod == AttendanceReportPeriod.custom,
                            onTap: _selectCustomDateRange,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Status Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatusFilterPill(
                            label: 'All ($totalCount)',
                            isSelected: _selectedStatus == 'ALL',
                            color: AppColors.primary,
                            onTap: () => setState(() => _selectedStatus = 'ALL'),
                          ),
                          const SizedBox(width: 6),
                          _StatusFilterPill(
                            label: 'Present ($presentCount)',
                            isSelected: _selectedStatus == 'PRESENT',
                            color: const Color(0xFF059669),
                            onTap: () => setState(() => _selectedStatus = 'PRESENT'),
                          ),
                          const SizedBox(width: 6),
                          _StatusFilterPill(
                            label: 'Late ($lateCount)',
                            isSelected: _selectedStatus == 'LATE',
                            color: const Color(0xFFD97706),
                            onTap: () => setState(() => _selectedStatus = 'LATE'),
                          ),
                          const SizedBox(width: 6),
                          _StatusFilterPill(
                            label: 'Half Day ($halfDayCount)',
                            isSelected: _selectedStatus == 'HALF_DAY',
                            color: const Color(0xFF4F46E5),
                            onTap: () => setState(() => _selectedStatus = 'HALF_DAY'),
                          ),
                          const SizedBox(width: 6),
                          _StatusFilterPill(
                            label: 'Absent ($absentCount)',
                            isSelected: _selectedStatus == 'ABSENT',
                            color: const Color(0xFFDC2626),
                            onTap: () => setState(() => _selectedStatus = 'ABSENT'),
                          ),
                          const SizedBox(width: 6),
                          _StatusFilterPill(
                            label: 'Leave ($leaveCount)',
                            isSelected: _selectedStatus == 'LEAVE',
                            color: const Color(0xFF2563EB),
                            onTap: () => setState(() => _selectedStatus = 'LEAVE'),
                          ),
                          const SizedBox(width: 6),
                          _StatusFilterPill(
                            label: 'Holiday ($holidayCount)',
                            isSelected: _selectedStatus == 'HOLIDAY',
                            color: const Color(0xFF7C3AED),
                            onTap: () => setState(() => _selectedStatus = 'HOLIDAY'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── KPI SUMMARY CARD ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Report Summary Overview',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Avg Work: $avgWorkHoursStr / day',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryMetricBox(
                              label: 'Present',
                              value: '$presentCount',
                              color: const Color(0xFF059669),
                              icon: RemixIcons.checkbox_circle_line,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryMetricBox(
                              label: 'Late',
                              value: '$lateCount',
                              color: const Color(0xFFD97706),
                              icon: RemixIcons.time_line,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryMetricBox(
                              label: 'Half Day',
                              value: '$halfDayCount',
                              color: const Color(0xFF4F46E5),
                              icon: RemixIcons.subtract_line,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryMetricBox(
                              label: 'Absent',
                              value: '$absentCount',
                              color: const Color(0xFFDC2626),
                              icon: RemixIcons.close_circle_line,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── RECORD COUNT HEADER ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ATTENDANCE RECORDS (${filteredRecords.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (state.isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),

            // ─── RECORD LIST / LOADING / EMPTY STATE ─────────────────────────
            if (state.isLoading && state.records.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShimmerLoading(
                        height: 160,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    childCount: 4,
                  ),
                ),
              )
            else if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            RemixIcons.lock_2_line,
                            size: 48,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Attendance Report Restricted',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchData,
                          icon: const Icon(RemixIcons.refresh_line, size: 16),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (filteredRecords.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            RemixIcons.file_search_line,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No attendance records found.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try adjusting your search or filter selection.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AttendanceReportCard(
                          record: filteredRecords[index],
                        ),
                      );
                    },
                    childCount: filteredRecords.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── ATTENDANCE CARD COMPONENT ──────────────────────────────────────────────────

class _AttendanceReportCard extends StatelessWidget {
  final HrAttendanceRecord record;

  const _AttendanceReportCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDate(record.date);
    final checkInStr = record.checkIn != null
        ? DateFormat('hh:mm a').format(record.checkIn!)
        : '--:--';
    final checkOutStr = record.checkOut != null
        ? DateFormat('hh:mm a').format(record.checkOut!)
        : '--:--';

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER: Avatar, Employee Info & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      record.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Employee Name & Designation (Wraps naturally)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.employeeName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${record.employeeCode}  •  ${record.designation}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge
                _StatusChip(status: record.status),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.6)),
            const SizedBox(height: 12),

            // ─── METADATA: Date, Store & Department
            Row(
              children: [
                Icon(RemixIcons.calendar_line, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (record.shiftName != null && record.shiftName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Shift: ${record.shiftName}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Store & Department Chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (record.officeName != null && record.officeName!.isNotEmpty)
                  _MetaTagPill(
                    icon: RemixIcons.store_2_line,
                    text: record.officeName!,
                    color: AppColors.textSecondary,
                  ),
                if (record.department != null && record.department!.isNotEmpty)
                  _MetaTagPill(
                    icon: RemixIcons.building_4_line,
                    text: record.department!,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ─── TIME & HOURS GRID
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TimeBox(
                      label: 'CHECK IN',
                      timeStr: checkInStr,
                      icon: RemixIcons.login_circle_line,
                      iconColor: const Color(0xFF059669),
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppColors.divider),
                  Expanded(
                    child: _TimeBox(
                      label: 'CHECK OUT',
                      timeStr: checkOutStr,
                      icon: RemixIcons.logout_circle_line,
                      iconColor: const Color(0xFFDC2626),
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppColors.divider),
                  Expanded(
                    child: _TimeBox(
                      label: 'BREAK',
                      timeStr: record.breakDurationLabel,
                      icon: RemixIcons.cup_line,
                      iconColor: const Color(0xFFD97706),
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppColors.divider),
                  Expanded(
                    child: _TimeBox(
                      label: 'WORK HOURS',
                      timeStr: record.workingHoursLabel,
                      icon: RemixIcons.time_fill,
                      iconColor: AppColors.primary,
                      isHighlighted: true,
                    ),
                  ),
                ],
              ),
            ),

            // ─── LATE / EARLY EXIT / REMARKS BANNER
            if (record.lateByMinutes > 0 || record.earlyExitMinutes > 0 || (record.notes != null && record.notes!.isNotEmpty)) ...[
              const SizedBox(height: 10),
              if (record.lateByMinutes > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(RemixIcons.error_warning_line, size: 12, color: const Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text(
                        'Late by ${record.lateByMinutes}m',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              if (record.notes != null && record.notes!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(RemixIcons.sticky_note_line, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record.notes!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy (EEEE)').format(d);
    } catch (_) {
      return dateStr;
    }
  }
}

// ─── HELPER COMPONENTS ─────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusFilterPill({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SummaryMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryMetricBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label = status;

    switch (status.toUpperCase()) {
      case 'PRESENT':
        color = const Color(0xFF059669);
        bg = const Color(0xFFECFDF5);
        label = 'Present';
        break;
      case 'LATE':
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFFFBEB);
        label = 'Late';
        break;
      case 'ABSENT':
        color = const Color(0xFFDC2626);
        bg = const Color(0xFFFEF2F2);
        label = 'Absent';
        break;
      case 'HALF_DAY':
        color = const Color(0xFF4F46E5);
        bg = const Color(0xFFEEF2FF);
        label = 'Half Day';
        break;
      case 'LEAVE':
      case 'PAID_LEAVE':
        color = const Color(0xFF2563EB);
        bg = const Color(0xFFDBEAFE);
        label = 'Paid Leave';
        break;
      case 'UNPAID_LEAVE':
        color = const Color(0xFFEA580C);
        bg = const Color(0xFFFFEDD5);
        label = 'Unpaid Leave';
        break;
      case 'HOLIDAY':
        color = const Color(0xFF7C3AED);
        bg = const Color(0xFFF5F3FF);
        label = 'Holiday';
        break;
      case 'HOLIDAY_WORKED':
        color = const Color(0xFF0D9488);
        bg = const Color(0xFFCCFBF1);
        label = 'Holiday Worked';
        break;
      case 'WEEKLY_OFF_WORKED':
        color = const Color(0xFF0284C7);
        bg = const Color(0xFFE0F2FE);
        label = 'Weekly Off Worked';
        break;
      case 'WEEKEND':
      case 'WEEK_OFF':
      case 'WEEKLY_OFF':
      case 'SUNDAY':
        color = const Color(0xFF64748B);
        bg = const Color(0xFFF1F5F9);
        label = 'Weekly Off';
        break;
      default:
        color = AppColors.textSecondary;
        bg = AppColors.background;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaTagPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaTagPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String timeStr;
  final IconData icon;
  final Color iconColor;
  final bool isHighlighted;

  const _TimeBox({
    required this.label,
    required this.timeStr,
    required this.icon,
    required this.iconColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 10, color: iconColor),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHint,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            timeStr,
            style: TextStyle(
              fontSize: isHighlighted ? 12.5 : 11.5,
              fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
              color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
