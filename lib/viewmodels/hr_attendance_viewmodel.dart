import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';
import '../models/hr_attendance_record_model.dart';

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
      final currentTime = DateTime.now();
      final url = '${AppUrl.hrTodayAttendance}'
          '?clientTimestamp=${Uri.encodeComponent(currentTime.toUtc().toIso8601String())}'
          '&timezone=${Uri.encodeComponent(currentTime.timeZoneName)}';

      debugPrint('🔄 Fetching today\'s HR attendance logs...');
      final res = await ApiService.get(url);
      final data = jsonDecode(res.body);

      final List rawRecords = data['attendances'] ?? [];
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
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final hrAttendanceViewModelProvider =
    StateNotifierProvider<HrAttendanceViewModel, HrAttendanceState>((ref) {
  return HrAttendanceViewModel();
});
