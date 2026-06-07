import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../viewmodels/attendance_viewmodel.dart';
import '../../widgets/custom_loading_widget.dart';
import '../../widgets/custom_error_widget.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends ConsumerState<AttendanceHistoryScreen> {
  String _selectedMonth = '';
  final List<String> _months = [];

  @override
  void initState() {
    super.initState();
    _initializeMonths();
    _selectedMonth = _getCurrentMonth();
    // Load attendance data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceViewModelProvider.notifier).fetchAttendanceData();
    });
  }

  void _initializeMonths() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      _months.add(DateFormat('MMM yyyy').format(month));
    }
  }

  String _getCurrentMonth() {
    return DateFormat('MMM yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceViewModelProvider);
    final attendanceViewModel = ref.read(attendanceViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadReport(attendanceViewModel),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => attendanceViewModel.fetchAttendanceData(),
        child: Column(
          children: [
            _buildMonthSelector(),
            _buildStatisticsCard(attendanceState),
            _buildAttendanceList(attendanceState),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Month',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _months.length,
              itemBuilder: (context, index) {
                final month = _months[index];
                final isSelected = month == _selectedMonth;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(month),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedMonth = month;
                        });
                        _filterAttendanceByMonth();
                      }
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue.shade700,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(AttendanceState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Present',
                      state.presentCount.toString(),
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Absent',
                      state.absentCount.toString(),
                      Colors.red,
                      Icons.cancel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Late',
                      state.lateCount.toString(),
                      Colors.orange,
                      Icons.access_time,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Half Day',
                      state.halfDayCount.toString(),
                      Colors.purple,
                      Icons.timelapse,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(AttendanceState state) {
    if (state.isLoading && state.history.isEmpty) {
      return const Expanded(
        child: Center(
          child: CustomLoadingWidget(message: 'Loading attendance history...'),
        ),
      );
    }

    final filteredHistory = _filterAttendanceRecords(state.history);

    if (filteredHistory.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No attendance records found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try selecting a different month',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredHistory.length,
        itemBuilder: (context, index) {
          final record = filteredHistory[index];
          return _buildAttendanceItem(record, index);
        },
      ),
    );
  }

  Widget _buildAttendanceItem(dynamic record, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(record.date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(record.status),
                ],
              ),
              const SizedBox(height: 12),
              if (record.checkIn != null) ...[
                _buildTimeRow('Check In', record.checkIn!, Icons.login, Colors.green),
                const SizedBox(height: 8),
              ],
              if (record.checkOut != null) ...[
                _buildTimeRow('Check Out', record.checkOut!, Icons.logout, Colors.red),
                const SizedBox(height: 8),
              ],
              if (record.isOnBreak) ...[
                _buildTimeRow('Break Start', record.breakStartTime!, Icons.free_breakfast, Colors.orange),
                const SizedBox(height: 8),
              ],
              if (record.totalBreakDuration.inMinutes > 0) ...[
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Total Break: ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${record.totalBreakDuration.inHours}:${(record.totalBreakDuration.inMinutes % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              if (record.officeLat != null && record.officeLon != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Location: ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Text(
                        'Office Area',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime time, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          DateFormat('hh:mm a').format(time),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(dynamic status) {
    Color color;
    IconData icon;
    String label;

    switch (status.toString().toUpperCase()) {
      case 'PRESENT':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Present';
        break;
      case 'ABSENT':
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Absent';
        break;
      case 'LATE':
        color = Colors.orange;
        icon = Icons.access_time;
        label = 'Late';
        break;
      case 'HALF_DAY':
        color = Colors.purple;
        icon = Icons.timelapse;
        label = 'Half Day';
        break;
      case 'WEEKEND':
        color = Colors.grey;
        icon = Icons.weekend;
        label = 'Weekend';
        break;
      case 'HOLIDAY':
        color = Colors.blue;
        icon = Icons.beach_access;
        label = 'Holiday';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterAttendanceRecords(List<dynamic> history) {
    if (_selectedMonth == _getCurrentMonth()) {
      return history; // Show all records for current month
    }

    // Filter by selected month
    return history.where((record) {
      final recordMonth = DateFormat('MMM yyyy').format(record.date);
      return recordMonth == _selectedMonth;
    }).toList();
  }

  void _filterAttendanceByMonth() {
    // This will trigger a rebuild with the filtered data
    setState(() {});
  }

  void _downloadReport(dynamic attendanceViewModel) async {
    // Convert selected month to format expected by API (e.g., "2024-01")
    final monthFormat = DateFormat('MMM yyyy').parse(_selectedMonth);
    final monthString = '${monthFormat.year}-${monthFormat.month.toString().padLeft(2, '0')}';
    
    await attendanceViewModel.downloadMyAttendanceReport(month: monthString);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance report downloaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
