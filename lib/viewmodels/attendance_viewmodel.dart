import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';
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
      debugPrint('🔄 Fetching attendance data...');
      
      // Use the new mobile API endpoint for today's attendance
      final todayRes = await ApiService.get(AppUrl.attendanceToday);
      final todayData = jsonDecode(todayRes.body);
      debugPrint('📊 Today\'s attendance response: ${todayRes.body}');
      
      final rawToday = todayData['data'];
      final todayRecord = rawToday != null ? _parseRecord(rawToday) : null;
      
      // Use the new mobile API endpoint for history
      final historyRes = await ApiService.get(AppUrl.attendanceHistory);
      final historyData = jsonDecode(historyRes.body);
      debugPrint('📚 History response: ${historyRes.body}');
      
      final List rawHistory = historyData['data']?['attendances'] ?? [];
      final history = rawHistory.map((h) => _parseRecord(h)).toList();

      state = AttendanceState(
        todayRecord: todayRecord,
        isCheckedIn: todayRecord != null && todayRecord.checkIn != null && todayRecord.checkOut == null,
        history: history,
        isLoading: false,
      );
      
      debugPrint('✅ Attendance data updated successfully');
    } catch (e) {
      debugPrint('❌ Error fetching attendance data: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> checkIn({bool viaFingerprint = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final currentTime = DateTime.now();
      debugPrint('🕒 LOCAL TIME BEFORE API CALL: ${currentTime.toIso8601String()}');
      debugPrint('🌍 TIMEZONE: ${currentTime.timeZoneName} (${currentTime.timeZoneOffset})');

      // Fetch real GPS coordinates
      final position = await _getCurrentPosition();
      debugPrint('📍 GPS Position: lat=${position?.latitude}, lon=${position?.longitude}');

      final response = await ApiService.post(AppUrl.attendancePunchIn, {
        'latitude': position?.latitude ?? 0.0,
        'longitude': position?.longitude ?? 0.0,
        'notes': viaFingerprint ? 'Punched in via Fingerprint' : 'Punched in via mobile app',
        'clientTimestamp': currentTime.toUtc().toIso8601String(),
        'timezone': currentTime.timeZoneName,
        'isFingerprint': viaFingerprint,
      });

      debugPrint('✅ Punch-in API response: ${response.body}');
      await fetchAttendanceData();
      return true;
    } catch (e) {
      debugPrint('❌ Punch-in error: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> checkOut({bool viaFingerprint = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final currentTime = DateTime.now();
      debugPrint('🕒 LOCAL TIME BEFORE API CALL: ${currentTime.toIso8601String()}');
      debugPrint('🌍 TIMEZONE: ${currentTime.timeZoneName} (${currentTime.timeZoneOffset})');

      // Fetch real GPS coordinates
      final position = await _getCurrentPosition();
      debugPrint('📍 GPS Position: lat=${position?.latitude}, lon=${position?.longitude}');

      final response = await ApiService.post(AppUrl.attendancePunchOut, {
        'latitude': position?.latitude ?? 0.0,
        'longitude': position?.longitude ?? 0.0,
        'notes': viaFingerprint ? 'Punched out via Fingerprint' : 'Punched out via mobile app',
        'clientTimestamp': currentTime.toUtc().toIso8601String(),
        'timezone': currentTime.timeZoneName,
        'isFingerprint': viaFingerprint,
      });

      debugPrint('✅ Punch-out API response: ${response.body}');
      await fetchAttendanceData();
      return true;
    } catch (e) {
      debugPrint('❌ Punch-out error: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Returns the device's current GPS position, requesting permission if needed.
  /// Returns null if location is unavailable or permission is denied.
  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission permanently denied.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Could not get GPS position: $e');
      return null;
    }
  }

  Future<void> startBreak() async {
    state = state.copyWith(isLoading: true);
    try {
      debugPrint('☕ Starting break...');
      
      // Use the new mobile API endpoint for starting break
      final response = await ApiService.post(AppUrl.attendanceBreakStart, {});
      debugPrint('✅ Break start response: ${response.body}');
      
      await fetchAttendanceData();
    } catch (e) {
      debugPrint('❌ Start break error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> endBreak() async {
    state = state.copyWith(isLoading: true);
    try {
      debugPrint('🔄 Ending break...');
      
      // Use the new mobile API endpoint for ending break
      final response = await ApiService.post(AppUrl.attendanceBreakEnd, {});
      debugPrint('✅ Break end response: ${response.body}');
      
      await fetchAttendanceData();
    } catch (e) {
      debugPrint('❌ End break error: $e');
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
      checkIn: data['checkIn'] != null ? DateTime.tryParse(data['checkIn'].toString())?.toLocal() : null,
      checkOut: data['checkOut'] != null ? DateTime.tryParse(data['checkOut'].toString())?.toLocal() : null,
      isOnBreak: data['isOnBreak'] ?? false,
      breakStartTime: data['breakStartTime'] != null ? DateTime.tryParse(data['breakStartTime'].toString())?.toLocal() : null,
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
