import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/attendance_viewmodel.dart';

class AttendanceHistoryView extends ConsumerStatefulWidget {
  const AttendanceHistoryView({super.key});

  @override
  ConsumerState<AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends ConsumerState<AttendanceHistoryView> {
  String _selectedMonth = '';

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat('MMM yyyy').format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceViewModelProvider.notifier).fetchAttendanceData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceViewModelProvider);
    final attendanceViewModel = ref.read(attendanceViewModelProvider.notifier);
    final history = _filterByMonth(attendanceState.history);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => attendanceViewModel.fetchAttendanceData(),
        child: Column(
          children: [
            _buildStatisticsCard(attendanceState),
            Expanded(
              child: history.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: history.length,
                      itemBuilder: (context, index) => _buildAttendanceItem(history[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No attendance records found', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
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
              const Text('Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _statItem('Present', '${state.presentCount}', Colors.green, Icons.check_circle)),
                  Expanded(child: _statItem('Absent', '${state.absentCount}', Colors.red, Icons.cancel)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _statItem('Late', '${state.lateCount}', Colors.orange, Icons.access_time)),
                  Expanded(child: _statItem('Half Day', '${state.halfDayCount}', Colors.purple, Icons.timelapse)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(dynamic record) {
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
                  Text(DateFormat('EEEE, MMM dd, yyyy').format(record.date),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  _statusChip(record.status),
                ],
              ),
              const SizedBox(height: 12),
              if (record.checkIn != null)
                _timeRow('Check In', record.checkIn, Icons.login, Colors.green),
              if (record.checkOut != null)
                _timeRow('Check Out', record.checkOut, Icons.logout, Colors.red),
              if (record.totalBreakDuration.inMinutes > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text('Total Break: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('${record.totalBreakDuration.inHours}:${(record.totalBreakDuration.inMinutes % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeRow(String label, DateTime time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(DateFormat('hh:mm a').format(time), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statusChip(dynamic status) {
    Color color;
    String label;
    switch (status.toString().toUpperCase()) {
      case 'PRESENT': color = Colors.green; label = 'Present'; break;
      case 'ABSENT': color = Colors.red; label = 'Absent'; break;
      case 'LATE': color = Colors.orange; label = 'Late'; break;
      case 'HALF_DAY': color = Colors.purple; label = 'Half Day'; break;
      case 'WEEKEND': color = Colors.grey; label = 'Weekend'; break;
      case 'HOLIDAY': color = Colors.blue; label = 'Holiday'; break;
      default: color = Colors.grey; label = 'Unknown';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  List<dynamic> _filterByMonth(List<dynamic> history) {
    return history.where((record) {
      return DateFormat('MMM yyyy').format(record.date) == _selectedMonth;
    }).toList();
  }
}
