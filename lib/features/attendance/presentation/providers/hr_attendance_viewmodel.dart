import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/features/attendance/data/models/hr_attendance_record_model.dart';

// ─── HR Attendance State ──────────────────────────────────────────────────────

class HrAttendanceState {
  final List<HrAttendanceRecord> records;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const HrAttendanceState({
    this.records = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  List<HrAttendanceRecord> get filteredRecords {
    if (searchQuery.trim().isEmpty) return records;
    final query = searchQuery.toLowerCase().trim();
    return records.where((rec) {
      return rec.employeeName.toLowerCase().contains(query) ||
          rec.employeeCode.toLowerCase().contains(query) ||
          rec.designation.toLowerCase().contains(query) ||
          (rec.officeName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Count active employees on break
  int get activeOnBreakCount => records.where((r) => r.isOnBreak).length;

  // Count checked-in employees
  int get presentCount => records.where((r) => r.checkIn != null).length;

  HrAttendanceState copyWith({
    List<HrAttendanceRecord>? records,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HrAttendanceState(
      records: records ?? this.records,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── HR Attendance ViewModel ───────────────────────────────────────────────────

class HrAttendanceViewModel extends StateNotifier<HrAttendanceState> {
  HrAttendanceViewModel() : super(const HrAttendanceState()) {
    fetchTodayAttendance();
  }

  Future<void> fetchTodayAttendance() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Get today's date in YYYY-MM-DD format
      final today = DateTime.now().toIso8601String().split('T')[0];

      final queryParams = <String, String>{
        'from': today,
        'to': today,
        'limit': '100',
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      final url = '${AppUrl.hrTodayAttendance}?$queryString';

      debugPrint('🔄 Fetching HR attendance logs...');
      final res = await ApiService.get(url);
      final data = jsonDecode(res.body);

      // Handle both response structures
      final List rawRecords = data['records'] ?? data['attendances'] ?? [];
      final records = rawRecords.map((r) => HrAttendanceRecord.fromJson(r)).toList();

      state = state.copyWith(records: records, isLoading: false);
      debugPrint('✅ HR attendance logs fetched: ${records.length} records.');
    } catch (e) {
      debugPrint('❌ Error fetching HR attendance logs: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  // Fetch attendance history with date range
  Future<void> fetchHistoryAttendance({
    String? from,
    String? to,
    int limit = 50,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      final url = '${AppUrl.hrTodayAttendance}?$queryString';

      debugPrint('🔄 Fetching HR attendance history...');
      final res = await ApiService.get(url);
      final data = jsonDecode(res.body);

      final List rawRecords = data['records'] ?? data['attendances'] ?? [];
      final records = rawRecords.map((r) => HrAttendanceRecord.fromJson(r)).toList();

      state = state.copyWith(records: records, isLoading: false);
      debugPrint('✅ HR attendance history fetched: ${records.length} records.');
    } catch (e) {
      debugPrint('❌ Error fetching HR attendance history: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Download attendance report for HR
  Future<void> downloadAttendanceReport({String? month, int? employeeId}) async {
    try {
      state = state.copyWith(isLoading: true);

      // Build URL with query parameters
      String url = AppUrl.attendanceReportDownload;
      List<String> queryParams = [];

      if (month != null) {
        queryParams.add('month=$month');
      }
      if (employeeId != null) {
        queryParams.add('employeeId=$employeeId');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        // File downloaded successfully
        if (kDebugMode) {
          print('HR attendance report downloaded successfully');
        }
      } else {
        throw Exception('Failed to download attendance report');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading HR attendance report: $e');
      }
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Fetch all employees' attendance (HR/Admin only)
  Future<void> fetchAllEmployeesAttendance({
    String? from,
    String? to,
    int? employeeId,
    int? departmentId,
    int? officeId,
    int page = 1,
    int limit = 50,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;
      if (employeeId != null) queryParams['employeeId'] = employeeId.toString();
      if (departmentId != null) queryParams['departmentId'] = departmentId.toString();
      if (officeId != null) queryParams['officeId'] = officeId.toString();

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      final url = '${AppUrl.mobileAllAttendance}?$queryString';

      debugPrint('🔄 Fetching all employees attendance...');
      final res = await ApiService.get(url);
      final data = jsonDecode(res.body);

      final List rawRecords = data['records'] ?? [];
      final records = rawRecords.map((r) => HrAttendanceRecord.fromJson(r)).toList();

      state = state.copyWith(records: records, isLoading: false);
      debugPrint('✅ All employees attendance fetched: ${records.length} records.');
    } catch (e) {
      debugPrint('❌ Error fetching all employees attendance: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final hrAttendanceViewModelProvider =
    StateNotifierProvider<HrAttendanceViewModel, HrAttendanceState>((ref) {
  return HrAttendanceViewModel();
});
