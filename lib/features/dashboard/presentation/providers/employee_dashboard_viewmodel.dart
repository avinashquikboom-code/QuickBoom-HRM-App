import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/features/dashboard/data/models/announcement_model.dart';

// ─── Upcoming Data Models ───────────────────────────────────────────────────

class UpcomingShift {
  final String name;
  final String startTime;
  final String endTime;
  final String? color;
  final String nextDate;
  final String dayName;

  UpcomingShift({
    required this.name,
    required this.startTime,
    required this.endTime,
    this.color,
    required this.nextDate,
    required this.dayName,
  });

  factory UpcomingShift.fromJson(Map<String, dynamic> json) {
    return UpcomingShift(
      name: json['name'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      color: json['color'],
      nextDate: json['nextDate'] ?? '',
      dayName: json['dayName'] ?? '',
    );
  }
}

class UpcomingHoliday {
  final String name;
  final String date;
  final bool isPublic;
  final String? description;

  UpcomingHoliday({
    required this.name,
    required this.date,
    required this.isPublic,
    this.description,
  });

  factory UpcomingHoliday.fromJson(Map<String, dynamic> json) {
    return UpcomingHoliday(
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      isPublic: json['isPublic'] ?? true,
      description: json['description'],
    );
  }
}

class UpcomingLeave {
  final String type;
  final String fromDate;
  final String toDate;
  final String? reason;

  UpcomingLeave({
    required this.type,
    required this.fromDate,
    required this.toDate,
    this.reason,
  });

  factory UpcomingLeave.fromJson(Map<String, dynamic> json) {
    return UpcomingLeave(
      type: json['type'] ?? '',
      fromDate: json['fromDate'] ?? '',
      toDate: json['toDate'] ?? '',
      reason: json['reason'],
    );
  }
}

class UpcomingData {
  final UpcomingShift? upcomingShift;
  final UpcomingHoliday? upcomingHoliday;
  final UpcomingLeave? upcomingLeave;
  final String? salaryDate;
  final AnnouncementModel? latestAnnouncement;

  UpcomingData({
    this.upcomingShift,
    this.upcomingHoliday,
    this.upcomingLeave,
    this.salaryDate,
    this.latestAnnouncement,
  });
}

// ─── Dashboard Stats ───────────────────────────────────────────────────────────

class DashboardStats {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int pendingLeaves;
  final int casualRemaining;
  final int sickRemaining;
  final int earnedRemaining;

  const DashboardStats({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
    this.pendingLeaves = 0,
    this.casualRemaining = 12,
    this.sickRemaining = 10,
    this.earnedRemaining = 15,
  });
}

// ─── Employee Dashboard State ────────────────────────────────────────────────

class EmployeeDashboardState {
  final DashboardStats stats;
  final List<AnnouncementModel> announcements;
  final UpcomingData? upcomingData;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? selectedMonth;
  final DateTime? selectedYear;

  const EmployeeDashboardState({
    this.stats = const DashboardStats(),
    this.announcements = const [],
    this.upcomingData,
    this.isLoading = false,
    this.errorMessage,
    this.selectedMonth,
    this.selectedYear,
  });

  EmployeeDashboardState copyWith({
    DashboardStats? stats,
    List<AnnouncementModel>? announcements,
    UpcomingData? upcomingData,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    DateTime? selectedMonth,
    DateTime? selectedYear,
  }) {
    return EmployeeDashboardState(
      stats: stats ?? this.stats,
      announcements: announcements ?? this.announcements,
      upcomingData: upcomingData ?? this.upcomingData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }
}

// ─── Employee Dashboard ViewModel ──────────────────────────────────────────────

class EmployeeDashboardViewModel extends StateNotifier<EmployeeDashboardState> {
  EmployeeDashboardViewModel() : super(const EmployeeDashboardState()) {
    fetchDashboard();
  }

  Future<void> fetchDashboard({DateTime? month, DateTime? year}) async {
    state = state.copyWith(isLoading: true, clearError: true, selectedMonth: month, selectedYear: year);
    try {
      final queryParams = <String, String>{};
      if (month != null) {
        queryParams['month'] = month.month.toString();
      }
      if (year != null) {
        queryParams['year'] = year.year.toString();
      }

      final queryString = queryParams.isNotEmpty ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}' : '';
      final res = await ApiService.get('${AppUrl.employeeDashboardStats}$queryString');
      final data = jsonDecode(res.body);

      final statsData = data['stats'];
      final stats = DashboardStats(
        totalTasks: statsData?['tasks']?['total'] ?? 0,
        completedTasks: statsData?['tasks']?['completed'] ?? 0,
        pendingTasks: statsData?['tasks']?['pending'] ?? 0,
        pendingLeaves: statsData?['leaves']?['pendingRequests'] ?? 0,
        casualRemaining: statsData?['leaves']?['balances']?['casualRemaining'] ?? 12,
        sickRemaining: statsData?['leaves']?['balances']?['sickRemaining'] ?? 10,
        earnedRemaining: statsData?['leaves']?['balances']?['earnedRemaining'] ?? 15,
      );

      final List rawAnnouncements = data['announcements'] ?? [];
      final announcements = rawAnnouncements.map((a) {
        AnnouncementCategory cat;
        switch ((a['category'] ?? 'general').toString().toLowerCase()) {
          case 'event':
            cat = AnnouncementCategory.event;
            break;
          case 'holiday':
            cat = AnnouncementCategory.holiday;
            break;
          case 'policy':
            cat = AnnouncementCategory.policy;
            break;
          default:
            cat = AnnouncementCategory.general;
        }
        return AnnouncementModel(
          id: a['id']?.toString() ?? '',
          title: a['title']?.toString() ?? '',
          description: a['content']?.toString() ?? '',
          date: DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now(),
          postedBy: a['publishedBy']?.toString() ?? 'HR',
          category: cat,
        );
      }).toList();

      // Fetch upcoming data
      UpcomingData? upcomingData;
      try {
        final upcomingRes = await ApiService.get(AppUrl.employeeDashboardUpcoming);
        final upcomingJson = jsonDecode(upcomingRes.body);
        if (upcomingJson['success'] == true && upcomingJson['data'] != null) {
          final uData = upcomingJson['data'];
          
          final shiftJson = uData['upcomingShift'];
          final holidayJson = uData['upcomingHoliday'];
          final leaveJson = uData['upcomingLeave'];
          final salDate = uData['salaryDate']?.toString();
          
          final announcementJson = uData['latestAnnouncement'];
          AnnouncementModel? latestAnn;
          if (announcementJson != null) {
            AnnouncementCategory cat = AnnouncementCategory.general;
            switch ((announcementJson['category'] ?? 'general').toString().toLowerCase()) {
              case 'event': cat = AnnouncementCategory.event; break;
              case 'holiday': cat = AnnouncementCategory.holiday; break;
              case 'policy': cat = AnnouncementCategory.policy; break;
            }
            latestAnn = AnnouncementModel(
              id: announcementJson['id']?.toString() ?? '',
              title: announcementJson['title']?.toString() ?? '',
              description: announcementJson['content']?.toString() ?? '',
              date: DateTime.tryParse(announcementJson['createdAt']?.toString() ?? '') ?? DateTime.now(),
              postedBy: announcementJson['publishedBy']?.toString() ?? 'HR',
              category: cat,
            );
          }

          upcomingData = UpcomingData(
            upcomingShift: shiftJson != null ? UpcomingShift.fromJson(shiftJson) : null,
            upcomingHoliday: holidayJson != null ? UpcomingHoliday.fromJson(holidayJson) : null,
            upcomingLeave: leaveJson != null ? UpcomingLeave.fromJson(leaveJson) : null,
            salaryDate: salDate,
            latestAnnouncement: latestAnn,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching upcoming widget data: $e');
      }

      state = EmployeeDashboardState(
        stats: stats,
        announcements: announcements,
        upcomingData: upcomingData,
        isLoading: false,
        selectedMonth: month,
        selectedYear: year,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setSelectedMonth(DateTime month) {
    state = state.copyWith(selectedMonth: month);
    fetchDashboard(month: month, year: state.selectedYear);
  }

  void setSelectedYear(DateTime year) {
    state = state.copyWith(selectedYear: year);
    fetchDashboard(month: state.selectedMonth, year: year);
  }

  void clearFilters() {
    state = state.copyWith(selectedMonth: null, selectedYear: null);
    fetchDashboard();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final employeeDashboardViewModelProvider =
    StateNotifierProvider<EmployeeDashboardViewModel, EmployeeDashboardState>((ref) {
  return EmployeeDashboardViewModel();
});
