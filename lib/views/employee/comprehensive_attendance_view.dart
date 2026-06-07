import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/comprehensive_attendance_service.dart';

class ComprehensiveAttendanceView extends ConsumerStatefulWidget {
  const ComprehensiveAttendanceView({super.key});

  @override
  ConsumerState<ComprehensiveAttendanceView> createState() => _ComprehensiveAttendanceViewState();
}

class _ComprehensiveAttendanceViewState extends ConsumerState<ComprehensiveAttendanceView> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  ComprehensiveReportSummary? _summary;
  List<AttendanceRecord> _records = [];
  List<LocationTracking> _locationTracking = [];
  List<BreakDetail> _breakDetails = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ComprehensiveAttendanceService.getComprehensiveReport(
        month: _selectedMonth,
        year: _selectedYear,
      );
      setState(() {
        _summary = ComprehensiveReportSummary.fromJson(data['summary']);
        _records = (data['attendanceRecords'] as List? ?? [])
            .map((item) => AttendanceRecord.fromJson(item))
            .toList();
        _locationTracking = (data['locationTracking'] as List? ?? [])
            .map((item) => LocationTracking.fromJson(item))
            .toList();
        _breakDetails = (data['breakDetails'] as List? ?? [])
            .map((item) => BreakDetail.fromJson(item))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading comprehensive report: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Report'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectMonth,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodHeader(),
                    const SizedBox(height: 16),
                    if (_summary != null) _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildAttendanceTypeCard(),
                    const SizedBox(height: 16),
                    _buildLocationTrackingCard(),
                    const SizedBox(height: 16),
                    _buildBreakDetailsCard(),
                    const SizedBox(height: 16),
                    _buildAttendanceRecordsCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPeriodHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth - 1)),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Days: ${_summary?.totalDays ?? 0}',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _summaryItem('Total Work Hours', '${_summary!.totalWorkHours.toStringAsFixed(1)}h', Icons.work, Colors.blue),
                _summaryItem('Total Break Time', '${_summary!.totalBreakTime.toStringAsFixed(0)}m', Icons.coffee, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _summaryItem('Location Tracking', '${_summary!.locationTrackingPercentage.toStringAsFixed(0)}%', Icons.location_on, Colors.green),
                _summaryItem('Tracking Days', '${_summary!.locationTrackingDays}', Icons.calendar_month, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTypeCard() {
    if (_summary == null) return const SizedBox();
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance Types', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _typeItem('Full Days', _summary!.fullDays, Colors.green, Icons.check_circle),
                _typeItem('Half Days', _summary!.halfDays, Colors.orange, Icons.timelapse),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _typeItem('Absent', _summary!.absentDays, Colors.red, Icons.cancel),
                _typeItem('Late', _summary!.lateDays, Colors.purple, Icons.access_time),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeItem(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTrackingCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Location Tracking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${_locationTracking.length} records', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 12),
            if (_locationTracking.isEmpty)
              const Text('No location tracking data available', style: TextStyle(color: Colors.grey))
            else
              ..._locationTracking.take(5).map((loc) => _locationItem(loc)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _locationItem(LocationTracking loc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(loc.locationStatus, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakDetailsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Break Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${_breakDetails.length} breaks', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 12),
            if (_breakDetails.isEmpty)
              const Text('No break data available', style: TextStyle(color: Colors.grey))
            else
              ..._breakDetails.take(5).map((breakDetail) => _breakItem(breakDetail)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _breakItem(BreakDetail breakDetail) {
    Color color;
    switch (breakDetail.breakType) {
      case 'LONG_BREAK': color = Colors.red; break;
      case 'STANDARD_BREAK': color = Colors.orange; break;
      case 'SHORT_BREAK': color = Colors.green; break;
      default: color = Colors.grey;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.coffee, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(breakDetail.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${breakDetail.breakMinutes} min', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(breakDetail.breakType, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecordsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Attendance Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${_records.length} records', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 12),
            if (_records.isEmpty)
              const Text('No attendance records available', style: TextStyle(color: Colors.grey))
            else
              ..._records.take(10).map((record) => _recordItem(record)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _recordItem(AttendanceRecord record) {
    Color typeColor;
    switch (record.attendanceType) {
      case 'FULL_DAY': typeColor = Colors.green; break;
      case 'HALF_DAY': typeColor = Colors.orange; break;
      case 'ABSENT': typeColor = Colors.red; break;
      case 'LATE': typeColor = Colors.purple; break;
      default: typeColor = Colors.grey;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(record.date, style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(record.attendanceType, style: TextStyle(fontSize: 12, color: typeColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (record.checkIn != null) _timeBadge('In', record.checkIn, Colors.green),
              if (record.checkOut != null) _timeBadge('Out', record.checkOut, Colors.red),
              const Spacer(),
              Text('${record.workHours.toStringAsFixed(1)}h work', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              if (record.breakMinutes > 0) Text(' | ${record.breakMinutes}m break', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          if (record.hasLocation)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue, size: 14),
                  const SizedBox(width: 4),
                  Text('Location tracked', style: TextStyle(fontSize: 12, color: Colors.blue)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeBadge(String label, String? time, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: ${time != null ? DateFormat('HH:mm').format(DateTime.parse(time)) : '--'}',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth - 1),
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (selected != null) {
      setState(() {
        _selectedMonth = selected.month;
        _selectedYear = selected.year;
      });
      _loadData();
    }
  }
}
