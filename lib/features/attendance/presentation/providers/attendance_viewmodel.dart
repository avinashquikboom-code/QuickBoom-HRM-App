import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/features/attendance/data/models/attendance_model.dart';

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

  Future<bool> checkIn({bool viaFingerprint = false, double? latitude, double? longitude}) async {
    state = state.copyWith(isLoading: true);
    
    final currentTime = DateTime.now();
    debugPrint('🕒 LOCAL TIME BEFORE API CALL: ${currentTime.toIso8601String()}');
    debugPrint('🌍 TIMEZONE: ${currentTime.timeZoneName} (${currentTime.timeZoneOffset})');

    double lat = latitude ?? 0.0;
    double lon = longitude ?? 0.0;

    if (latitude == null || longitude == null) {
      // Fetch real GPS coordinates
      final position = await _getCurrentPosition();
      lat = position?.latitude ?? 0.0;
      lon = position?.longitude ?? 0.0;
    }
    debugPrint('📍 GPS Position: lat=$lat, lon=$lon');

    debugPrint('[PUNCH] API request start: checkIn');
    final response = await ApiService.post(AppUrl.attendancePunchIn, {
      'latitude': lat,
      'longitude': lon,
      'notes': viaFingerprint ? 'Punched in via Fingerprint' : 'Punched in via mobile app',
      'clientTimestamp': currentTime.toUtc().toIso8601String(),
      'timezone': currentTime.timeZoneName,
      'isFingerprint': viaFingerprint,
    });

    debugPrint('✅ Punch-in API response: ${response.body}');
    debugPrint('[PUNCH] API response: success');
    
    debugPrint('[PUNCH] Attendance state refresh');
    await fetchAttendanceData();
    return true;
  }

  Future<bool> checkOut({bool viaFingerprint = false, double? latitude, double? longitude, String? notes}) async {
    state = state.copyWith(isLoading: true);
    
    final currentTime = DateTime.now();
    debugPrint('🕒 LOCAL TIME BEFORE API CALL: ${currentTime.toIso8601String()}');
    debugPrint('🌍 TIMEZONE: ${currentTime.timeZoneName} (${currentTime.timeZoneOffset})');

    double lat = latitude ?? 0.0;
    double lon = longitude ?? 0.0;

    if (latitude == null || longitude == null) {
      // Fetch real GPS coordinates
      final position = await _getCurrentPosition();
      lat = position?.latitude ?? 0.0;
      lon = position?.longitude ?? 0.0;
    }
    debugPrint('📍 GPS Position: lat=$lat, lon=$lon');

    debugPrint('[PUNCH] API request start: checkOut');
    final response = await ApiService.post(AppUrl.attendancePunchOut, {
      'latitude': lat,
      'longitude': lon,
      'notes': notes ?? (viaFingerprint ? 'Punched out via Fingerprint' : 'Punched out via mobile app'),
      'clientTimestamp': currentTime.toUtc().toIso8601String(),
      'timezone': currentTime.timeZoneName,
      'isFingerprint': viaFingerprint,
    });

    debugPrint('✅ Punch-out API response: ${response.body}');
    debugPrint('[PUNCH] API response: success');
    
    debugPrint('[PUNCH] Attendance state refresh');
    await fetchAttendanceData();
    return true;
  }

  /// Returns the device's current GPS position, requesting permission if needed.
  /// Returns null if location is unavailable or permission is denied.
  Future<Position?> _getCurrentPosition() async {
    try {
      debugPrint('🔍 Checking location services...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled.');
        return null;
      }
      
      debugPrint('🔍 Checking location permissions...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('📋 Requesting location permission...');
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission denied.');
        return null;
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
      debugPrint('❌ Error getting current position: $e');
      return null;
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
      debugPrint('❌ Error starting break: $e');
      state = state.copyWith(isLoading: false);
      rethrow;
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
      debugPrint('❌ Error ending break: $e');
      state = state.copyWith(isLoading: false);
      rethrow;
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
      isLateMarkedAsHalfDay: data['isLateMarkedAsHalfDay'] ?? false,
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
    state = state.copyWith(isLoading: true);
    
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      // Build URL with query parameters
      String url = AppUrl.attendanceMyReportDownload;
      if (month != null) {
        url += '?month=$month';
      }
      
      final downloadUri = Uri.parse(
        '${AppUrl.baseUrl}$url?token=$token',
      );

      debugPrint('📥 Opening attendance report URL: $downloadUri');

      bool launched = await launchUrl(
        downloadUri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        // Fallback for devices without an external browser handler
        launched = await launchUrl(
          downloadUri,
          mode: LaunchMode.inAppWebView,
        );
      }
      
      if (!launched) {
        throw Exception('Could not launch download URL');
      }
      
      if (kDebugMode) {
        print('Attendance report download launched successfully');
      }
    } catch (e) {
      debugPrint('❌ Error downloading attendance report: $e');
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
