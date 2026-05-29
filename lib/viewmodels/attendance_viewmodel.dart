import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../models/attendance_model.dart';

class AttendanceState {
  final List<AttendanceModel> history;
  final AttendanceModel? todayRecord;
  final bool isCheckedIn;
  final bool isLoading;

  const AttendanceState({
    this.history = const [],
    this.todayRecord,
    this.isCheckedIn = false,
    this.isLoading = false,
  });

  AttendanceState copyWith({
    List<AttendanceModel>? history,
    AttendanceModel? todayRecord,
    bool? isCheckedIn,
    bool? isLoading,
    bool clearToday = false,
  }) {
    return AttendanceState(
      history: history ?? this.history,
      todayRecord: clearToday ? null : (todayRecord ?? this.todayRecord),
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get presentCount => history
      .where(
        (a) =>
            a.status == AttendanceStatus.present ||
            a.status == AttendanceStatus.late,
      )
      .length;

  int get absentCount =>
      history.where((a) => a.status == AttendanceStatus.absent).length;

  int get lateCount =>
      history.where((a) => a.status == AttendanceStatus.late).length;

  int get halfDayCount =>
      history.where((a) => a.status == AttendanceStatus.halfDay).length;
}

// ─── Attendance ViewModel ────────────────────────────────────────────────────

class AttendanceViewModel extends StateNotifier<AttendanceState> {
  AttendanceViewModel() : super(const AttendanceState()) {
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    state = state.copyWith(isLoading: true);
    try {
      final todayRes = await ApiService.get('/api/employee/attendance/today');
      final todayData = jsonDecode(todayRes.body);
      final rawToday = todayData['todayRecord'];
      final todayRecord = rawToday != null ? _parseRecord(rawToday) : null;

      final historyRes = await ApiService.get('/api/employee/attendance/history');
      final historyData = jsonDecode(historyRes.body);
      final List rawHistory = historyData['history'] ?? [];
      final history = rawHistory.map((h) => _parseRecord(h)).toList();

      state = AttendanceState(
        todayRecord: todayRecord,
        isCheckedIn: todayRecord != null && todayRecord.checkIn != null && todayRecord.checkOut == null,
        history: history,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> checkIn({bool viaFingerprint = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      await ApiService.post('/api/employee/attendance/check-in', {
        'latitude': '19.0760',
        'longitude': '72.8777',
        'viaFingerprint': viaFingerprint,
      });
      await fetchAttendanceData();
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> checkOut({bool viaFingerprint = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      await ApiService.post('/api/employee/attendance/check-out', {
        'viaFingerprint': viaFingerprint,
      });
      await fetchAttendanceData();
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> startBreak() async {
    state = state.copyWith(isLoading: true);
    try {
      await ApiService.post('/api/employee/attendance/break/start', {});
      await fetchAttendanceData();
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> endBreak() async {
    state = state.copyWith(isLoading: true);
    try {
      await ApiService.post('/api/employee/attendance/break/end', {});
      await fetchAttendanceData();
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  AttendanceModel _parseRecord(Map<String, dynamic> data) {
    final rawDate = data['date'];
    DateTime parsedDate;
    if (rawDate is String && rawDate.contains('-')) {
      final parts = rawDate.split('-');
      parsedDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } else {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }

    return AttendanceModel(
      id: data['id'].toString(),
      employeeId: data['employeeId'].toString(),
      date: parsedDate,
      status: _parseStatus(data['status']?.toString() ?? 'ABSENT'),
      checkIn: data['checkIn'] != null ? DateTime.tryParse(data['checkIn'].toString()) : null,
      checkOut: data['checkOut'] != null ? DateTime.tryParse(data['checkOut'].toString()) : null,
      isFingerprintCheckIn: data['isFingerprintCheckIn'] ?? false,
      isFingerprintCheckOut: data['isFingerprintCheckOut'] ?? false,
      isOnBreak: data['isOnBreak'] ?? false,
      breakStartTime: data['breakStartTime'] != null ? DateTime.tryParse(data['breakStartTime'].toString()) : null,
      totalBreakDuration: Duration(seconds: data['totalBreakSeconds'] ?? 0),
    );
  }

  AttendanceStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return AttendanceStatus.present;
      case 'ABSENT':
        return AttendanceStatus.absent;
      case 'LATE':
        return AttendanceStatus.late;
      case 'HALF_DAY':
        return AttendanceStatus.halfDay;
      case 'WEEKEND':
        return AttendanceStatus.weekend;
      case 'HOLIDAY':
        return AttendanceStatus.holiday;
      default:
        return AttendanceStatus.absent;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final attendanceViewModelProvider =
    StateNotifierProvider<AttendanceViewModel, AttendanceState>((ref) {
  return AttendanceViewModel();
});
