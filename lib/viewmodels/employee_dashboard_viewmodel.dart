import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';
import '../models/announcement_model.dart';

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
  final bool isLoading;
  final String? errorMessage;

  const EmployeeDashboardState({
    this.stats = const DashboardStats(),
    this.announcements = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  EmployeeDashboardState copyWith({
    DashboardStats? stats,
    List<AnnouncementModel>? announcements,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmployeeDashboardState(
      stats: stats ?? this.stats,
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── Employee Dashboard ViewModel ──────────────────────────────────────────────

class EmployeeDashboardViewModel extends StateNotifier<EmployeeDashboardState> {
  EmployeeDashboardViewModel() : super(const EmployeeDashboardState()) {
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiService.get(AppUrl.employeeDashboardStats);
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

      state = EmployeeDashboardState(
        stats: stats,
        announcements: announcements,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final employeeDashboardViewModelProvider =
    StateNotifierProvider<EmployeeDashboardViewModel, EmployeeDashboardState>((ref) {
  return EmployeeDashboardViewModel();
});
