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
      
      // Use the new mobile API endpoint for today's attendance with clientTimestamp and timezone query params
      final currentTime = DateTime.now();
      final todayRes = await ApiService.get(
        '${AppUrl.attendanceToday}?clientTimestamp=${Uri.encodeComponent(currentTime.toUtc().toIso8601String())}&timezone=${Uri.encodeComponent(currentTime.timeZoneName)}',
      );
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

      if (position == null && !kDebugMode) {
        throw Exception('Location is required. Please enable GPS to punch in.');
      }

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
      
      // Handle specific geofence errors
      String errorMessage = e.toString();
      if (errorMessage.contains('OUTSIDE_GEOFENCE')) {
        throw Exception('You are outside the office geofence. Please move closer to the office location to punch in.');
      } else if (errorMessage.contains('MISSING_LOCATION')) {
        throw Exception('Location services are required. Please enable GPS and try again.');
      } else if (errorMessage.contains('ALREADY_PUNCHED_IN')) {
        throw Exception('You have already punched in today.');
      } else if (errorMessage.contains('NO_OFFICE_ASSIGNED')) {
        throw Exception('No office assigned to your profile. Please contact HR.');
      } else if (errorMessage.contains('Location is required')) {
        throw Exception('GPS location is required for punch in. Please enable location services.');
      }
      
      throw Exception('Failed to punch in: ${errorMessage.replaceAll('Exception: ', '')}');
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

      if (position == null && !kDebugMode) {
        throw Exception('Location is required. Please enable GPS to punch out.');
      }

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
      
      // Handle specific errors
      String errorMessage = e.toString();
      if (errorMessage.contains('NO_ACTIVE_PUNCH_IN')) {
        throw Exception('No active punch in found for today. Please punch in first.');
      } else if (errorMessage.contains('STILL_ON_BREAK')) {
        throw Exception('Cannot punch out while on break. Please end break first.');
      } else if (errorMessage.contains('Location is required')) {
        throw Exception('GPS location is required for punch out. Please enable location services.');
      }
      
      throw Exception('Failed to punch out: ${errorMessage.replaceAll('Exception: ', '')}');
    }
  }

  /// Returns the device's current GPS position, requesting permission if needed.
  /// Returns null if location is unavailable or permission is denied.
  Future<Position?> _getCurrentPosition() async {
    try {
      debugPrint('🔍 Checking location services...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled.');
        throw Exception('Location services are disabled. Please enable GPS to continue.');
      }

      debugPrint('🔍 Checking location permissions...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('📋 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permission denied.');
          throw Exception('Location permission denied. Please allow location access to continue.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission permanently denied.');
        throw Exception('Location permission permanently denied. Please enable location in device settings.');
      }

      debugPrint('📍 Getting current GPS position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      debugPrint('✅ GPS Position obtained: lat=${position.latitude}, lon=${position.longitude}');
      debugPrint('📊 GPS Accuracy: ${position.accuracy}m');
      debugPrint('⏰ GPS Timestamp: ${position.timestamp}');
      
      return position;
    } catch (e) {
      debugPrint('❌ Could not get GPS position: $e');
      
      // Provide specific error messages
      String errorMessage = e.toString();
      if (errorMessage.contains('Location services are disabled')) {
        throw Exception('Please enable GPS/location services on your device.');
      } else if (errorMessage.contains('permission')) {
        throw Exception('Please allow location access for this app to punch in/out.');
      } else if (errorMessage.contains('timeout')) {
        throw Exception('Location request timed out. Please try again.');
      } else {
        throw Exception('Unable to get location: ${errorMessage.replaceAll('Exception: ', '')}');
      }
    }
  }

  Future<void> startBreak() async {
    state = state.copyWith(isLoading: true);
    try {
      debugPrint('☕ Starting break...');
      final currentTime = DateTime.now();
      debugPrint('🕒 LOCAL TIME BEFORE API CALL: ${currentTime.toIso8601String()}');
      
      final position = await _getCurrentPosition();
      debugPrint('📍 GPS Position: lat=${position?.latitude}, lon=${position?.longitude}');

      if (position == null && !kDebugMode) {
        throw Exception('Location is required. Please enable GPS to start break.');
      }

      // Use the new mobile API endpoint for starting break
      final response = await ApiService.post(AppUrl.attendanceBreakStart, {
        'latitude': position?.latitude ?? 0.0,
        'longitude': position?.longitude ?? 0.0,
        'clientTimestamp': currentTime.toUtc().toIso8601String(),
        'timezone': currentTime.timeZoneName,
      });
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
      final currentTime = DateTime.now();
      debugPrint('🕒 LOCAL TIME BEFORE API CALL: ${currentTime.toIso8601String()}');
      
      final position = await _getCurrentPosition();
      debugPrint('📍 GPS Position: lat=${position?.latitude}, lon=${position?.longitude}');

      if (position == null && !kDebugMode) {
        throw Exception('Location is required. Please enable GPS to end break.');
      }

      // Use the new mobile API endpoint for ending break
      final response = await ApiService.post(AppUrl.attendanceBreakEnd, {
        'latitude': position?.latitude ?? 0.0,
        'longitude': position?.longitude ?? 0.0,
        'clientTimestamp': currentTime.toUtc().toIso8601String(),
        'timezone': currentTime.timeZoneName,
      });
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

    final officeData = data['office'];

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
      officeLat: officeData?['latitude'] != null ? (officeData['latitude'] as num).toDouble() : null,
      officeLon: officeData?['longitude'] != null ? (officeData['longitude'] as num).toDouble() : null,
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

  // Download attendance report
  Future<void> downloadMyAttendanceReport({String? month}) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Build URL with query parameters
      String url = AppUrl.attendanceMyReportDownload;
      if (month != null) {
        url += '?month=$month';
      }
      
      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        // File downloaded successfully
        if (kDebugMode) {
          print('Attendance report downloaded successfully');
        }
      } else {
        throw Exception('Failed to download attendance report');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading attendance report: $e');
      }
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final attendanceViewModelProvider =
    StateNotifierProvider<AttendanceViewModel, AttendanceState>((ref) {
  return AttendanceViewModel();
});
